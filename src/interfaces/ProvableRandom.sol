// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ProvableRandom {
    /// @notice Initialize the seed for an address
    /// @param seed The initial seed value
    function initializeSeed(bytes32 seed) external;

    /// @notice Generate multiple random numbers
    /// @param count The number of random numbers to generate
    /// @return An array of random numbers
    function generateNumbers(uint256 count) external view returns (uint256[] memory);

    /// @notice Check if a random number is available for an address
    /// @param addr The address to check
    /// @return Whether a random number is available
    function isRandomNumberAvailable(address addr) external view returns (bool);
}
