// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title RoyaltySplitterProxy
/// @notice 版税拆分器的 ERC1967 代理
/// @dev
///   - pendingWithdrawals 余额记录存储在此代理合约
///   - 升级逻辑合约不影响用户待提取余额
contract RoyaltySplitterProxy is ERC1967Proxy {

    constructor(address logic, bytes memory initData)
        ERC1967Proxy(logic, initData)
    {}

    function implementation() external view returns (address) {
        return _implementation();
    }

    receive() external payable {}
}
