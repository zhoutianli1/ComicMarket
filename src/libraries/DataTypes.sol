// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DataTypes
/// @notice 全局共享数据结构定义，所有合约通过此库引用
library DataTypes {

    // ─────────────────────────────────────────────────────────────
    // NFT 作品相关
    // ─────────────────────────────────────────────────────────────

    /// @notice 漫画作品元数据与版税配置，分为原创作品和二创作品两种情况。二创作品必须关联一个原创作品，并且可以选择是否给原创作品分成。
    /// @dev creator/metadataURI/isDerivative 铸造后永久不可修改
    struct ComicInfo {
        string  metadataURI;         // IPFS URI，来源于链下存储，包含漫画作品的基本信息和内容地址
        address creator;             // 原始创作者（永久）
        uint16  secondaryRoyaltyBps; // 二级市场转卖版税（max 1000 = 10%），转给原创作者
        uint16  derivativeShareBps;  // 二创衍生品销售额中，原创作者分成（默认 500 = 5%）
        bool    isDerivative;        // 是否为二创作品
        uint256 parentTokenId;       // 原作 Token ID（非二创为 0）
        address derivativeCreator;   // 二创作者（非二创为 address(0)）
    }

    /// @notice IP 家族统计（原作维度），用于展示和二创版税分成计算，不存储在链上，而是通过事件和链下索引计算得出
    struct IPFamily {
        uint256   totalDerivatives; // 原作下的二创作品总数
        uint256[] derivativeTokenIds; // 原作下的二创作品 Token ID 列表（仅展示前 10 个，剩余通过链下索引查询）
        uint256   totalRoyaltyEarned; // wei，原作从二创作品销售中获得的累计版税收入（仅统计二创销售额 * derivativeShareBps 部分）
    }

    // ─────────────────────────────────────────────────────────────
    // 市场交易相关
    // ─────────────────────────────────────────────────────────────

    struct Listing {
        address seller;// 卖家地址
        address nftContract;
        uint256 tokenId;// 唯一标识一件 NFT
        uint256 price;        // wei
        address paymentToken; // address(0) = 原生 ETH
        bool    active;
        uint64  listedAt;// 上架时间戳
    }

    struct Offer {
        address bidder;// 买家地址
        uint256 amount;       // wei，出价金额
        address paymentToken;
        uint64  expiredAt;// 过期时间戳
        bool    active;
    }

    struct Auction {
        address seller;// 卖家地址
        address nftContract;
        uint256 tokenId;
        uint256 startPrice;// wei, 起拍价
        uint256 reservePrice;// wei, 保底价，0 表示无保底价
        uint256 currentBid;// wei, 当前最高出价
        address currentBidder;// 当前最高出价者
        address paymentToken;
        uint64  startTime;
        uint64  endTime;
        bool    settled;
    }

    // ─────────────────────────────────────────────────────────────
    // 版税拆分相关
    // ─────────────────────────────────────────────────────────────

    struct RoyaltySplit {
        address creator;
        uint16  creatorBps;// 原创作品版税比例
        address derivativeCreator; // address(0) 表示非二创
        uint16  derivativeBps;// 二创作品版税比例（如果是二创）
        address platform;// 固定平台地址，平台分成固定为 250 bps = 2.5%
        uint16  platformBps;       // 固定 250 = 2.5%
    }

    // ─────────────────────────────────────────────────────────────
    // IP 授权相关
    // ─────────────────────────────────────────────────────────────

    enum LicenseStatus { Pending, Approved, Rejected, Revoked }

    struct LicenseGrant {
        uint256       parentTokenId;// 原作 Token ID
        address       licensee;// 被授权人
        LicenseStatus status;// 授权状态
        uint16        royaltyBps;// 被授权作品的版税比例（max 500 = 5%）
        uint256       depositAmount; // 保证金 wei（授权费的 20%）
        uint64        grantedAt;// 授权时间戳
        uint64        expiresAt;     // 0 = 永久
        bool          commercialUse;// 是否允许商业用途
    }

    // ─────────────────────────────────────────────────────────────
    // 悬赏任务相关
    // ─────────────────────────────────────────────────────────────

    enum BountyType   { Translation, Coloring, Dubbing, Other }
    enum BountyStatus { Open, InReview, Completed, Cancelled }
    // 任务发布者发布一个与某个漫画作品相关的悬赏任务，指定奖励金额、截止日期、评审周期等信息。用户可以领取任务并提交成果，发布者在评审周期结束后审核并发放奖励。
    struct BountyTask {
        address      publisher;// 任务发布者
        uint256      tokenId;// 关联的漫画作品 Token ID
        BountyType   taskType;// 任务类型：翻译、上色、配音、其他
        BountyStatus status;// 任务状态
        uint256      reward;        // wei
        address      paymentToken;  // address(0) = ETH
        address      assignee;// 任务承接者
        uint64       deadline;// 截止日期
        uint64       reviewPeriod;  // 7-30天（秒）
        string       requirementURI;// 任务要求描述的 IPFS URI
        string       submissionURI;
    }

    // ─────────────────────────────────────────────────────────────
    // 跨链相关
    // ─────────────────────────────────────────────────────────────
    
    enum CrossChainMessageType { Mint, Unlock }

    // 跨链消息结构体，包含跨链所需的所有信息，确保跨链后 NFT 的信息和版税分成计算的一致性
    //是将NFT从一个链转移到另一个链的过程中，携带必要的信息以确保跨链后 NFT 的属性和版税分成计算的一致性。这个结构体包含了以下字段：
    struct CrossChainMessage {
        CrossChainMessageType messageType;// 跨链消息类型：铸造（去）或 解锁（回）
        uint256 tokenId;// 跨链的 NFT Token ID
        address originalOwner;// 跨链前的拥有者
        address targetRecipient;// 跨链后的接收者
        string  metadataURI;// 跨链时携带的元数据 URI，确保跨链后 NFT 的信息一致
        address originalCreator;// 跨链前的创作者地址
        uint16  secondaryRoyaltyBps;// 跨链后如果是二创，二级市场版税比例（max 1000 = 10%）
    }
    // 跨链锁定信息结构体，记录被锁定的 NFT 的相关信息，确保在跨链过程中 NFT 不会被重复使用或转移
    struct BridgeLock {
        address owner;// 锁定 NFT 的拥有者
        uint256 tokenId;
        uint64  lockedAt;// 锁定时间戳
        uint64  chainSelector; // CCIP 目标链 selector
        bool    released;
    }
}
