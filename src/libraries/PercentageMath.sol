// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PercentageMath：一个用于处理基点（bps）计算的 Solidity 库
/// @notice Basis points（万分比）安全计算工具
/// @dev 1 bps = 0.01%，10000 bps = 100%
library PercentageMath {

    uint16 internal constant BPS_DENOMINATOR  = 10_000;
    uint16 internal constant PLATFORM_FEE_BPS = 250;    // 2.5% 平台费
    uint16 internal constant MAX_SECONDARY_BPS = 1_000; // 10% 二级市场版税上限
    uint16 internal constant DEFAULT_DERIVATIVE_BPS = 500; // 5% 衍生品原作分成默认值

    /// @notice 计算 amount 的 bps 百分比
    /// @dev 使用先乘后除，避免精度损失；amount 上限由调用方保证不溢出
    function percentOf(uint256 amount, uint16 bps) internal pure returns (uint256) {
        return (amount * bps) / BPS_DENOMINATOR;
    }

    /// @notice 验证所有分成之和不超过 100%
    function validateBpsSum(uint16[] memory bpsArray) internal pure returns (bool) {
        uint256 total = 0;
        for (uint256 i; i < bpsArray.length; ++i) {
            total += bpsArray[i];
        }
        return total <= BPS_DENOMINATOR;
    }

    /// @notice 计算一笔交易中各方实际获得金额，这是版税计算的核心
    /// @param saleAmount      成交总额（wei）
    /// @param creatorBps      创作者版税比例
    /// @param derivativeBps   二创者版税比例（非二创传 0）
    /// @return creatorShare      创作者获得
    /// @return derivativeShare   二创者获得
    /// @return platformShare     平台获得
    /// @return sellerShare       卖家获得（剩余）
    function splitProceeds(
        uint256 saleAmount,
        uint16  creatorBps,
        uint16  derivativeBps
    ) internal pure returns (
        uint256 creatorShare,
        uint256 derivativeShare,
        uint256 platformShare,
        uint256 sellerShare
    ) {
        platformShare   = percentOf(saleAmount, PLATFORM_FEE_BPS);//平台费
        creatorShare    = percentOf(saleAmount, creatorBps);//创作者版税
        derivativeShare = percentOf(saleAmount, derivativeBps);//二创者版税

        uint256 totalDeducted = platformShare + creatorShare + derivativeShare;
        // 剩余金额给卖家，防止因 basis points 舍入导致下溢
        sellerShare = saleAmount > totalDeducted ? saleAmount - totalDeducted : 0;
    }
}
