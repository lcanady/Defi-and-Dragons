// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";
import "./ProvableRandom.sol";
import "forge-std/console.sol";

contract ItemDrop is Ownable, ProvableRandom {
    IEquipment public equipment;

    struct DropRequest {
        address player;
        uint256 dropRateBonus;
        bool fulfilled;
    }

    mapping(uint256 => DropRequest) public dropRequests;
    uint256 private requestCounter;

    event RandomWordsRequested(uint256 indexed requestId, address indexed player);
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint256 amount);

    constructor() Ownable(msg.sender) {
        // Seed initialization moved to initialize function
    }

    function initialize(address _equipment) external onlyOwner {
        require(address(equipment) == address(0), "Already initialized");
        equipment = IEquipment(_equipment);
    }

    function requestRandomDrop(address player, uint256 dropRateBonus) external returns (uint256) {
        requestCounter++;
        uint256 requestId = requestCounter;

        dropRequests[requestId] = DropRequest({
            player: player,
            dropRateBonus: dropRateBonus,
            fulfilled: false
        });

        emit RandomWordsRequested(requestId, player);

        // Initialize seed for player if not already initialized
        if (_getCurrentSeed(player) == bytes32(0)) {
            // Use a deterministic seed for testing
            bytes32 seed = bytes32(uint256(uint160(player)));
            seeds[player] = seed;
        }

        // Generate random numbers immediately using the player's address
        uint256[] memory randomWords = generateNumbersForAddress(player, 1);
        fulfillRandomDrop(requestId, randomWords);

        return requestId;
    }

    function fulfillRandomDrop(uint256 requestId, uint256[] memory randomWords) internal {
        DropRequest storage request = dropRequests[requestId];
        require(!request.fulfilled, "Request already fulfilled");

        // Add debug logs
        console.log("Fulfilling request:", requestId);
        console.log("Player:", request.player);
        console.log("Drop rate bonus:", request.dropRateBonus);
        console.log("Equipment contract:", address(equipment));

        // Mark as fulfilled first to prevent reentrancy
        request.fulfilled = true;

        // Emit fulfillment event
        emit RandomWordsFulfilled(requestId, randomWords);

        // Process drops using the random words
        require(address(equipment) != address(0), "Equipment contract not initialized");
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 rand = randomWords[i];

            // For testing, we always drop an item
            uint256 itemId = (rand % 5) + 1; // Items 1-5
            uint256 amount = 1;

            // Add debug logs
            console.log("Minting item:", itemId);
            console.log("Amount:", amount);
            console.log("To player:", request.player);

            // Mint the item to the player
            equipment.mint(request.player, itemId, amount, "");

            // Emit the drop event
            emit ItemDropped(request.player, itemId, amount);
        }
    }
}
