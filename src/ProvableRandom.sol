// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ProvableRandom
 * @notice A contract for generating provable random numbers using cryptographic hashing
 * @dev Uses keccak256 hashing with a seed and nonce for deterministic but unpredictable number generation
 */
contract ProvableRandom {
    // Mapping to store seeds for different users/contexts
    mapping(address => bytes32) internal seeds;
    
    // Mapping to track nonces for each user
    mapping(address => uint256) private nonces;
    
    // Event emitted when new numbers are generated
    event NumbersGenerated(
        address indexed user,
        uint256[] numbers,
        bytes32 seed,
        uint256 nonce
    );

    /**
     * @notice Initialize a new seed for the caller
     * @param _seed The initial seed value
     */
    function initializeSeed(bytes32 _seed) public {
        require(seeds[msg.sender] == bytes32(0), "Seed already initialized");
        seeds[msg.sender] = _seed;
    }

    /**
     * @notice Generate a batch of provable random numbers
     * @param count Number of random numbers to generate
     * @return numbers Array of generated random numbers
     */
    function generateNumbers(uint256 count) public returns (uint256[] memory numbers) {
        require(seeds[msg.sender] != bytes32(0), "Seed not initialized");
        
        numbers = new uint256[](count);
        bytes32 currentHash = seeds[msg.sender];
        
        for (uint256 i = 0; i < count; i++) {
            // Increment nonce for each number
            nonces[msg.sender]++;
            
            // Generate new hash using current hash and nonce
            currentHash = keccak256(abi.encodePacked(currentHash, nonces[msg.sender]));
            
            // Convert hash to number and ensure it's within uint256 range
            numbers[i] = uint256(currentHash);
        }
        
        // Update seed for next generation
        seeds[msg.sender] = currentHash;
        
        emit NumbersGenerated(msg.sender, numbers, seeds[msg.sender], nonces[msg.sender]);
    }

    /**
     * @notice Generate a batch of provable random numbers for a specific address
     * @param user Address of the user
     * @param count Number of random numbers to generate
     * @return numbers Array of generated random numbers
     */
    function generateNumbersForAddress(address user, uint256 count) public returns (uint256[] memory numbers) {
        require(seeds[user] != bytes32(0), "Seed not initialized");
        
        numbers = new uint256[](count);
        bytes32 currentHash = seeds[user];
        
        for (uint256 i = 0; i < count; i++) {
            // Increment nonce for each number
            nonces[user]++;
            
            // Generate new hash using current hash and nonce
            currentHash = keccak256(abi.encodePacked(currentHash, nonces[user]));
            
            // Convert hash to number and ensure it's within uint256 range
            numbers[i] = uint256(currentHash);
        }
        
        // Update seed for next generation
        seeds[user] = currentHash;
        
        emit NumbersGenerated(user, numbers, seeds[user], nonces[user]);
    }

    /**
     * @notice Verify that a set of numbers was generated correctly
     * @param numbers Array of numbers to verify
     * @param seed The seed used for generation
     * @param nonce The starting nonce used
     * @return bool Whether the numbers are valid
     */
    function verifyNumbers(
        uint256[] calldata numbers,
        bytes32 seed,
        uint256 nonce
    ) external pure returns (bool) {
        bytes32 currentHash = seed;
        
        for (uint256 i = 0; i < numbers.length; i++) {
            currentHash = keccak256(abi.encodePacked(currentHash, nonce + i));
            if (uint256(currentHash) != numbers[i]) {
                return false;
            }
        }
        
        return true;
    }

    /**
     * @notice Get the current seed for a user (internal version)
     * @param user Address of the user
     * @return The current seed
     */
    function _getCurrentSeed(address user) internal view returns (bytes32) {
        return seeds[user];
    }

    /**
     * @notice Get the current seed for a user
     * @param user Address of the user
     * @return The current seed
     */
    function getCurrentSeed(address user) external view returns (bytes32) {
        return seeds[user];
    }

    /**
     * @notice Get the current nonce for a user
     * @param user Address of the user
     * @return The current nonce
     */
    function getCurrentNonce(address user) external view returns (uint256) {
        return nonces[user];
    }
} 