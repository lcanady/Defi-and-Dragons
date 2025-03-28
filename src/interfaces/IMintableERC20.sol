// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMintableERC20
 * @dev Interface for an ERC20 token with a public mint function.
 */
interface IMintableERC20 is IERC20 {
    /**
     * @notice Mints `amount` tokens to `to`.
     * @dev MUST restrict access appropriately (e.g., only owner, only specific contracts).
     */
    function mint(address to, uint256 amount) external;
} 