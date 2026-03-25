// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import { ComicNFT }             from "../src/core/ComicNFT.sol";
import { Marketplace }          from "../src/core/Marketplace.sol";
import { RoyaltySplitter }      from "../src/core/RoyaltySplitter.sol";
import { BountyBoard }          from "../src/bounty/BountyBoard.sol";
import { CrossChainBridge }     from "../src/crosschain/CrossChainBridge.sol";
import { ComicNFTProxy }        from "../src/proxy/ComicNFTProxy.sol";
import { MarketplaceProxy }     from "../src/proxy/MarketplaceProxy.sol";
import { RoyaltySplitterProxy } from "../src/proxy/RoyaltySplitterProxy.sol";
import { BountyBoardProxy }     from "../src/proxy/BountyBoardProxy.sol";
import { CrossChainBridgeProxy } from "../src/proxy/CrossChainBridgeProxy.sol";

/// @title Deploy
/// @notice 一键部署所有合约（Foundry Script）
/// @dev 运行命令：
///   forge script script/Deploy.s.sol:Deploy \
///     --rpc-url $ABR_RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast \
///     --verify
contract Deploy is Script {

    address CCIP_ROUTER      = vm.envOr("CCIP_ROUTER",      address(0));

    // ── 从环境变量读取配置，需要手动输入 
    address OWNER            = vm.envAddress("OWNER_ADDRESS");
    address PLATFORM_TREASURY = vm.envAddress("PLATFORM_TREASURY");
    address UNISWAP_ROUTER   = vm.envOr("UNISWAP_ROUTER",   address(0));

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        if (deployerKey == 0) {
            revert("PRIVATE_KEY not found in .env");
        }
        vm.startBroadcast(deployerKey);

        console.log(unicode"=== 开始部署去中心化漫画市场合约 ===");
        console.log("Owner:            ", OWNER);
        console.log("Platform Treasury:", PLATFORM_TREASURY);
        console.log("CCIP Router:      ", CCIP_ROUTER);
        console.log("Uniswap Router:   ", UNISWAP_ROUTER);

        // ── Step 1: 部署逻辑合约 ──
        ComicNFT        comicNFTImpl      = new ComicNFT();
        RoyaltySplitter splitterImpl      = new RoyaltySplitter();
        Marketplace     marketplaceImpl   = new Marketplace();
        BountyBoard     bountyBoardImpl   = new BountyBoard();
        CrossChainBridge bridgeImpl       = new CrossChainBridge();

        console.log("Logic contracts deployed.");

        // ── Step 2: 部署具名代理合约并初始化 ──
        // 每个代理合约有独立的类型，便于区块链浏览器识别、前端 ABI 匹配、事件过滤

        // 2a. ComicNFTProxy — 漫画 NFT 永久入口地址
        bytes memory comicNFTInit = abi.encodeCall(ComicNFT.initialize, (OWNER));
        ComicNFTProxy comicNFTProxy = new ComicNFTProxy(address(comicNFTImpl), comicNFTInit);
        address comicNFT = address(comicNFTProxy);
        console.log("ComicNFTProxy:          ", comicNFT);
        console.log("  -> logic impl:        ", comicNFTProxy.implementation());

        // 2b. RoyaltySplitterProxy — 版税拆分器，需先于 Marketplace 部署
        bytes memory splitterInit = abi.encodeCall(
            RoyaltySplitter.initialize,
            (OWNER, comicNFT, PLATFORM_TREASURY, address(0))
        );
        RoyaltySplitterProxy splitterProxy = new RoyaltySplitterProxy(address(splitterImpl), splitterInit);
        address splitter = address(splitterProxy);
        console.log("RoyaltySplitterProxy:   ", splitter);
        console.log("  -> logic impl:        ", splitterProxy.implementation());

        // 2c. MarketplaceProxy — 市场交易永久入口地址
        bytes memory marketplaceInit = abi.encodeCall(
            Marketplace.initialize,
            (OWNER, splitter)
        );
        MarketplaceProxy marketplaceProxy = new MarketplaceProxy(address(marketplaceImpl), marketplaceInit);
        address marketplace = address(marketplaceProxy);
        console.log("MarketplaceProxy:       ", marketplace);
        console.log("  -> logic impl:        ", marketplaceProxy.implementation());

        // 2d. BountyBoardProxy — 悬赏任务永久入口地址
        bytes memory bountyInit = abi.encodeCall(BountyBoard.initialize, (OWNER));
        BountyBoardProxy bountyProxy = new BountyBoardProxy(address(bountyBoardImpl), bountyInit);
        address bountyBoard = address(bountyProxy);
        console.log("BountyBoardProxy:       ", bountyBoard);
        console.log("  -> logic impl:        ", bountyProxy.implementation());

        // 2e. CrossChainBridgeProxy（CCIP/Uniswap 测试网可为占位地址）
        address ccipRouter    = CCIP_ROUTER    != address(0) ? CCIP_ROUTER    : address(1);
        address uniswapRouter = UNISWAP_ROUTER != address(0) ? UNISWAP_ROUTER : address(1);

        bytes memory bridgeInit = abi.encodeCall(
            CrossChainBridge.initialize,
            (OWNER, ccipRouter, uniswapRouter, comicNFT)
        );
        CrossChainBridgeProxy bridgeProxy = new CrossChainBridgeProxy(address(bridgeImpl), bridgeInit);
        address bridge = address(bridgeProxy);
        console.log("CrossChainBridgeProxy:  ", bridge);
        console.log("  -> logic impl:        ", bridgeProxy.implementation());

        // ── Step 3: 合约互相授权 ──
        // 3a. 设置 NFT 的市场合约地址
        ComicNFT(comicNFT).setMarketplaceContract(marketplace);
        console.log("ComicNFT -> Marketplace: Authorized.");

        // 3b. 设置 Splitter 的市场合约地址
        RoyaltySplitter(payable(splitter)).setMarketplaceContract(marketplace);
        console.log("RoyaltySplitter -> Marketplace: Authorized.");

        vm.stopBroadcast();

        console.log(unicode"=== 部署完成 ===");
        console.log(unicode"请将以上地址保存到配置文件，并更新前端 ABI。");

        // 输出部署摘要（可重定向到文件）
        _writeDeploymentSummary(
            comicNFT, splitter, marketplace, bountyBoard, bridge
        );
    }

    function _writeDeploymentSummary(
        address comicNFT,
        address splitter,
        address marketplace,
        address bountyBoard,
        address bridge
    ) internal view {
        console.log(unicode"\n========== 部署摘要 ==========");
        console.log("Network:         ABR Chain");
        console.log("ComicNFT:       ", comicNFT);
        console.log("RoyaltySplitter:", splitter);
        console.log("Marketplace:    ", marketplace);
        console.log("BountyBoard:    ", bountyBoard);
        console.log("Bridge:         ", bridge);
        console.log("================================");
    }
}
