// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { ComicNFT }        from "../src/core/ComicNFT.sol";
import { Marketplace }     from "../src/core/Marketplace.sol";
import { RoyaltySplitter } from "../src/core/RoyaltySplitter.sol";
import { BountyBoard }     from "../src/bounty/BountyBoard.sol";
import { DataTypes }       from "../src/libraries/DataTypes.sol";
import { Errors }          from "../src/libraries/Errors.sol";
import { PercentageMath }  from "../src/libraries/PercentageMath.sol";

/// @title ComicMarketTest
/// @notice 核心流程测试（Foundry）
contract ComicMarketTest is Test {

    // ── 合约实例 ──
    ComicNFT        comicNFT;
    RoyaltySplitter splitter;
    Marketplace     marketplace;
    BountyBoard     bountyBoard;

    // ── 测试账户 ──
    address owner     = makeAddr("owner");
    address treasury  = makeAddr("treasury");
    address creator   = makeAddr("creator");
    address collector = makeAddr("collector");
    address fan       = makeAddr("fan");
    address derCreator = makeAddr("derivativeCreator");

    uint256 constant MINT_PRICE      = 1 ether;
    uint256 constant SECONDARY_PRICE = 2 ether;
    string  constant IPFS_URI        = "ipfs://QmTest123";

    function setUp() public {
        vm.startPrank(owner);

        // 部署逻辑合约 + 代理
        ComicNFT        nftImpl      = new ComicNFT();
        RoyaltySplitter splitterImpl = new RoyaltySplitter();
        Marketplace     mktImpl      = new Marketplace();
        BountyBoard     bountyImpl   = new BountyBoard();
        // 部署 ComicNFT 代理
        comicNFT = ComicNFT(address(new ERC1967Proxy(
            address(nftImpl),
            abi.encodeCall(ComicNFT.initialize, (owner))
        )));
        // 部署 RoyaltySplitter 代理
        splitter = RoyaltySplitter(payable(address(new ERC1967Proxy(
            address(splitterImpl),
            abi.encodeCall(RoyaltySplitter.initialize, (owner, address(comicNFT), treasury, address(0)))
        ))));
        // 部署 Marketplace 代理
        marketplace = Marketplace(payable(address(new ERC1967Proxy(
            address(mktImpl),
            abi.encodeCall(Marketplace.initialize, (owner, address(splitter)))
        ))));
        // 部署 BountyBoard 代理
        bountyBoard = BountyBoard(payable(address(new ERC1967Proxy(
            address(bountyImpl),
            abi.encodeCall(BountyBoard.initialize, (owner))
        ))));

        comicNFT.setMarketplaceContract(address(marketplace));
        splitter.setMarketplaceContract(address(marketplace));

        vm.stopPrank();

        // 给测试账户充值
        vm.deal(creator,    10 ether);
        vm.deal(collector,  10 ether);
        vm.deal(fan,        10 ether);
        vm.deal(derCreator, 10 ether);
    }

    // ════════════════════════════════════════════════════════════════
    // 铸造测试
    // ════════════════════════════════════════════════════════════════

    function test_MintSuccess() public {
        vm.prank(creator);
        uint256 tokenId = comicNFT.mint(
            creator, IPFS_URI,
            500,  // 5%  二级版税
            500,  // 5%  衍生品分成
            false, 0
        );

        assertEq(tokenId, 1);
        assertEq(comicNFT.ownerOf(tokenId), creator);

        DataTypes.ComicInfo memory info = comicNFT.getComicInfo(tokenId);
        assertEq(info.creator, creator);
        assertEq(info.secondaryRoyaltyBps, 500);
        assertFalse(info.isDerivative);
    }

    function test_MintDerivative() public {
        // 先铸造原作
        vm.prank(creator);
        uint256 parentId = comicNFT.mint(creator, IPFS_URI, 500, 500, false, 0);

        // 铸造二创
        vm.prank(derCreator);
        uint256 derTokenId = comicNFT.mint(
            derCreator, "ipfs://derivative", 500, 500, true, parentId
        );

        DataTypes.ComicInfo memory info = comicNFT.getComicInfo(derTokenId);
        assertTrue(info.isDerivative);
        assertEq(info.parentTokenId, parentId);
        assertEq(info.derivativeCreator, derCreator);

        // IP 家族更新
        DataTypes.IPFamily memory family = comicNFT.getIPFamily(parentId);
        assertEq(family.totalDerivatives, 1);
        assertEq(family.derivativeTokenIds[0], derTokenId);
    }

    function test_MintRevertsWhenPaused() public {
        vm.prank(owner);
        comicNFT.pause();

        vm.prank(creator);
        vm.expectRevert();
        comicNFT.mint(creator, IPFS_URI, 500, 500, false, 0);
    }

    // ════════════════════════════════════════════════════════════════
    // 市场交易测试
    // ════════════════════════════════════════════════════════════════

    function _mintAndList() internal returns (uint256 tokenId, uint256 listingId) {
        vm.prank(creator);
        tokenId = comicNFT.mint(creator, IPFS_URI, 500, 500, false, 0);

        vm.startPrank(creator);
        comicNFT.approve(address(marketplace), tokenId);
        listingId = marketplace.list(address(comicNFT), tokenId, SECONDARY_PRICE, address(0));
        vm.stopPrank();
    }

    function test_ListAndBuy() public {
        (uint256 tokenId, uint256 listingId) = _mintAndList();

        // uint256 creatorBalBefore  = address(creator).balance;
        // uint256 treasuryBalBefore = address(treasury).balance;

        vm.prank(collector);
        marketplace.buy{value: SECONDARY_PRICE}(listingId);

        // NFT 已转给买家
        assertEq(comicNFT.ownerOf(tokenId), collector);

        // 验证版税分配到 RoyaltySplitter 的 pendingWithdrawals
        // 平台费 2.5% = 0.05 ETH
        uint256 expectedPlatformFee = (SECONDARY_PRICE * 250) / 10_000;
        assertEq(
            splitter.pendingWithdrawals(treasury, address(0)),
            expectedPlatformFee
        );

        // 创作者二级版税 5% = 0.1 ETH
        uint256 expectedCreatorRoyalty = (SECONDARY_PRICE * 500) / 10_000;
        assertEq(
            splitter.pendingWithdrawals(creator, address(0)),
            expectedCreatorRoyalty
        );
    }

    function test_BuyRevertsOnSelfPurchase() public {
        (, uint256 listingId) = _mintAndList();

        vm.prank(creator);
        vm.expectRevert(Errors.SelfPurchase.selector);
        marketplace.buy{value: SECONDARY_PRICE}(listingId);
    }

    function test_CancelListing() public {
        (, uint256 listingId) = _mintAndList();

        vm.prank(creator);
        marketplace.cancelListing(listingId);

        DataTypes.Listing memory listing = marketplace.getListing(listingId);
        assertFalse(listing.active);
    }

    function test_BatchBuyMaxSize() public {
        uint256[] memory ids = new uint256[](11);
        vm.prank(collector);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BatchSizeExceeded.selector, 11, 10)
        );
        marketplace.batchBuy{value: 0}(ids);
    }

    // ════════════════════════════════════════════════════════════════
    // 版税计算测试
    // ════════════════════════════════════════════════════════════════

    function test_PercentageMathSplitProceeds() public pure {
        // 100 ETH 成交，二级版税 10%，无衍生品
        (
            uint256 creatorShare,
            uint256 derivativeShare,
            uint256 platformShare,
            uint256 sellerShare
        ) = PercentageMath.splitProceeds(100 ether, 1000, 0);

        assertEq(creatorShare,    10 ether);   // 10%
        assertEq(derivativeShare, 0);           // 无二创
        assertEq(platformShare,   2.5 ether);  // 2.5%
        assertEq(sellerShare,     87.5 ether); // 87.5%
        assertEq(
            creatorShare + derivativeShare + platformShare + sellerShare,
            100 ether
        );
    }

    // ════════════════════════════════════════════════════════════════
    // 悬赏任务测试
    // ════════════════════════════════════════════════════════════════

    function test_BountyFullFlow() public {
        uint256 reward   = 1 ether;
        uint64  deadline = uint64(block.timestamp + 7 days);
        uint64  review   = 7 days;

        // 1. 创建悬赏
        vm.prank(creator);
        uint256 bountyId = bountyBoard.createBounty{value: reward}(
            1, DataTypes.BountyType.Coloring, reward, address(0),
            deadline, review, "ipfs://requirements"
        );

        // 2. 贡献者申请
        vm.prank(fan);
        bountyBoard.applyBounty(bountyId);

        // 3. 指定中标者
        vm.prank(creator);
        bountyBoard.assignBounty(bountyId, fan);

        // 4. 提交作品
        vm.prank(fan);
        bountyBoard.submitBounty(bountyId, "ipfs://submission");

        // 5. 验收通过
        uint256 fanBalBefore = address(fan).balance;
        vm.prank(creator);
        bountyBoard.approveBounty(bountyId);

        // 奖金到账
        assertEq(address(fan).balance, fanBalBefore + reward);

        DataTypes.BountyTask memory task = bountyBoard.getBounty(bountyId);
        assertEq(uint8(task.status), uint8(DataTypes.BountyStatus.Completed));
    }

    function test_BountyTimeoutClaim() public {
        uint256 reward  = 0.5 ether;
        uint64  review  = 7 days;

        vm.prank(creator);
        uint256 bountyId = bountyBoard.createBounty{value: reward}(
            1, DataTypes.BountyType.Translation, reward, address(0),
            uint64(block.timestamp + 7 days), review, "ipfs://req"
        );

        vm.prank(fan);
        bountyBoard.applyBounty(bountyId);
        vm.prank(creator);
        bountyBoard.assignBounty(bountyId, fan);
        vm.prank(fan);
        bountyBoard.submitBounty(bountyId, "ipfs://sub");

        // 模拟超过 reviewPeriod
        vm.warp(block.timestamp + 8 days);

        uint256 fanBal = address(fan).balance;
        vm.prank(fan);
        bountyBoard.claimByTimeout(bountyId);

        assertEq(address(fan).balance, fanBal + reward);
    }

    // ════════════════════════════════════════════════════════════════
    // 暂停机制测试
    // ════════════════════════════════════════════════════════════════

    function test_PauseBlocksAllOperations() public {
        // 暂停 marketplace
        vm.prank(owner);
        marketplace.pause();

        // 挂单应被阻止
        vm.prank(creator);
        vm.expectRevert();
        marketplace.list(address(comicNFT), 1, 1 ether, address(0));

        // 恢复
        vm.prank(owner);
        marketplace.unpause();
    }

    function test_OnlyOwnerCanPause() public {
        vm.prank(creator); // 非 owner
        vm.expectRevert();
        marketplace.pause();
    }

    // ════════════════════════════════════════════════════════════════
    // 版税提取测试
    // ════════════════════════════════════════════════════════════════

    function test_WithdrawRoyalty() public {
        // 先完成一笔交易
        (,uint256 listingId) = _mintAndList();
        vm.prank(collector);
        marketplace.buy{value: SECONDARY_PRICE}(listingId);

        // creator 提取版税
        uint256 pending = splitter.pendingWithdrawals(creator, address(0));
        assertTrue(pending > 0);

        uint256 balBefore = address(creator).balance;
        vm.prank(creator);
        splitter.withdraw(address(0));

        assertEq(address(creator).balance, balBefore + pending);
        assertEq(splitter.pendingWithdrawals(creator, address(0)), 0);
    }
}
