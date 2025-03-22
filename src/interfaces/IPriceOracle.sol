// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IPriceOracle
/// @notice Interface for price oracle used by strategy quests
interface IPriceOracle {
    /// @notice Get the current price of a token in USD (with 18 decimals)
    /// @param token The token address to get the price for
    /// @return The current price of the token
    function getPrice(address token) external view returns (uint256);

    /// @notice Get the timestamp of the last price update
    /// @param token The token address to check
    /// @return The timestamp of the last price update
    function getLastUpdate(address token) external view returns (uint256);
} 