// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Errors.sol";
import "./ProvableRandom.sol";
import "forge-std/console.sol";

contract ItemDrop is Ownable {
    IEquipment public equipment;
    ProvableRandom public immutable provableRandom;

    // Packed struct - saves gas by using smaller uint types
    struct DropRequest {
        address player;
        uint32 dropRateBonus; // Reduced from uint256 since it's a percentage/multiplier
        bool fulfilled;
    }

    // Constants
    uint8 private constant MAX_ITEMS = 5;
    uint8 private constant MIN_DROP_AMOUNT = 1;

    // State variables
    mapping(uint256 => DropRequest) public dropRequests;
    uint32 private requestCounter; // Reduced from uint256 since we don't need that many requests

    event RandomWordsRequested(uint256 indexed requestId, address indexed player);
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint8 amount);

    constructor(address _provableRandom) Ownable() {
        provableRandom = ProvableRandom(_provableRandom);
        _transferOwnership(msg.sender);
    }

    function initialize(address _equipment) external onlyOwner {
        if (address(equipment) != address(0)) revert AlreadyInitialized();
        equipment = IEquipment(_equipment);
    }

    function requestRandomDrop(address player, uint32 dropRateBonus) external returns (uint256) {
        // Increment counter and create request ID
        uint256 requestId;
        unchecked {
            requestCounter++;
            requestId = requestCounter;
        }

        // Store request
        dropRequests[requestId] = DropRequest({ player: player, dropRateBonus: dropRateBonus, fulfilled: false });

        emit RandomWordsRequested(requestId, player);

        // Get the current seed and nonce for this player
        bytes32 context = bytes32(uint256(uint160(address(this))));
        bytes32 currentSeed = provableRandom.getCurrentSeed(player, context);
        uint256 currentNonce = provableRandom.getCurrentNonce(player, context);

        // If no seed exists or nonce is 0, initialize a new seed
        if (currentSeed == 0 || currentNonce == 0) {
            provableRandom.resetSeed(player, context);
            provableRandom.initializeSeed(player, context);
        }

        // Generate random numbers for item drop
        uint256[] memory randomWords = provableRandom.generateNumbers(player, context, 1);
        _fulfillRandomDrop(requestId, randomWords);

        return requestId;
    }

    function _fulfillRandomDrop(uint256 requestId, uint256[] memory randomWords) internal {
        // Load request into memory to save gas on multiple storage reads
        DropRequest storage request = dropRequests[requestId];

        if (request.fulfilled) revert RequestAlreadyFulfilled();
        if (address(equipment) == address(0)) revert NotInitialized();

        // Mark as fulfilled first to prevent reentrancy
        request.fulfilled = true;

        // Emit fulfillment event
        emit RandomWordsFulfilled(requestId, randomWords);

        // Process drops using the random words
        uint256 len = randomWords.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                uint256 rand = randomWords[i];

                // For testing, we always drop an item
                // Using unchecked since we know MAX_ITEMS is small and this can't overflow
                uint256 itemId = (rand % MAX_ITEMS) + 1; // Items 1-5

                // Mint the item to the player
                equipment.mint(request.player, itemId, MIN_DROP_AMOUNT, "");

                // Emit the drop event
                emit ItemDropped(request.player, itemId, MIN_DROP_AMOUNT);
            }
        }
    }
}
