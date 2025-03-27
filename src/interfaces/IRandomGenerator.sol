// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IRandomGenerator
/// @notice Interface for random number generation
interface IRandomGenerator {
    /// @notice Request a random number
    /// @param requestId Unique identifier for the request
    /// @return requestId The ID of the request
    function requestRandomNumber(uint256 requestId) external returns (uint256);

    /// @notice Get a random number for a given request
    /// @param requestId The ID of the request
    /// @return The random number
    function getRandomNumber(uint256 requestId) external view returns (uint256);

    /// @notice Check if a random number is available for a given request
    /// @param requestId The ID of the request
    /// @return True if the random number is available
    function isRandomNumberAvailable(uint256 requestId) external view returns (bool);

    /// @notice Generate multiple random numbers
    /// @param count The number of random numbers to generate
    /// @return An array of random numbers
    function generateNumbers(uint256 count) external view returns (uint256[] memory);

    /// @notice Initialize the seed for an address
    /// @param seed The initial seed value
    function initializeSeed(bytes32 seed) external;

    /// @notice Get the current seed for a given address
    /// @param account The address to get the seed for
    /// @return The current seed
    function getCurrentSeed(address account) external view returns (bytes32);
}
