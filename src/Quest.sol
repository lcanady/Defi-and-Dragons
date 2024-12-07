// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GameToken.sol";
import "./Equipment.sol";
import "./Character.sol";

contract Quest is Ownable {
    GameToken public gameToken;
    Equipment public equipment;
    Character public character;

    // Quest structure
    struct QuestData {
        string name;
        uint256 requiredLevel;
        uint256 rewardGold;
        uint256[] rewardEquipmentIds;
        uint256[] rewardEquipmentAmounts;
        uint256 cooldownPeriod;
        bool isActive;
    }

    // Mapping from quest ID to quest data
    mapping(uint256 => QuestData) public quests;
    
    // Mapping from character ID to quest completion timestamps
    mapping(uint256 => mapping(uint256 => uint256)) public lastQuestCompletion;
    
    // Counter for creating new quests
    uint256 private _nextQuestId = 1;

    // Events
    event QuestCreated(uint256 indexed questId, string name, uint256 requiredLevel);
    event QuestCompleted(uint256 indexed questId, uint256 indexed characterId, address indexed player);
    event QuestStatusUpdated(uint256 indexed questId, bool isActive);

    constructor(
        address _gameToken,
        address _equipment,
        address _character
    ) Ownable(msg.sender) {
        gameToken = GameToken(_gameToken);
        equipment = Equipment(_equipment);
        character = Character(_character);
    }

    /**
     * @dev Create a new quest
     * @param name Quest name
     * @param requiredLevel Required character level
     * @param rewardGold Gold reward amount
     * @param rewardEquipmentIds Array of equipment IDs for rewards
     * @param rewardEquipmentAmounts Array of equipment amounts for rewards
     * @param cooldownPeriod Time required between completions
     */
    function createQuest(
        string memory name,
        uint256 requiredLevel,
        uint256 rewardGold,
        uint256[] memory rewardEquipmentIds,
        uint256[] memory rewardEquipmentAmounts,
        uint256 cooldownPeriod
    ) public onlyOwner returns (uint256) {
        require(rewardEquipmentIds.length == rewardEquipmentAmounts.length, "Reward arrays must match");
        
        uint256 questId = _nextQuestId++;
        
        quests[questId] = QuestData({
            name: name,
            requiredLevel: requiredLevel,
            rewardGold: rewardGold,
            rewardEquipmentIds: rewardEquipmentIds,
            rewardEquipmentAmounts: rewardEquipmentAmounts,
            cooldownPeriod: cooldownPeriod,
            isActive: true
        });

        emit QuestCreated(questId, name, requiredLevel);
        return questId;
    }

    /**
     * @dev Complete a quest with a character
     * @param questId Quest ID
     * @param characterId Character ID
     */
    function completeQuest(uint256 questId, uint256 characterId) public {
        QuestData memory quest = quests[questId];
        require(quest.isActive, "Quest is not active");
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");

        // Get character stats
        (,Character.Stats memory stats,) = character.getCharacter(characterId);
        require(stats.level >= quest.requiredLevel, "Character level too low");

        // Check cooldown
        require(
            block.timestamp >= lastQuestCompletion[characterId][questId] + quest.cooldownPeriod,
            "Quest on cooldown"
        );

        // Update completion timestamp
        lastQuestCompletion[characterId][questId] = block.timestamp;

        // Distribute rewards
        if (quest.rewardGold > 0) {
            gameToken.mintQuestReward(msg.sender, quest.rewardGold);
        }

        if (quest.rewardEquipmentIds.length > 0) {
            equipment.mintBatch(
                msg.sender,
                quest.rewardEquipmentIds,
                quest.rewardEquipmentAmounts,
                ""
            );
        }

        emit QuestCompleted(questId, characterId, msg.sender);
    }

    /**
     * @dev Set quest active status
     * @param questId Quest ID
     * @param isActive New active status
     */
    function setQuestStatus(uint256 questId, bool isActive) public onlyOwner {
        require(questId < _nextQuestId, "Quest does not exist");
        quests[questId].isActive = isActive;
        emit QuestStatusUpdated(questId, isActive);
    }

    /**
     * @dev Get quest data
     * @param questId Quest ID
     */
    function getQuest(uint256 questId) public view returns (QuestData memory) {
        require(questId < _nextQuestId, "Quest does not exist");
        return quests[questId];
    }

    /**
     * @dev Check if a character can complete a quest
     * @param questId Quest ID
     * @param characterId Character ID
     */
    function canCompleteQuest(uint256 questId, uint256 characterId) public view returns (bool) {
        QuestData memory quest = quests[questId];
        if (!quest.isActive) return false;

        (,Character.Stats memory stats,) = character.getCharacter(characterId);
        if (stats.level < quest.requiredLevel) return false;

        if (block.timestamp < lastQuestCompletion[characterId][questId] + quest.cooldownPeriod) {
            return false;
        }

        return true;
    }
} 