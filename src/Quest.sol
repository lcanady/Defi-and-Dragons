// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";

contract Quest is Ownable {
    ICharacter public immutable character;
    IGameToken public gameToken;

    struct QuestTemplate {
        uint8 requiredLevel;
        uint8 requiredStrength;
        uint8 requiredAgility;
        uint8 requiredMagic;
        uint256 rewardAmount;
        uint256 cooldown;
    }

    mapping(uint256 => QuestTemplate) public questTemplates;
    mapping(uint256 => mapping(uint256 => uint256)) public lastQuestCompletionTime;
    mapping(uint256 => bool) public activeQuests;

    event QuestStarted(uint256 indexed characterId, uint256 indexed questId);
    event QuestCompleted(uint256 indexed characterId, uint256 indexed questId, uint256 reward);

    constructor(address characterContract) Ownable(msg.sender) {
        character = ICharacter(characterContract);
    }

    function initialize(address _gameToken) external onlyOwner {
        require(address(gameToken) == address(0), "Already initialized");
        gameToken = IGameToken(_gameToken);
    }

    modifier onlyCharacterOwner(uint256 characterId) {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        _;
    }

    function createQuest(
        uint8 requiredLevel,
        uint8 requiredStrength,
        uint8 requiredAgility,
        uint8 requiredMagic,
        uint256 rewardAmount,
        uint256 cooldown
    ) external onlyOwner returns (uint256 questId) {
        questId = uint256(
            keccak256(
                abi.encodePacked(
                    requiredLevel,
                    requiredStrength,
                    requiredAgility,
                    requiredMagic,
                    rewardAmount,
                    cooldown,
                    block.timestamp
                )
            )
        );

        questTemplates[questId] = QuestTemplate({
            requiredLevel: requiredLevel,
            requiredStrength: requiredStrength,
            requiredAgility: requiredAgility,
            requiredMagic: requiredMagic,
            rewardAmount: rewardAmount,
            cooldown: cooldown
        });
    }

    function startQuest(uint256 characterId, uint256 questId) external onlyCharacterOwner(characterId) {
        require(!activeQuests[questId], "Quest already active");
        require(questTemplates[questId].requiredLevel > 0, "Quest does not exist");

        uint256 lastCompletion = lastQuestCompletionTime[characterId][questId];
        if (lastCompletion > 0) {
            require(block.timestamp >= lastCompletion + questTemplates[questId].cooldown, "Quest on cooldown");
        }

        (Types.Stats memory stats,,) = character.getCharacter(characterId);
        require(stats.strength >= questTemplates[questId].requiredStrength, "Insufficient strength");
        require(stats.agility >= questTemplates[questId].requiredAgility, "Insufficient agility");
        require(stats.magic >= questTemplates[questId].requiredMagic, "Insufficient magic");

        activeQuests[questId] = true;
        emit QuestStarted(characterId, questId);
    }

    function completeQuest(uint256 characterId, uint256 questId) external onlyCharacterOwner(characterId) {
        require(activeQuests[questId], "Quest not active");

        activeQuests[questId] = false;
        lastQuestCompletionTime[characterId][questId] = block.timestamp;

        uint256 reward = questTemplates[questId].rewardAmount;
        gameToken.mint(msg.sender, reward);

        emit QuestCompleted(characterId, questId, reward);
    }
}
