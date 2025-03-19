// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAttributeProvider {
    /// @notice Check if the provider is active for a character
    /// @param characterId The ID of the character
    /// @return Whether the provider is active
    function isActive(uint256 characterId) external view returns (bool);

    /// @notice Get the bonus provided by this provider
    /// @param characterId The ID of the character
    /// @return The bonus value in basis points
    function getBonus(uint256 characterId) external view returns (uint256);
}
