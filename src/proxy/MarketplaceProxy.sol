// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title MarketplaceProxy
/// @notice 市场合约的 ERC1967 代理
/// @dev
///   - 所有挂单、购买、拍卖记录存储在此代理合约
///   - 可在不迁移数据的情况下升级市场逻辑（如新增功能、修复 Bug）
///   - 升级后原有 listingId / auctionId 全部保留
contract MarketplaceProxy is ERC1967Proxy {

    constructor(address logic, bytes memory initData)
        ERC1967Proxy(logic, initData)
    {}

    function implementation() external view returns (address) {
        return _implementation();
    }

    receive() external payable {}
}
