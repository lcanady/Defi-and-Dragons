// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Character.sol";
import "./Equipment.sol";

contract ItemDrop is Ownable {
    Character public character;
    Equipment public equipment;

    struct DropTable {
        uint256[] itemIds;
        uint256[] weights; // In basis points (100 = 1%)
        uint256 minLevel;
    }

    // Mapping from drop table ID to drop table
    mapping(uint256 => DropTable) public dropTables;
    uint256 public nextDropTableId = 1;

    event DropTableCreated(uint256 indexed dropTableId);
    event ItemDropped(uint256 indexed characterId, uint256 indexed itemId, uint256 amount);

    constructor(address characterContract, address equipmentContract) Ownable(msg.sender) {
        character = Character(characterContract);
        equipment = Equipment(equipmentContract);
    }

    function createDropTable(uint256[] memory itemIds, uint256[] memory weights, uint256 minLevel)
        public
        onlyOwner
        returns (uint256)
    {
        require(itemIds.length == weights.length, "Arrays must be same length");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        require(totalWeight == 10_000, "Weights must sum to 100%");

        uint256 dropTableId = nextDropTableId++;
        dropTables[dropTableId] = DropTable({ itemIds: itemIds, weights: weights, minLevel: minLevel });

        emit DropTableCreated(dropTableId);
        return dropTableId;
    }

    function rollDrop(uint256 dropTableId, uint256 characterId) public returns (uint256) {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");

        DropTable storage dropTable = dropTables[dropTableId];
        require(dropTable.itemIds.length > 0, "Drop table does not exist");

        // Get character stats
        (Types.Stats memory stats,, Types.CharacterState memory state) = character.getCharacter(characterId);
        uint256 characterLevel = (stats.strength + stats.agility + stats.magic) / 30; // Simple level calculation
        require(characterLevel >= dropTable.minLevel, "Character level too low");

        // Generate random number using block data and character info
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, characterId, state.roundsParticipated)
            )
        );

        // Roll for item
        uint256 roll = randomNumber % 10_000; // Roll between 0-9999
        uint256 currentWeight = 0;

        for (uint256 i = 0; i < dropTable.itemIds.length; i++) {
            currentWeight += dropTable.weights[i];
            if (roll < currentWeight) {
                // Mint the item
                equipment.mint(msg.sender, dropTable.itemIds[i], 1, "");
                emit ItemDropped(characterId, dropTable.itemIds[i], 1);
                return dropTable.itemIds[i];
            }
        }

        revert("No item rolled");
    }

    function getDropTable(uint256 dropTableId)
        public
        view
        returns (uint256[] memory itemIds, uint256[] memory weights, uint256 minLevel)
    {
        DropTable storage dropTable = dropTables[dropTableId];
        require(dropTable.itemIds.length > 0, "Drop table does not exist");
        return (dropTable.itemIds, dropTable.weights, dropTable.minLevel);
    }
}
