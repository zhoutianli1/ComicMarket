// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { DataTypes }      from "../libraries/DataTypes.sol";
import { Errors }         from "../libraries/Errors.sol";
import { PercentageMath } from "../libraries/PercentageMath.sol";
import { IComicNFT, IRoyaltySplitter } from "../interfaces/IAll.sol";

/// 设计模式：Pull-over-Push
/// @title RoyaltySplitter
/// @notice 自动版税拆分合约（依赖ComicNFT），不直接向收款方“推送”（transfer）资金，而是将应付金额记在各自的账上（ pendingWithdrawals 映射）。收款方必须主动调用 withdraw 函数来“拉取”（pull）他们的资金。如果采用“推送”模式，只要有一个收款方（例如，一个设计有问题的合约）接收转账失败，就会导致整个交易（包括NFT转移和所有版税分配）回滚。Pull模式将每个人的提款操作隔离开，避免了这种“一损俱损”的风险。同时，它也是防止重入攻击的有效手段。
/// @dev 每笔成交时由 Marketplace 调用，按比例分配给：
///      原作者 / 二创作者（若有）/ 平台 / 卖家
///      支持 ETH 和 ERC20 两种支付方式
///      只分配到待提取账户，实际转账由各方主动提取（pull 模式，防止 push 失败导致交易回滚）
contract RoyaltySplitter is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    IRoyaltySplitter
{
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;

    // ─── 存储 ──────────────────────────────────────────────────────────────

    address public comicNFTContract; // ComicNFT 合约地址
    address public platformTreasury; // 平台金库地址，收取平台分成 ，可以是一个钱包地址或 合约地址
    address public marketplaceContract; // 授权的市场合约地址

    // ─── 修饰符 ────────────────────────────────────────────────────────────

    modifier onlyMarketplace() {
        if (msg.sender != marketplaceContract) revert Errors.Unauthorized();
        _;
    }

    /// 各地址待提取余额（pull 模式，防止 push 失败导致交易回滚）
    mapping(address => mapping(address => uint256)) public pendingWithdrawals;
    // pendingWithdrawals[recipient][paymentToken] => amount

    // ─── 初始化 ────────────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address _comicNFTContract,
        address _platformTreasury,
        address _marketplaceContract
    ) external initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();

        if (_comicNFTContract == address(0) || _platformTreasury == address(0))
            revert Errors.ZeroAddress();

        comicNFTContract    = _comicNFTContract;
        platformTreasury    = _platformTreasury;
        marketplaceContract = _marketplaceContract; // 允许初始为 0，后续通过 setMarketplaceContract 设置
    }

    // ─── 暂停机制 ──────────────────────────────────────────────────────────

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

 

    // ─── 核心：分配版税 ────────────────────────────────────────────────────

    /// @notice 由 Marketplace 在成交时调用
    /// @param tokenId       成交的 NFT Token ID
    /// @param seller        卖家地址
    /// @param saleAmount    成交总额（wei）
    /// @param paymentToken  支付代币（address(0) = ETH）
    /// @return creatorShare    创作者获得
    /// @return derivativeShare 二创者获得
    /// @return platformShare   平台获得
    /// @return sellerProceeds  卖家实际到手金额
    function distribute(
        uint256 tokenId,
        address, // nftContract (unused)
        address seller,
        uint256 saleAmount,
        address paymentToken
    ) external payable override onlyMarketplace nonReentrant whenNotPaused returns (
        uint256 creatorShare,
        uint256 derivativeShare,
        uint256 platformShare,
        uint256 sellerProceeds
    ) {
        // onlyMarketplace：只有 Marketplace 可以调用

        // ── 读取版税配置 ──
        DataTypes.ComicInfo memory info = IComicNFT(comicNFTContract).getComicInfo(tokenId);

        // ── 是否为原作者出售，确定版税比例 ──
        // 一级市场（创作者直接出售）：，创作者和卖家是同一人，不需要额外版税拆分;
        // 二级市场（持有者转售）：使用 secondaryRoyaltyBps
        bool isPrimary = (seller == info.creator);//如果卖家是原作者，就是一级市场交易，否则就是二级市场交易
        uint16 creatorBps = isPrimary ? 0 : info.secondaryRoyaltyBps;

        //不是二创作品，derivativeBps=0
        uint16 derivativeBps = 0;
        // ── 为二创作品 ──
        if (info.isDerivative) {
            // 只要是二创作品，无论是首次销售还是后续转卖：原作者都从销售额中获得分成
            DataTypes.ComicInfo memory parentInfo = IComicNFT(comicNFTContract).getComicInfo(info.parentTokenId);
            derivativeBps = parentInfo.derivativeShareBps;
        }

        // ── 计算各方金额 ──
        //当是原创作品，creatorBps=
        (
            creatorShare,
            derivativeShare,
            platformShare,
            sellerProceeds
        ) = PercentageMath.splitProceeds(saleAmount, creatorBps, derivativeBps);

        // ── 分配到待提取账户（pull 模式，防重入）──
        _credit(info.creator, paymentToken, creatorShare);

        if (info.isDerivative && info.derivativeCreator != address(0)) {
            // 二创作品：二创者分成
            // derivativeShare 对应原作者从衍生品获得的分成
            DataTypes.ComicInfo memory parentInfo2 = IComicNFT(comicNFTContract).getComicInfo(info.parentTokenId);
            _credit(parentInfo2.creator, paymentToken, derivativeShare);
        }
        
        _credit(platformTreasury, paymentToken, platformShare);
        _credit(seller,           paymentToken, sellerProceeds);

        // ── 验证：ETH 支付时确保收到足额 ──
        if (paymentToken == address(0)) {
            if (msg.value < saleAmount) revert Errors.InsufficientPayment(msg.value, saleAmount);
        } else {
            // ERC20：由 Marketplace 提前转入本合约
        }

        emit RoyaltyDistributed(
            tokenId,
            saleAmount,
            creatorShare,
            derivativeShare,
            platformShare,
            sellerProceeds
        );
    }

    // ─── 提取（pull 模式）────────────────────────────────────────────────────

    /// @notice 各方主动提取自己的待结算金额
    /// @param paymentToken  代币地址（address(0) = ETH）
    function withdraw(address paymentToken) external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender][paymentToken];
        if (amount == 0) revert Errors.ZeroAmount();

        pendingWithdrawals[msg.sender][paymentToken] = 0; // 先清零，防重入

        if (paymentToken == address(0)) {
            (bool ok,) = payable(msg.sender).call{value: amount}("");
            if (!ok) revert Errors.TransferFailed(msg.sender, amount);
        } else {
            IERC20(paymentToken).safeTransfer(msg.sender, amount);
        }

        emit Withdrawn(msg.sender, paymentToken, amount);
    }

    /// @notice 批量提取多种代币
    function batchWithdraw(address[] calldata paymentTokens) external nonReentrant {
        uint256 length = paymentTokens.length;
        uint256[] memory amounts = new uint256[](length);

        // 1. 先记录并清零所有待提款金额 (Check-Effect)
        for (uint256 i; i < length; ) {
            address token = paymentTokens[i];
            uint256 amount = pendingWithdrawals[msg.sender][token];
            if (amount != 0) {
                amounts[i] = amount;
                pendingWithdrawals[msg.sender][token] = 0;
            }
            unchecked { ++i; }
        }

        // 2. 再统一进行外部转账 (Interaction)
        for (uint256 i; i < length; ) {
            uint256 amount = amounts[i];
            if (amount != 0) {
                address token = paymentTokens[i];
                if (token == address(0)) {
                    (bool ok,) = payable(msg.sender).call{value: amount}("");
                    if (!ok) revert Errors.TransferFailed(msg.sender, amount);
                } else {
                    IERC20(token).safeTransfer(msg.sender, amount);
                }
                emit Withdrawn(msg.sender, token, amount);
            }
            unchecked { ++i; }
        }
    }

    // ─── 内部工具 ──────────────────────────────────────────────────────────

    function _credit(address recipient, address token, uint256 amount) internal {
        if (amount == 0 || recipient == address(0)) return;
        //只是增加待提取金额，不直接转账，避免 push 失败导致交易回滚
        pendingWithdrawals[recipient][token] += amount;
    }

    // ─── 配置 ──────────────────────────────────────────────────────────────
   function setMarketplaceContract(address marketplace) external onlyOwner {
        if (marketplace == address(0)) revert Errors.ZeroAddress();
        marketplaceContract = marketplace;
    }
    function setPlatformTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert Errors.ZeroAddress();
        platformTreasury = newTreasury;
    }

    function setComicNFTContract(address newContract) external onlyOwner {
        if (newContract == address(0)) revert Errors.ZeroAddress();
        comicNFTContract = newContract;
    }

    // ─── UUPS 升级 ────────────────────────────────────────────────────────

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ─── 接收 ETH ─────────────────────────────────────────────────────────

    receive() external payable {}

    // ─── 事件 ─────────────────────────────────────────────────────────────

    event Withdrawn(address indexed recipient, address indexed token, uint256 amount);
}
