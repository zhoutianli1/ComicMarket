// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { DataTypes }   from "../libraries/DataTypes.sol";
import { Errors }      from "../libraries/Errors.sol";
import { ICCIPRouter, IUniswapRouter, IComicNFT } from "../interfaces/IAll.sol";

/// @title CrossChainBridge
/// @notice 跨链桥主合约：本链锁定 NFT → CCIP 传消息 → 目标链铸造封装版 NFT：
///本质上做一件事：让一个 NFT 从 A 链"移动"到 B 链，同时把版税配置也带过去。
/// @dev
///   安全机制：
///   1. 只有 owner 可添加受支持链
///   2. 锁定时记录 BridgeLock，防止重复操作
///   3. CCIP 消息只来自授权的目标链合约地址
///   4. 暂停机制可立即停止所有跨链操作
///   5. 失败交易支持 owner 手动回滚（释放锁定）
///   CCIP 手续费要用 LINK 或 ETH 支付，但用户钱包里可能只有 USDC。UniswapSwapAdapter.swapForBridgeFee() 就是在跨链之前帮用户把手里的代币换成支付手续费所需的代币，是一个预处理步骤，不是跨链本身的一部分。
contract CrossChainBridge is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    // ─── 存储 ──────────────────────────────────────────────────────────────

    ICCIPRouter   public ccipRouter;
    IUniswapRouter public uniswapRouter;
    address        public comicNFTContract; // 本链 NFT 合约

    /// 支持的目标链：chainSelector => 目标链桥合约地址（abi.encode 后）
    mapping(uint64 => bytes) public supportedChains;

    /// tokenId => 锁定记录
    mapping(uint256 => DataTypes.BridgeLock) public bridgeLocks;

    /// CCIP 消息 ID => 是否已处理（防重放）
    mapping(bytes32 => bool) public processedMessages;

    // ─── 初始化 ────────────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address _ccipRouter,
        address _uniswapRouter,
        address _comicNFTContract
    ) external initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();

        if (_ccipRouter == address(0) || _comicNFTContract == address(0))
            revert Errors.ZeroAddress();

        ccipRouter       = ICCIPRouter(_ccipRouter);
        uniswapRouter    = IUniswapRouter(_uniswapRouter);
        comicNFTContract = _comicNFTContract;
    }

    // ─── 暂停机制 ──────────────────────────────────────────────────────────

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ─── 核心：发起跨链（锁定 + 发送 CCIP 消息）。“锁定与铸造”（Lock-and-Mint） 模式。

    /// @notice 用户将本链 NFT 跨链到目标链
    /// @param tokenId           要跨链的 NFT Token ID
    /// @param targetChainSelector 目标链 CCIP selector
    /// @param targetRecipient   目标链接收地址
    /// @param feeToken          CCIP 手续费代币（address(0) = ETH）
    function bridgeOut(
        uint256 tokenId,
        uint64  targetChainSelector,
        address targetRecipient,
        address feeToken
    ) external payable whenNotPaused nonReentrant {
        if (targetRecipient == address(0)) revert Errors.ZeroAddress();
        if (supportedChains[targetChainSelector].length == 0)
            revert Errors.UnsupportedChain(targetChainSelector);

        IERC721 nft = IERC721(comicNFTContract);
        if (nft.ownerOf(tokenId) != msg.sender)
            revert Errors.NotTokenOwner(msg.sender, tokenId);
        if (bridgeLocks[tokenId].owner != address(0) && !bridgeLocks[tokenId].released)
            revert Errors.TokenAlreadyLocked(tokenId);

        // ── Effects: 先更新内部状态，标记锁定 ──
        bridgeLocks[tokenId] = DataTypes.BridgeLock({
            owner:         msg.sender,
            tokenId:       tokenId,
            lockedAt:      uint64(block.timestamp),
            chainSelector: targetChainSelector,
            released:      false
        });

        // ── Interactions: 再执行外部调用 ──
        // 1. 锁定 NFT（转入本合约）
        nft.transferFrom(msg.sender, address(this), tokenId);

        // 2. 构造跨链消息 (包含对外部 NFT 合约的读取)
        bytes memory msgData = abi.encode(DataTypes.CrossChainMessage({
            messageType:         DataTypes.CrossChainMessageType.Mint,
            tokenId:             tokenId,
            originalOwner:       msg.sender,
            targetRecipient:     targetRecipient,
            metadataURI:         _getMetadataURI(tokenId),
            originalCreator:     _getCreator(tokenId),
            secondaryRoyaltyBps: _getSecondaryRoyalty(tokenId)
        }));

        ICCIPRouter.EVM2AnyMessage memory ccipMsg = ICCIPRouter.EVM2AnyMessage({
            receiver:   supportedChains[targetChainSelector],
            data:       msgData,
            feeToken:   feeToken == address(0) ? address(0) : feeToken,
            gasLimit:   300_000
        });

        // ── 计算并支付 CCIP 手续费 ──
        uint256 fee = ccipRouter.getFee(targetChainSelector, ccipMsg);

        bytes32 messageId;
        if (feeToken == address(0)) {
            if (msg.value < fee) revert Errors.InsufficientPayment(msg.value, fee);
            messageId = ccipRouter.ccipSend{value: fee}(targetChainSelector, ccipMsg);

            // 退还多余 ETH
            if (msg.value > fee) {
                (bool ok,) = payable(msg.sender).call{value: msg.value - fee}("");
                if (!ok) revert Errors.TransferFailed(msg.sender, msg.value - fee);
            }
        } else {
            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(feeToken).forceApprove(address(ccipRouter), fee);
            messageId = ccipRouter.ccipSend(targetChainSelector, ccipMsg);
        }

        emit BridgeOutInitiated(tokenId, msg.sender, targetChainSelector, targetRecipient, messageId);
    }

    // ─── 核心：反向跨链（销毁封装资产并请求源链解锁）

    /// @notice 目标链调用：销毁封装 NFT 并请求源链解锁原始 NFT
    /// @param tokenId           要跨链回流的 NFT Token ID
    /// @param targetChainSelector 源链 CCIP selector
    /// @param targetRecipient   源链接收地址
    /// @param feeToken          CCIP 手续费代币
    function bridgeIn(
        uint256 tokenId,
        uint64  targetChainSelector,
        address targetRecipient,
        address feeToken
    ) external payable whenNotPaused nonReentrant {
        if (targetRecipient == address(0)) revert Errors.ZeroAddress();
        if (supportedChains[targetChainSelector].length == 0)
            revert Errors.UnsupportedChain(targetChainSelector);

        IComicNFT nft = IComicNFT(comicNFTContract);
        if (IERC721(address(nft)).ownerOf(tokenId) != msg.sender)
            revert Errors.NotTokenOwner(msg.sender, tokenId);

        // ── 销毁封装 NFT ──
        nft.burn(tokenId);

        // ── 构造反向消息（Unlock 类型）──
        bytes memory msgData = abi.encode(DataTypes.CrossChainMessage({
            messageType:         DataTypes.CrossChainMessageType.Unlock,
            tokenId:             tokenId,
            originalOwner:       msg.sender,
            targetRecipient:     targetRecipient,
            metadataURI:         "", // 回流时不需要元数据
            originalCreator:     address(0),
            secondaryRoyaltyBps: 0
        }));

        ICCIPRouter.EVM2AnyMessage memory ccipMsg = ICCIPRouter.EVM2AnyMessage({
            receiver:   supportedChains[targetChainSelector],
            data:       msgData,
            feeToken:   feeToken == address(0) ? address(0) : feeToken,
            gasLimit:   300_000
        });

        // ── 支付并发送 ──
        uint256 fee = ccipRouter.getFee(targetChainSelector, ccipMsg);
        bytes32 messageId;
        if (feeToken == address(0)) {
            if (msg.value < fee) revert Errors.InsufficientPayment(msg.value, fee);
            messageId = ccipRouter.ccipSend{value: fee}(targetChainSelector, ccipMsg);
            if (msg.value > fee) {
                (bool ok,) = payable(msg.sender).call{value: msg.value - fee}("");
                if (!ok) revert Errors.TransferFailed(msg.sender, msg.value - fee);
            }
        } else {
            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(feeToken).forceApprove(address(ccipRouter), fee);
            messageId = ccipRouter.ccipSend(targetChainSelector, ccipMsg);
        }

        emit BridgeInInitiated(tokenId, msg.sender, targetChainSelector, targetRecipient, messageId);
    }

    // ─── 接收跨链消息（处理 Mint 或 Unlock）────────────────────────────────

    /// @notice 由 CCIP 中继调用（接收方链上的此合约）
    /// @dev 实际生产中需继承 CCIPReceiver，此处展示核心逻辑
    function ccipReceive(
        bytes32 messageId,
        uint64  sourceChainSelector,
        bytes   calldata message
    ) external whenNotPaused {
        // 只接受授权的 CCIP Router 调用
        if (msg.sender != address(ccipRouter)) revert Errors.Unauthorized();
        if (processedMessages[messageId]) revert Errors.CrossChainMessageFailed();

        processedMessages[messageId] = true;

        DataTypes.CrossChainMessage memory crossMsg = abi.decode(message, (DataTypes.CrossChainMessage));

        if (crossMsg.messageType == DataTypes.CrossChainMessageType.Mint) {
            // 在目标链铸造封装 NFT
            IComicNFT(comicNFTContract).mint(
                crossMsg.targetRecipient,
                crossMsg.metadataURI,
                crossMsg.secondaryRoyaltyBps,
                0, // 衍生品逻辑在此示例中保持简单
                false,
                0
            );
        } else if (crossMsg.messageType == DataTypes.CrossChainMessageType.Unlock) {
            // 在源链释放锁定的 NFT
            DataTypes.BridgeLock storage lock = bridgeLocks[crossMsg.tokenId];
            if (lock.owner == address(0) || lock.released) 
                revert Errors.TokenNotLocked(crossMsg.tokenId);

            lock.released = true;
            IERC721(comicNFTContract).transferFrom(address(this), crossMsg.targetRecipient, crossMsg.tokenId);
        }

        emit BridgeInCompleted(
            crossMsg.tokenId,
            crossMsg.targetRecipient,
            sourceChainSelector,
            messageId
        );
    }

    // ─── 跨链失败回滚（由 owner 手动触发）────────────────────────────────

    /// @notice 跨链失败时，owner 释放锁定，NFT 归还原持有者
    /// @param tokenId 失败的 NFT Token ID
    function rollback(uint256 tokenId) external onlyOwner {
        DataTypes.BridgeLock storage lock = bridgeLocks[tokenId];
        if (lock.owner == address(0)) revert Errors.TokenNotLocked(tokenId);
        if (lock.released)            revert Errors.TokenNotLocked(tokenId);

        lock.released = true;

        IERC721(comicNFTContract).transferFrom(address(this), lock.owner, tokenId);

        emit BridgeRolledBack(tokenId, lock.owner);
    }

    // ─── Uniswap 代币兑换（跨链前的代币准备）──────────────────────────────

    /// @notice 将用户持有的代币换成目标链所需代币（用于支付跨链费用）
    /// @param tokenIn       输入代币
    /// @param tokenOut      输出代币（目标链所需）
    /// @param amountIn      输入数量
    /// @param amountOutMin  最低接受输出量（防滑点）
    /// @param fee           Uniswap 池手续费（500/3000/10000）
    function swapForBridgeFee(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24  fee
    ) external whenNotPaused returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(address(uniswapRouter), amountIn);

        amountOut = uniswapRouter.exactInputSingle(
            IUniswapRouter.ExactInputSingleParams({
                tokenIn:           tokenIn,
                tokenOut:          tokenOut,
                fee:               fee,
                recipient:         msg.sender,
                deadline:          block.timestamp + 15 minutes,
                amountIn:          amountIn,
                amountOutMinimum:  amountOutMin,
                sqrtPriceLimitX96: 0
            })
        );

        emit TokenSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    // ─── 查询 ─────────────────────────────────────────────────────────────

    function getBridgeLock(uint256 tokenId) external view returns (DataTypes.BridgeLock memory) {
        return bridgeLocks[tokenId];
    }

    function isMessageProcessed(bytes32 messageId) external view returns (bool) {
        return processedMessages[messageId];
    }

    // ─── 管理配置 ─────────────────────────────────────────────────────────

    function addSupportedChain(uint64 chainSelector, bytes calldata receiverAddress) external onlyOwner {
        supportedChains[chainSelector] = receiverAddress;
        emit ChainAdded(chainSelector, receiverAddress);
    }

    function removeSupportedChain(uint64 chainSelector) external onlyOwner {
        delete supportedChains[chainSelector];
        emit ChainRemoved(chainSelector);
    }

    // ─── 内部工具（读取 NFT 信息）────────────────────────────────────────

    function _getMetadataURI(uint256 tokenId) internal view returns (string memory) {
        return IComicNFT(comicNFTContract).tokenURI(tokenId);
    }

    function _getCreator(uint256 tokenId) internal view returns (address creator) {
        DataTypes.ComicInfo memory info = IComicNFT(comicNFTContract).getComicInfo(tokenId);
        return info.creator;
    }

    function _getSecondaryRoyalty(uint256 tokenId) internal view returns (uint16) {
        DataTypes.ComicInfo memory info = IComicNFT(comicNFTContract).getComicInfo(tokenId);
        return info.secondaryRoyaltyBps;
    }

    // ─── UUPS 升级 ────────────────────────────────────────────────────────

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    // ─── 事件 ─────────────────────────────────────────────────────────────

    event BridgeOutInitiated(
        uint256 indexed tokenId,
        address indexed owner,
        uint64  targetChain,
        address targetRecipient,
        bytes32 messageId
    );
    event BridgeInInitiated(
        uint256 indexed tokenId,
        address indexed owner,
        uint64  targetChain,
        address targetRecipient,
        bytes32 messageId
    );
    event BridgeInCompleted(
        uint256 indexed tokenId,
        address indexed recipient,
        uint64  sourceChain,
        bytes32 messageId
    );
    event BridgeRolledBack(uint256 indexed tokenId, address indexed owner);
    event TokenSwapped(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event ChainAdded(uint64 chainSelector, bytes receiverAddress);
    event ChainRemoved(uint64 chainSelector);
}
