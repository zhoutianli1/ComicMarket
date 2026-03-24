// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title ComicNFTProxy
/// @notice 漫画 NFT 的 ERC1967 代理合约
/// @dev
///   - 用户和前端始终与此地址交互，地址永不改变
///   - 逻辑合约（ComicNFT.sol）可通过 upgradeTo() 升级到 V2/V3
///   - 所有状态（tokenId、版税配置、IP家族）存储在本代理合约的存储槽中
///   - 升级时数据不丢失，只替换逻辑
///
///   存储布局（ERC1967 标准插槽）：
///   - 0x360894...（逻辑合约地址）
///   - 0xb53127...（admin 地址）
///   - ComicNFT 自身存储从 slot 0 开始，由 OpenZeppelin 存储布局保证
///
///   升级流程：
///   1. 部署新逻辑合约 ComicNFTV2
///   2. owner 调用 ComicNFTProxy.upgradeToAndCall(newImpl, data)
///   3. 所有调用自动路由到新逻辑
contract ComicNFTProxy is ERC1967Proxy {

    /// @param logic      初始逻辑合约地址（ComicNFT.sol 部署地址）
    /// @param initData   初始化调用数据，通常为 ComicNFT.initialize(owner) 的 ABI 编码
    constructor(address logic, bytes memory initData)
        ERC1967Proxy(logic, initData)
    {}

    /// @notice 返回当前逻辑合约地址（便于前端和监控工具查询）
    function implementation() external view returns (address) {
        return _implementation();
    }

    receive() external payable {}
}
