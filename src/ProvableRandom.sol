// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Custom errors for gas optimization
error SeedAlreadyInitialized();
error SeedNotInitialized();

/**
 * @title ProvableRandom
 * @notice A contract for generating provable random numbers using cryptographic hashing
 * @dev Uses keccak256 hashing with a seed and nonce for deterministic but unpredictable number generation
 */
contract ProvableRandom {
    // Mapping from user address to their current seed
    mapping(address => mapping(bytes32 => bytes32)) private seeds;
    // Mapping from user address to their current nonce
    mapping(address => mapping(bytes32 => uint32)) private nonces;

    event SeedInitialized(address indexed user, bytes32 indexed context, bytes32 seed);
    event NumbersGenerated(address indexed user, bytes32 indexed context, uint256[] numbers, bytes32 seed, uint32 nonce);

    /**
     * @notice Reset the seed for a user and context
     * @param user Address of the user to reset
     * @param context Address of the context to reset
     */
    function resetSeed(address user, bytes32 context) public virtual {
        delete seeds[user][context];
        delete nonces[user][context];
    }

    /**
     * @notice Initialize the seed for a user and context
     * @param user Address of the user to initialize the seed for
     * @param context Address of the context to initialize the seed for
     */
    function initializeSeed(address user, bytes32 context) public virtual {
        if (seeds[user][context] != bytes32(0)) revert SeedAlreadyInitialized();
        seeds[user][context] = context;
        nonces[user][context] = 0;
        emit SeedInitialized(user, context, context);
    }

    /**
     * @notice Get the current seed for a user and context
     * @param user Address of the user
     * @param context Address of the context
     * @return The current seed
     */
    function getCurrentSeed(address user, bytes32 context) public view virtual returns (bytes32) {
        return seeds[user][context];
    }

    /**
     * @notice Get the current nonce for a user and context
     * @param user Address of the user
     * @param context Address of the context
     * @return The current nonce
     */
    function getCurrentNonce(address user, bytes32 context) public view virtual returns (uint32) {
        return nonces[user][context];
    }

    /**
     * @notice Generate random numbers for a user and context
     * @param user Address of the user to generate numbers for
     * @param context Address of the context to generate numbers for
     * @return numbers Array of generated random numbers
     */
    function generateNumbers(address user, bytes32 context) public virtual returns (uint256[] memory numbers) {
        return generateNumbers(user, context, 1);
    }

    /**
     * @notice Generate multiple random numbers for a user and context
     * @param user Address of the user to generate numbers for
     * @param context Address of the context to generate numbers for
     * @param count Number of random numbers to generate
     * @return numbers Array of generated random numbers
     */
    function generateNumbers(address user, bytes32 context, uint256 count) public virtual returns (uint256[] memory numbers) {
        bytes32 seed = seeds[user][context];
        if (seed == bytes32(0)) revert SeedNotInitialized();

        uint32 nonce = nonces[user][context];
        numbers = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            bytes32 hash = keccak256(abi.encodePacked(seed, nonce + uint32(i)));
            numbers[i] = uint256(hash);
        }

        nonces[user][context] = nonce + uint32(count);
        emit NumbersGenerated(user, context, numbers, seed, nonce);
        return numbers;
    }

    /**
     * @notice Verify that a set of numbers was generated from a given seed and nonce
     * @param numbers Array of numbers to verify
     * @param seed The seed used for generation
     * @param startNonce The starting nonce used
     * @return bool Whether the numbers are valid
     */
    function verifyNumbers(uint256[] memory numbers, bytes32 seed, uint32 startNonce) public pure virtual returns (bool) {
        for (uint256 i = 0; i < numbers.length; i++) {
            bytes32 hash = keccak256(abi.encodePacked(seed, startNonce + uint32(i)));
            if (numbers[i] != uint256(hash)) {
                return false;
            }
        }
        return true;
    }
}
