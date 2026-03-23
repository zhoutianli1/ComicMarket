// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Errors
/// @notice 全局自定义错误定义（比 require(string) 节省 ~50% Gas）
library Errors {

    // ── 通用 ──────────────────────────────────────────────────────
    error ZeroAddress();
    error ZeroAmount();
    error Unauthorized();
    error InvalidParameter(string param);
    error ContractPaused();

    // ── NFT 铸造 ──────────────────────────────────────────────────
    error InvalidMetadataURI();
    error SecondaryRoyaltyTooHigh(uint16 given, uint16 max); // max 1000
    error ParentTokenNotExists(uint256 parentTokenId);// 二创父级不存在
    error NotTokenOwner(address caller, uint256 tokenId);// 不是 NFT 拥有者
    error TokenNotExists(uint256 tokenId);

    // ── 市场交易 ──────────────────────────────────────────────────
    error ListingNotActive(uint256 listingId);// 列表不存在或已下架
    error NotSeller(address caller);// 不是卖家
    error InsufficientPayment(uint256 sent, uint256 required);// 付款不足
    error NFTNotApproved();// 卖家未授权市场合约转移 NFT
    error SelfPurchase();// 卖家试图购买自己的 NFT
    error BatchSizeExceeded(uint256 given, uint256 max); // max 10

    // ── 拍卖 ──────────────────────────────────────────────────────
    error AuctionNotActive(uint256 auctionId);// 拍卖不存在或未开始
    error AuctionNotEnded(uint256 auctionId);// 拍卖未结束
    error AuctionAlreadySettled(uint256 auctionId);// 拍卖已结算
    error BidTooLow(uint256 bid, uint256 minRequired);// 出价过低
    error AuctionEndTimeTooShort();// 拍卖结束时间必须至少 1 小时后

    // ── IP 授权 ──────────────────────────────────────────────────
    error LicenseNotPending(uint256 licenseId);
    error LicenseExpired(uint256 licenseId);
    error InsufficientDeposit(uint256 sent, uint256 required);
    error NotLicensee(address caller, uint256 licenseId);

    // ── 悬赏任务 ──────────────────────────────────────────────────
    error BountyNotOpen(uint256 bountyId);// 悬赏不存在或未开放
    error BountyDeadlinePassed(uint256 bountyId);// 已过截止日期
    error BountyReviewPeriodNotElapsed(uint256 bountyId);// 评审期未结束
    error InvalidReviewPeriod(uint64 given, uint64 minDays, uint64 maxDays);// 评审期必须在 1-30 天之间
    error NotBountyPublisher(address caller, uint256 bountyId);// 不是悬赏发布者
    error NotBountyAssignee(address caller, uint256 bountyId);// 不是悬赏领取者

    // ── 版税拆分 ──────────────────────────────────────────────────
    error RoyaltyBpsOverflow(uint256 total); // 所有分成之和 > 10000
    error TransferFailed(address to, uint256 amount);

    // ── 跨链桥 ───────────────────────────────────────────────────
    error TokenAlreadyLocked(uint256 tokenId);// 试图锁定已锁定的 NFT
    error TokenNotLocked(uint256 tokenId);// 试图解锁未锁定的 NFT
    error UnsupportedChain(uint64 chainSelector);// 不支持的链
    error CrossChainMessageFailed();// 跨链消息发送失败
}
