// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ComicNFT }          from "../src/core/ComicNFT.sol";
import { Marketplace }       from "../src/core/Marketplace.sol";
import { RoyaltySplitter }   from "../src/core/RoyaltySplitter.sol";
import { BountyBoard }       from "../src/bounty/BountyBoard.sol";
import { CrossChainBridge }  from "../src/crosschain/CrossChainBridge.sol";
import { ComicNFTProxy }     from "../src/proxy/ComicNFTProxy.sol";

/// @title Upgrade
/// @notice 升级指定合约的逻辑实现（不改变代理地址，不丢失数据）
/// @dev
///   升级前必须确认：
///   1. 新逻辑合约与旧合约存储布局兼容（新增字段只能追加到末尾）
///   2. 新逻辑合约已通过测试和审计
///   3. 对于 CrossChainBridge，升级前先 pause() 等在途消息处理完毕
///
///   运行示例（升级 ComicNFT）：
///   forge script script/Upgrade.s.sol:Upgrade \
///     --sig "upgradeComicNFT()" \
///     --rpc-url $ABR_RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast
contract Upgrade is Script {

    address OWNER       = vm.envAddress("OWNER_ADDRESS");
    address COMIC_NFT   = vm.envAddress("COMIC_NFT_PROXY");
    address MARKETPLACE = vm.envAddress("MARKETPLACE_PROXY");
    address SPLITTER    = vm.envAddress("SPLITTER_PROXY");
    address BOUNTY      = vm.envAddress("BOUNTY_PROXY");
    address BRIDGE      = vm.envAddress("BRIDGE_PROXY");

    // ── 升级 ComicNFT ────────────────────────────────────────────────

    function upgradeComicNFT() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 1. 部署新逻辑合约
        ComicNFT newImpl = new ComicNFT();
        console.log("New ComicNFT impl: ", address(newImpl));

        // 2. 通过代理调用 upgradeToAndCall（UUPS 模式）
        //    upgradeToAndCall(newImpl, "") 仅升级，不调用迁移函数
        //    如果需要迁移数据，将迁移逻辑编码到第二个参数
        UUPSUpgradeable(COMIC_NFT).upgradeToAndCall(address(newImpl), "");

        console.log("ComicNFT upgraded at proxy: ", COMIC_NFT);
        console.log("New impl address:           ", ComicNFTProxy(payable(COMIC_NFT)).implementation());

        vm.stopBroadcast();
    }

    // ── 升级 Marketplace ─────────────────────────────────────────────

    function upgradeMarketplace() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Marketplace newImpl = new Marketplace();
        console.log("New Marketplace impl: ", address(newImpl));

        UUPSUpgradeable(MARKETPLACE).upgradeToAndCall(address(newImpl), "");
        console.log("Marketplace upgraded at proxy: ", MARKETPLACE);

        vm.stopBroadcast();
    }

    // ── 升级 RoyaltySplitter ─────────────────────────────────────────

    function upgradeRoyaltySplitter() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        RoyaltySplitter newImpl = new RoyaltySplitter();
        UUPSUpgradeable(SPLITTER).upgradeToAndCall(address(newImpl), "");
        console.log("RoyaltySplitter upgraded at proxy: ", SPLITTER);

        vm.stopBroadcast();
    }

    // ── 升级 BountyBoard ─────────────────────────────────────────────

    function upgradeBountyBoard() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        BountyBoard newImpl = new BountyBoard();
        UUPSUpgradeable(BOUNTY).upgradeToAndCall(address(newImpl), "");
        console.log("BountyBoard upgraded at proxy: ", BOUNTY);

        vm.stopBroadcast();
    }

    // ── 升级 CrossChainBridge（需先暂停）────────────────────────────

    function upgradeBridge() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 安全检查：升级跨链桥前确保已暂停
        // 若未暂停，此处会 revert，强制操作者手动确认
        (bool ok, bytes memory data) = BRIDGE.staticcall(
            abi.encodeWithSignature("paused()")
        );
        require(ok && abi.decode(data, (bool)), "Bridge must be paused before upgrade");

        CrossChainBridge newImpl = new CrossChainBridge();
        UUPSUpgradeable(BRIDGE).upgradeToAndCall(address(newImpl), "");
        console.log("CrossChainBridge upgraded at proxy: ", BRIDGE);

        vm.stopBroadcast();
    }
}
