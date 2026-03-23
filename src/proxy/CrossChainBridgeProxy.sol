// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title CrossChainBridgeProxy
/// @notice 跨链桥的 ERC1967 代理
/// @dev
///   - bridgeLocks、processedMessages 存储在此代理合约
///   - 跨链进行中时不应升级逻辑（防止在途消息处理异常）
///   - 建议在升级前先 pause()，等所有在途跨链消息处理完毕后再升级
contract CrossChainBridgeProxy is ERC1967Proxy {

    constructor(address logic, bytes memory initData)
        ERC1967Proxy(logic, initData)
    {}

    function implementation() external view returns (address) {
        return _implementation();
    }
}
