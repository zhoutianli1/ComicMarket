// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DataTypes } from "../libraries/DataTypes.sol";

// ─────────────────────────────────────────────────────────────────────────────
// IComicNFT
// ─────────────────────────────────────────────────────────────────────────────

interface IComicNFT {
    event ComicMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string  metadataURI,
        bool    isDerivative,
        uint256 parentTokenId
    );
    /// @notice 当漫画 NFT 的版税信息更新时触发
    event RoyaltyUpdated(uint256 indexed tokenId, uint16 secondaryRoyaltyBps);
    /// @notice 当漫画 NFT 的衍生品分成信息更新时触发
    event DerivativeShareUpdated(uint256 indexed tokenId, uint16 derivativeShareBps);

    function mint(
        address to,
        string  calldata metadataURI,
        uint16  secondaryRoyaltyBps,
        uint16  derivativeShareBps,
        bool    isDerivative,
        uint256 parentTokenId
    ) external returns (uint256 tokenId);

    /// @notice 更新漫画 NFT 的二级市场版税信息，只有创作者或授权的管理员可以调用
    function updateSecondaryRoyalty(uint256 tokenId, uint16 newBps) external;
    /// @notice 更新漫画 NFT 的衍生品分成信息，只有创作者或授权的管理员可以调用
    function updateDerivativeShare(uint256 tokenId, uint16 newBps) external;
    
    //视图函数
    /// @notice 获取漫画 NFT 的详细信息，包括基本属性和版税信息
    function getComicInfo(uint256 tokenId) external view returns (DataTypes.ComicInfo memory);
    /// @notice 获取漫画 NFT 的版税信息，包含创作者、二级市场版税和衍生品分成
    function getIPFamily(uint256 tokenId)  external view returns (DataTypes.IPFamily  memory);
    /// @notice 获取漫画 NFT 的元数据 URI
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// ─────────────────────────────────────────────────────────────────────────────
// IRoyaltySplitter
// ─────────────────────────────────────────────────────────────────────────────

interface IRoyaltySplitter {
    event RoyaltyDistributed(
        uint256 indexed tokenId,
        uint256 saleAmount,
        uint256 creatorShare,
        uint256 derivativeShare,
        uint256 platformShare,
        uint256 sellerShare
    );

    function distribute(
        uint256 tokenId,
        address nftContract,
        address seller,
        uint256 saleAmount,
        address paymentToken
    ) external payable returns (
        uint256 creatorShare,
        uint256 derivativeShare,
        uint256 platformShare,
        uint256 sellerProceeds
    );
}


// ─────────────────────────────────────────────────────────────────────────────
// IMarketplace
// ─────────────────────────────────────────────────────────────────────────────

interface IMarketplace {
    
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    );
    event ListingCancelled(uint256 indexed listingId);
    event Sale(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 price,
        uint256 creatorRoyalty,
        uint256 derivativeRoyalty,
        uint256 platformFee,
        uint256 sellerProceeds
    );
    event AuctionCreated(uint256 indexed auctionId, uint256 tokenId, uint64 endTime);
    event BidPlaced(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionSettled(uint256 indexed auctionId, address winner, uint256 finalPrice);
    event OfferMade(uint256 indexed listingId, address bidder, uint256 amount);

    function list(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) external returns (uint256 listingId);

    function cancelListing(uint256 listingId) external;

    function buy(uint256 listingId) external payable;

    function batchBuy(uint256[] calldata listingIds) external payable;

    function makeOffer(uint256 listingId, uint256 amount, address paymentToken, uint64 expiredAt) external payable;

    function acceptOffer(uint256 listingId, address offerBidder) external;

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 reservePrice,
        address paymentToken,
        uint64  duration
    ) external returns (uint256 auctionId);

    function bid(uint256 auctionId, uint256 amount) external payable;

    function settleAuction(uint256 auctionId) external;

    function getListing(uint256 listingId) external view returns (DataTypes.Listing memory);
    function getAuction(uint256 auctionId)  external view returns (DataTypes.Auction  memory);
}

// ─────────────────────────────────────────────────────────────────────────────
// ICCIPRouter  （Chainlink CCIP 最小接口）
// ─────────────────────────────────────────────────────────────────────────────
//只包含两个方法签名 ccipSend 和 getFee，合约编译完全不依赖 Chainlink 的库。
//运行时部署时传入真实的 Chainlink CCIP Router 地址就可以工作，编译期不需要它的源码。
interface ICCIPRouter {
    struct EVM2AnyMessage {
        bytes   receiver;
        bytes   data;
        address feeToken;
        uint256 gasLimit;
    }

    function ccipSend(uint64 destinationChainSelector, EVM2AnyMessage calldata message)
        external payable returns (bytes32 messageId);

    function getFee(uint64 destinationChainSelector, EVM2AnyMessage calldata message)
        external view returns (uint256 fee);
}

// ─────────────────────────────────────────────────────────────────────────────
// IUniswapRouter  （V3 最小接口，用于跨链代币兑换）
//运行时部署时传入真实的 UniswapRouter 地址就可以工作，编译期不需要它的源码。
// ─────────────────────────────────────────────────────────────────────────────

interface IUniswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external payable returns (uint256 amountOut);
}
