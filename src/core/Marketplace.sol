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

import { DataTypes }       from "../libraries/DataTypes.sol";
import { Errors }          from "../libraries/Errors.sol";
import { PercentageMath }  from "../libraries/PercentageMath.sol";
import { IMarketplace, IRoyaltySplitter } from "../interfaces/IAll.sol";

/// @title Marketplace
/// @notice 漫画 NFT 市场交易合约（UUPS 可升级）
/// @dev
///   功能：
///   1. 固定价格挂单 / 取消 / 购买（支持批量，最多 10 个）
///   2. 出价 / 接受出价
///   3. 英式拍卖（含保留价）
///   4. 所有成交自动调用 RoyaltySplitter 拆分版税
///   5. 紧急暂停机制（停止所有交易）
///
///   安全模式：检查-效果-交互（CEI），ReentrancyGuard，Pausable
contract Marketplace is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    UUPSUpgradeable,
    IMarketplace
{
    using SafeERC20 for IERC20;

    // ─── 常量 ──────────────────────────────────────────────────────────────

    uint256 public constant MAX_BATCH_SIZE      = 10;// 批量购买最大数量
    uint64  public constant MIN_AUCTION_DURATION = 1 hours;// 拍卖最短持续时间
    uint64  public constant MAX_AUCTION_DURATION = 30 days;

    // ─── 存储 ──────────────────────────────────────────────────────────────

    address public royaltySplitter;

    uint256 private _nextListingId;// 挂单 ID 递增计数器
    uint256 private _nextAuctionId;// 拍卖 ID 递增计数器
    //商品ID => 挂单信息
    mapping(uint256 => DataTypes.Listing)                    private _listings;
    //拍卖ID => 拍卖信息
    mapping(uint256 => DataTypes.Auction)                    private _auctions;
    // listingId => bidder投标人地址 => Offer：支持同一挂单多个买家出价，每个买家只能有一个有效出价
    mapping(uint256 => mapping(address => DataTypes.Offer))  private _offers;
    // 支持的支付代币白名单
    mapping(address => bool) public supportedPaymentTokens;

    // ─── 修饰符 ────────────────────────────────────────────────────────────
    // 验证挂单是否有效
    modifier validListing(uint256 listingId) {
        if (!_listings[listingId].active) revert Errors.ListingNotActive(listingId);
        _;
    }
    // 验证拍卖是否有效
    modifier validAuction(uint256 auctionId) {
        DataTypes.Auction storage a = _auctions[auctionId];
        if (a.seller == address(0) || a.settled) revert Errors.AuctionNotActive(auctionId);
        if (block.timestamp > a.endTime) revert Errors.AuctionNotActive(auctionId);
        _;
    }

    // ─── 初始化 ────────────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address _royaltySplitter
    ) external initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();

        if (_royaltySplitter == address(0)) revert Errors.ZeroAddress();
        royaltySplitter = _royaltySplitter;

        // ETH 默认支持（address(0) 表示原生 ETH）
        supportedPaymentTokens[address(0)] = true;
        _nextListingId = 1;
        _nextAuctionId = 1;
    }

    // ─── 暂停机制（安全关键）─────────────────────────────────────────────────

    /// @notice 紧急暂停所有交易
    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ─── 一、固定价格挂单 ────────────────────────────────────────────────────

    /// @notice 创建挂单
    function list(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) external override whenNotPaused returns (uint256 listingId) {
        if (price == 0) revert Errors.ZeroAmount();
        if (!supportedPaymentTokens[paymentToken]) revert Errors.InvalidParameter("paymentToken");

        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) revert Errors.NotTokenOwner(msg.sender, tokenId);
        if (nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))// 全局授权
        ) revert Errors.NFTNotApproved();

        listingId = _nextListingId++;
        _listings[listingId] = DataTypes.Listing({
            seller:       msg.sender,
            nftContract:  nftContract,
            tokenId:      tokenId,
            price:        price,
            paymentToken: paymentToken,
            active:       true,
            listedAt:     uint64(block.timestamp)
        });

        emit Listed(listingId, msg.sender, nftContract, tokenId, price, paymentToken);
    }

    /// @notice 取消挂单
    function cancelListing(uint256 listingId)
        external override validListing(listingId)
    {
        DataTypes.Listing storage listing = _listings[listingId];
        if (listing.seller != msg.sender) revert Errors.NotSeller(msg.sender);

        listing.active = false;
        emit ListingCancelled(listingId);
    }

    // ─── 二、购买 ────────────────────────────────────────────────────────────
    // 代币的一致性必须一致 。
    /// @notice 直接购买（固定价格）
    function buy(uint256 listingId)
        external payable override
        whenNotPaused nonReentrant validListing(listingId)
    {
        _executeBuy(listingId, msg.sender);
    }

    /// @notice 批量购买（最多 10 个）
    function batchBuy(uint256[] calldata listingIds)
        external payable override
        whenNotPaused nonReentrant
    {
        if (listingIds.length > MAX_BATCH_SIZE)
            revert Errors.BatchSizeExceeded(listingIds.length, MAX_BATCH_SIZE);

        for (uint256 i; i < listingIds.length; ++i) {
            if (_listings[listingIds[i]].active) {
                _executeBuy(listingIds[i], msg.sender);
            }
        }
    }

    /// @dev 内部购买逻辑（CEI 模式）, 处理支付和版税拆分
    function _executeBuy(uint256 listingId, address buyer) internal {
        DataTypes.Listing storage listing = _listings[listingId];

        if (buyer == listing.seller) revert Errors.SelfPurchase();

        // ── 效果：先标记为不可用，防重入 ──
        listing.active = false;

        // ── 交互：转移 NFT ──
        IERC721(listing.nftContract).transferFrom(listing.seller, buyer, listing.tokenId);

        // ── 交互：版税拆分 ──
        (
            uint256 creatorRoyalty,
            uint256 derivativeRoyalty,
            uint256 platformFee,
            uint256 sellerProceeds
        ) = _processPaymentAndSplit(
            listing.tokenId,
            listing.nftContract,
            listing.seller,
            listing.price,
            listing.paymentToken,
            buyer,
            false // isPrepaid: 实时支付
        );

        emit Sale(
            listingId,
            buyer,
            listing.price,
            creatorRoyalty,
            derivativeRoyalty,
            platformFee,
            sellerProceeds
        );
    }

    // ─── 三、出价 ────────────────────────────────────────────────────────────
    //用户出价是通过 msg.value 发送 ETH，或通过 bidERC20 函数发送 ERC20 代币
    // 代币的一致性不必须一致 。出价是一种“议价”行为。即便卖家挂单 1 ETH，买家也可以尝试用 2500 USDC 进行出价。只要卖家认为这个价格合适并调用 acceptOffer ，交易就可以成交
    /// @notice 对某个挂单出价（ERC20 只需授权，ETH 直接发送）
    function makeOffer(
        uint256 listingId,
        uint256 amount,
        address paymentToken,
        uint64  expiredAt
    ) external payable override whenNotPaused validListing(listingId) {
        if (amount == 0) revert Errors.ZeroAmount();
        if (expiredAt <= block.timestamp) revert Errors.InvalidParameter("expiredAt");
        if (!supportedPaymentTokens[paymentToken]) revert Errors.InvalidParameter("paymentToken");

        if (paymentToken == address(0)) {
            if (msg.value < amount) revert Errors.InsufficientPayment(msg.value, amount);
        }

        _offers[listingId][msg.sender] = DataTypes.Offer({
            bidder:       msg.sender,
            amount:       amount,
            paymentToken: paymentToken,
            expiredAt:    expiredAt,
            active:       true
        });

        emit OfferMade(listingId, msg.sender, amount);
    }

    /// @notice 卖家接受出价
    function acceptOffer(uint256 listingId, address offerBidder)
        external override
        whenNotPaused nonReentrant validListing(listingId)
    {
        DataTypes.Listing storage listing = _listings[listingId];
        if (listing.seller != msg.sender) revert Errors.NotSeller(msg.sender);

        DataTypes.Offer storage offer = _offers[listingId][offerBidder];
        if (!offer.active) revert Errors.InvalidParameter("offer");
        if (offer.expiredAt < block.timestamp) revert Errors.InvalidParameter("offerExpired");

        listing.active = false;
        offer.active   = false;

        IERC721(listing.nftContract).transferFrom(listing.seller, offerBidder, listing.tokenId);

        _processPaymentAndSplit(
            listing.tokenId,
            listing.nftContract,
            listing.seller,
            offer.amount,
            offer.paymentToken,
            offerBidder,
            true // isPrepaid: 资金已在 makeOffer 时存入合约（ETH）或授权（ERC20）
        );

        emit Sale(listingId, offerBidder, offer.amount, 0, 0, 0, 0);
    }

    // ─── 四、拍卖 ────────────────────────────────────────────────────────────
    // 代币的一致性必须一致 。拍卖是“价高者得”。如果有人出 1 ETH，有人出 2000 USDC，合约在没有预言机（Oracle）的情况下无法判断哪个价格更高。因此，所有参与竞价的人必须使用拍卖发起者指定的代币。
    /// @notice 创建英式拍卖
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,// 起拍价
        uint256 reservePrice,// 保留价
        address paymentToken,
        uint64  duration // 拍卖持续时间（秒）
    ) external override whenNotPaused returns (uint256 auctionId) {
        if (duration < MIN_AUCTION_DURATION || duration > MAX_AUCTION_DURATION)
            revert Errors.AuctionEndTimeTooShort();
        if (startPrice == 0) revert Errors.ZeroAmount();
        if (!supportedPaymentTokens[paymentToken]) revert Errors.InvalidParameter("paymentToken");

        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) revert Errors.NotTokenOwner(msg.sender, tokenId);
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) revert Errors.NFTNotApproved();

        uint64 endTime = uint64(block.timestamp) + duration;
        auctionId = _nextAuctionId++;

        _auctions[auctionId] = DataTypes.Auction({
            seller:        msg.sender,
            nftContract:   nftContract,
            tokenId:       tokenId,
            startPrice:    startPrice,
            reservePrice:  reservePrice,
            currentBid:    0,
            currentBidder: address(0),
            paymentToken:  paymentToken,
            startTime:     uint64(block.timestamp),
            endTime:       endTime,
            settled:       false
        });

        emit AuctionCreated(auctionId, tokenId, endTime);
    }

    /// @notice 出价（拍卖）
    //用户出价是通过 msg.value 发送 ETH，或通过 bidERC20 函数发送 ERC20 代币
    function bid(uint256 auctionId, uint256 amount)
        external payable override
        whenNotPaused nonReentrant validAuction(auctionId)
    {
        DataTypes.Auction storage auction = _auctions[auctionId];

        uint256 bidAmount;
        if (auction.paymentToken == address(0)) {
            bidAmount = msg.value;
        } else {
            bidAmount = amount;
            // ERC20 竞价需要从用户账户转入合约，待竞价被超越或流拍时再退还给用户
            IERC20(auction.paymentToken).safeTransferFrom(msg.sender, address(this), bidAmount);
        }

        uint256 minBid = auction.currentBid == 0
            ? auction.startPrice
            : (auction.currentBid * 105) / 100; // 最低加价 5%

        if (bidAmount < minBid) revert Errors.BidTooLow(bidAmount, minBid);

        // 退还上一位出价者
        address prevBidder = auction.currentBidder;
        uint256 prevBid    = auction.currentBid;

        auction.currentBid    = bidAmount;
        auction.currentBidder = msg.sender;

        if (prevBidder != address(0) && prevBid > 0) {
            if (auction.paymentToken == address(0)) {
                (bool ok,) = payable(prevBidder).call{value: prevBid}("");
                if (!ok) revert Errors.TransferFailed(prevBidder, prevBid);
            } else {
                IERC20(auction.paymentToken).safeTransfer(prevBidder, prevBid);
            }
        }

        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }

    /// @notice 结算拍卖（任何人可调用，拍卖结束后）
    function settleAuction(uint256 auctionId)
        external override nonReentrant
    {
        DataTypes.Auction storage auction = _auctions[auctionId];
        if (auction.seller == address(0))  revert Errors.AuctionNotActive(auctionId);
        if (auction.settled)               revert Errors.AuctionAlreadySettled(auctionId);
        if (block.timestamp <= auction.endTime) revert Errors.AuctionNotEnded(auctionId);

        auction.settled = true;

        // 未达保留价：退款给出价者，NFT 归还卖家
        if (auction.currentBid < auction.reservePrice || auction.currentBidder == address(0)) {
            if (auction.currentBidder != address(0) && auction.currentBid > 0) {
                (bool ok,) = payable(auction.currentBidder).call{value: auction.currentBid}("");
                if (!ok) revert Errors.TransferFailed(auction.currentBidder, auction.currentBid);
            }
            emit AuctionSettled(auctionId, address(0), 0);
            return;
        }

        // 成交：转移 NFT + 拆分版税
        IERC721(auction.nftContract).transferFrom(
            auction.seller, auction.currentBidder, auction.tokenId
        );

        _processPaymentAndSplit(
            auction.tokenId,
            auction.nftContract,
            auction.seller,
            auction.currentBid,
            auction.paymentToken,
            auction.currentBidder,
            true // isPrepaid: 资金已在 bid 时存入合约（ETH）或授权（ERC20）
        );

        emit AuctionSettled(auctionId, auction.currentBidder, auction.currentBid);
    }

    // ─── 内部：支付 + 版税拆分 ────────────────────────────────────────────────

    /// @dev 统一处理支付和版税拆分，返回各方金额
    /// @param isPrepaid 是否为预付资金（如出价、拍卖中的资金已锁定在合约中）
    function _processPaymentAndSplit(
        uint256 tokenId,
        address nftContract,
        address seller,
        uint256 saleAmount,
        address paymentToken,
        address buyer,
        bool    isPrepaid
    ) internal returns (
        uint256 creatorRoyalty,
        uint256 derivativeRoyalty,
        uint256 platformFee,
        uint256 sellerProceeds
    ) {
        if (paymentToken == address(0)) {
            // ETH 支付
            if (isPrepaid) {
                // 预付模式：资金已在本合约中（来自 makeOffer 或 bid）
                (creatorRoyalty, derivativeRoyalty, platformFee, sellerProceeds) = IRoyaltySplitter(royaltySplitter).distribute{value: saleAmount}(
                    tokenId, nftContract, seller, saleAmount, address(0)
                );
            } else {
                // 实时支付模式：buyer 通过 msg.value 发送
                if (msg.value < saleAmount) revert Errors.InsufficientPayment(msg.value, saleAmount);

                (creatorRoyalty, derivativeRoyalty, platformFee, sellerProceeds) = IRoyaltySplitter(royaltySplitter).distribute{value: saleAmount}(
                    tokenId, nftContract, seller, saleAmount, address(0)
                );

                // 退还多余 ETH 给买家
                uint256 excess = msg.value - saleAmount;
                if (excess > 0) {
                    (bool ok,) = payable(buyer).call{value: excess}("");
                    if (!ok) revert Errors.TransferFailed(buyer, excess);
                }
            }
        } else {
            // ERC20 支付：无论是预付还是实时，均需从相应方扣款并转入 splitter
            // 注意：如果是 Offer，买家已在 makeOffer 时授权；如果是拍卖，买家已在 bid 时转入本合约
            address payer = isPrepaid ? address(this) : buyer;
            
            if (payer == address(this)) {
                IERC20(paymentToken).safeTransfer(royaltySplitter, saleAmount);
            } else {
                IERC20(paymentToken).safeTransferFrom(payer, royaltySplitter, saleAmount);
            }

            (creatorRoyalty, derivativeRoyalty, platformFee, sellerProceeds) = IRoyaltySplitter(royaltySplitter).distribute(
                tokenId, nftContract, seller, saleAmount, paymentToken
            );
        }
    }

    // ─── 查询 ──────────────────────────────────────────────────────────────────

    function getListing(uint256 listingId) external view override returns (DataTypes.Listing memory) {
        return _listings[listingId];
    }

    function getAuction(uint256 auctionId) external view override returns (DataTypes.Auction memory) {
        return _auctions[auctionId];
    }

    function getOffer(uint256 listingId, address bidder) external view returns (DataTypes.Offer memory) {
        return _offers[listingId][bidder];
    }

    // ─── 管理配置 ─────────────────────────────────────────────────────────────

    function addSupportedToken(address token) external onlyOwner {
        supportedPaymentTokens[token] = true;
    }

    function removeSupportedToken(address token) external onlyOwner {
        supportedPaymentTokens[token] = false;
    }

    function setRoyaltySplitter(address newSplitter) external onlyOwner {
        if (newSplitter == address(0)) revert Errors.ZeroAddress();
        royaltySplitter = newSplitter;
    }

    // ─── UUPS 升级 ────────────────────────────────────────────────────────────

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}
}
