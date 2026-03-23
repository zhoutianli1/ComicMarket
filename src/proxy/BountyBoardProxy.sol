// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title BountyBoardProxy
/// @notice 悬赏合约的 ERC1967 代理
/// @dev
///   - 所有 BountyTask、申请记录、奖金余额存储在此代理合约
///   - 可升级任务验收逻辑而不影响进行中的任务
contract BountyBoardProxy is ERC1967Proxy {

    constructor(address logic, bytes memory initData)
        ERC1967Proxy(logic, initData)
    {}

    function implementation() external view returns (address) {
        return _implementation();
    }
}
