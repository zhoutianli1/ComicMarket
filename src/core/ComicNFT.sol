// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";//基础 ERC721 功能，不包含 tokenURI 存储
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";//提供tokenURI存储功能
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";//所有权管理（多签地址）
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";//暂停机制（紧急安全措施）
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";//可升级模式（初始化）
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";//可升级模式（UUPS）

import { DataTypes }       from "../libraries/DataTypes.sol";
import { Errors }          from "../libraries/Errors.sol";
import { PercentageMath }  from "../libraries/PercentageMath.sol";
import { IComicNFT }       from "../interfaces/IAll.sol";

/// @title ComicNFT
/// @notice 漫画 NFT 主合约（ERC721，UUPS 可升级）
/// @dev
///   - 铸造时链上记录版税配置，不可修改核心字段
///   - 支持原作 / 二创两种类型，二创自动注册到 IP 家族
///   - 管理员可随时暂停铸造（紧急安全机制）
///   - 符合 EIP-2981 版税标准（供第三方市场读取）
contract ComicNFT is
    Initializable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    IComicNFT
{
    using PercentageMath for uint256;

    // ─── 存储 ──────────────────────────────────────────────────────────────
    // 递增的 Token ID 计数器
    uint256 private _nextTokenId;

    /// tokenId => 作品信息
    mapping(uint256 => DataTypes.ComicInfo) private _comicInfo;

    /// 原作 tokenId => IP 家族信息
    mapping(uint256 => DataTypes.IPFamily) private _ipFamilies;

    /// tokenId => IP 授权列表（licenseId）
    mapping(uint256 => uint256[]) private _tokenLicenses;

    /// licenseId => 授权凭证
    mapping(uint256 => DataTypes.LicenseGrant) private _licenses;
    uint256 private _nextLicenseId;

    /// 授权的市场合约地址（只有市场合约可以调用 transferFrom）
    address public marketplaceContract;

    /// 授权的跨链桥合约地址（允许销毁资产进行跨链回流）
    address public bridgeContract;

    // ─── 修饰符 ──────────────────────────────────────────────────────────────

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert Errors.NotTokenOwner(msg.sender, tokenId);
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        if (_ownerOf(tokenId) == address(0)) revert Errors.TokenNotExists(tokenId);
        _;
    }

    // ─── 初始化（代替 普通合约constructor初始化构造，UUPS 模式）────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    // initializer 确保这个函数只能被调用一次
    function initialize(address initialOwner) external initializer {
        __ERC721_init("ComicMarketNFT", "COMIC");// ERC721 基础初始化
        __ERC721URIStorage_init();// URI 存储初始化
        __Ownable_init(initialOwner);// 所有权初始化（多签地址）
        __Pausable_init();// 暂停机制初始化
        _nextTokenId = 1;
    }

    // ─── 暂停机制（安全关键）─────────────────────────────────────────────────

    /// @notice 紧急暂停：停止所有铸造和转移
    /// @dev 只有 owner（多签地址）可调用
    function pause() external onlyOwner { _pause(); }

    /// @notice 恢复正常运行
    function unpause() external onlyOwner { _unpause(); }

    // ─── 核心：铸造 ───────────────────────────────────────────────────────────

    /// @notice 铸造漫画 NFT：重写mint函数，增加了版税和二创相关参数，并在链上记录 IP 家族信息
    /// @param to                  接收者地址（通常为创作者本人）
    /// @param metadataURI         IPFS 元数据 URI
    /// @param secondaryRoyaltyBps 二级市场版税（≤ 1000）
    /// @param derivativeShareBps  原作衍生品分成（推荐 500）
    /// @param isDerivative        是否为二创作品
    /// @param parentTokenId       若为二创，原作 Token ID
    /// @return tokenId            新铸造的 Token ID
    function mint(
        address to,
        string  calldata metadataURI,
        uint16  secondaryRoyaltyBps,
        uint16  derivativeShareBps,
        bool    isDerivative,
        uint256 parentTokenId
    ) external override whenNotPaused nonReentrant returns (uint256 tokenId) {
        // ── 参数校验 ──
        if (to == address(0))          revert Errors.ZeroAddress();
        if (bytes(metadataURI).length == 0) revert Errors.InvalidMetadataURI();
        if (secondaryRoyaltyBps > PercentageMath.MAX_SECONDARY_BPS)
            revert Errors.SecondaryRoyaltyTooHigh(secondaryRoyaltyBps, PercentageMath.MAX_SECONDARY_BPS);

        // ── 二创校验：原作必须存在，且作者需获得授权 ──
        address derivativeCreatorAddr = address(0);
        if (isDerivative) {
            if (_ownerOf(parentTokenId) == address(0))
                revert Errors.ParentTokenNotExists(parentTokenId);
            
            // 校验授权：msg.sender 必须在原作的已批准授权名单中
            bool isAuthorized = false;
            uint256[] memory licenses = _tokenLicenses[parentTokenId];
            for (uint256 i = 0; i < licenses.length; i++) {
                DataTypes.LicenseGrant memory grant = _licenses[licenses[i]];
                if (grant.licensee == msg.sender && grant.status == DataTypes.LicenseStatus.Approved) {
                    if (grant.expiresAt == 0 || grant.expiresAt > block.timestamp) {
                        isAuthorized = true;
                        break;
                    }
                }
            }
            if (!isAuthorized) revert Errors.Unauthorized();

            derivativeCreatorAddr = msg.sender;
        }

        // ── 铸造 ──
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        // ── 写入元数据（铸造后核心字段不可变）──
        _comicInfo[tokenId] = DataTypes.ComicInfo({
            metadataURI:         metadataURI,
            creator:             msg.sender,
            secondaryRoyaltyBps: secondaryRoyaltyBps,
            derivativeShareBps:  derivativeShareBps,
            isDerivative:        isDerivative,
            parentTokenId:       isDerivative ? parentTokenId : 0,
            derivativeCreator:   derivativeCreatorAddr
        });

        // ── 更新 IP 家族 ──
        if (isDerivative) {
            DataTypes.IPFamily storage family = _ipFamilies[parentTokenId];
            family.totalDerivatives++;
            family.derivativeTokenIds.push(tokenId);
        }

        emit ComicMinted(tokenId, msg.sender, metadataURI, isDerivative, parentTokenId);
    }

    /// @notice 销毁漫画 NFT（仅允许桥合约销毁用于回流，或持有者自行销毁）
    function burn(uint256 tokenId) external override whenNotPaused {
        if (msg.sender != bridgeContract && ownerOf(tokenId) != msg.sender)
            revert Errors.Unauthorized();
        
        _burn(tokenId);
    }

    // ─── IP 家族管理 ──────────────────────────────────────────────────────────

    /// @notice 创作者更新二级市场版税比例（只能降低，不能提高，防止欺诈）
    function updateSecondaryRoyalty(uint256 tokenId, uint16 newBps)
        external override tokenExists(tokenId) onlyTokenOwner(tokenId)
    {
        if (newBps > PercentageMath.MAX_SECONDARY_BPS)
            revert Errors.SecondaryRoyaltyTooHigh(newBps, PercentageMath.MAX_SECONDARY_BPS);
        _comicInfo[tokenId].secondaryRoyaltyBps = newBps;
        emit RoyaltyUpdated(tokenId, newBps);
    }

    /// @notice 创作者更新衍生品分成比例
    function updateDerivativeShare(uint256 tokenId, uint16 newBps)
        external override tokenExists(tokenId)
    {
        DataTypes.ComicInfo storage info = _comicInfo[tokenId];
        if (info.creator != msg.sender) revert Errors.Unauthorized();
        info.derivativeShareBps = newBps;
        emit DerivativeShareUpdated(tokenId, newBps);
    }

    // ─── IP 授权 ──────────────────────────────────────────────────────────────

    /// @notice 读者/二创者申请 IP 授权
    /// @param parentTokenId 原作 Token ID
    /// @param royaltyBps    双方协商的版税比例
    /// @param commercialUse 是否商业用途
    /// @param expiresAt     过期时间（0 = 永久）
    function requestLicense(
        uint256 parentTokenId,
        uint16  royaltyBps,
        bool    commercialUse,
        uint64  expiresAt
    ) external payable tokenExists(parentTokenId) returns (uint256 licenseId) {
        // 计算并锁定保证金（授权费的 20%），意味着在调用此函数时需要支付一定的 ETH（abr链的原生代币） 作为保证金，防止恶意申请
        // 授权费=（预期二创作品销售额 * 版税比例）的20%，这个数值可以根据实际情况调整，既要足够高以防止垃圾申请，又不能过高以免阻碍正常的授权需求。
        uint256 deposit = msg.value;

        licenseId = _nextLicenseId++;
        _licenses[licenseId] = DataTypes.LicenseGrant({
            parentTokenId: parentTokenId,
            licensee:      msg.sender,
            status:        DataTypes.LicenseStatus.Pending,// 初始状态为待审核
            royaltyBps:    royaltyBps,
            depositAmount: deposit,
            grantedAt:     0,
            expiresAt:     expiresAt,
            commercialUse: commercialUse
        });
        _tokenLicenses[parentTokenId].push(licenseId);

        // 通知原作者（链下监听事件后在 UI 审核）
        emit LicenseRequested(licenseId, parentTokenId, msg.sender, royaltyBps, commercialUse);
    }

    /// @notice 原作者审核授权申请
    function reviewLicense(uint256 licenseId, bool approve)
        external
    {
        DataTypes.LicenseGrant storage grant = _licenses[licenseId];
        if (grant.status != DataTypes.LicenseStatus.Pending)
            revert Errors.LicenseNotPending(licenseId);

        DataTypes.ComicInfo storage info = _comicInfo[grant.parentTokenId];
        if (info.creator != msg.sender) revert Errors.Unauthorized();

        if (approve) {
            grant.status    = DataTypes.LicenseStatus.Approved;
            grant.grantedAt = uint64(block.timestamp);
            emit LicenseApproved(licenseId, grant.parentTokenId, grant.licensee);
        } else {
            grant.status = DataTypes.LicenseStatus.Rejected;
            // 退还保证金，.call() 是推荐的发送 ETH 的方式，格式为 (bool success, ) = recipient.call{value: amount}("");
            (bool ok,) = payable(grant.licensee).call{value: grant.depositAmount}("");
            if (!ok) revert Errors.TransferFailed(grant.licensee, grant.depositAmount);
            emit LicenseRejected(licenseId);
        }
    }

    // ─── 查询 ──────────────────────────────────────────────────────────────────

    function getComicInfo(uint256 tokenId) external view override returns (DataTypes.ComicInfo memory) {
        return _comicInfo[tokenId];
    }

    function getIPFamily(uint256 tokenId) external view override returns (DataTypes.IPFamily memory) {
        return _ipFamilies[tokenId];
    }

    function getLicense(uint256 licenseId) external view returns (DataTypes.LicenseGrant memory) {
        return _licenses[licenseId];
    }

    function getTokenLicenses(uint256 tokenId) external view returns (uint256[] memory) {
        return _tokenLicenses[tokenId];
    }

    // ─── 市场合约授权 ─────────────────────────────────────────────────────────

    /// @notice 设置市场合约
    function setMarketplaceContract(address marketplace) external onlyOwner {
        if (marketplace == address(0)) revert Errors.ZeroAddress();
        marketplaceContract = marketplace;
    }

    /// @notice 设置跨链桥合约
    function setBridgeContract(address bridge) external onlyOwner {
        if (bridge == address(0)) revert Errors.ZeroAddress();
        bridgeContract = bridge;
    }

    // ─── EIP-2981 版税标准 ────────────────────────────────────────────────────

    /// @notice 供第三方市场（OpenSea 等）读取版税信息
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view returns (address receiver, uint256 royaltyAmount)
    {
        DataTypes.ComicInfo storage info = _comicInfo[tokenId];
        receiver      = info.creator;
        royaltyAmount = PercentageMath.percentOf(salePrice, info.secondaryRoyaltyBps);
    }
    // EIP-2981 接口 ID 是 0x2a55205a，重写 supportsInterface 以声明支持该接口
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return interfaceId == 0x2a55205a // EIP-2981
            || super.supportsInterface(interfaceId);
    }

    // ─── ERC721 重写（暂停时阻止转移）────────────────────────────────────────

    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721Upgradeable)  
        whenNotPaused
        returns (address)
    {
        return super._update(to, tokenId, auth);// 只有在合约未暂停时才允许转移，暂停时会 revert
    }

    function tokenURI(uint256 tokenId)
        public view override(ERC721URIStorageUpgradeable, IComicNFT)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // ─── UUPS 升级授权 ────────────────────────────────────────────────────────

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ─── 额外事件（授权相关）─────────────────────────────────────────────────

    event LicenseRequested(
        uint256 indexed licenseId,
        uint256 indexed parentTokenId,
        address indexed licensee,
        uint16  royaltyBps,
        bool    commercialUse
    );
    event LicenseApproved(uint256 indexed licenseId, uint256 parentTokenId, address licensee);
    event LicenseRejected(uint256 indexed licenseId);
}
