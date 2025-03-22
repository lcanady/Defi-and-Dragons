// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./Quest.sol";

/// @title ProtocolQuest
/// @notice Manages quests that reward users for interacting with various protocols
contract ProtocolQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    Quest public immutable questContract;

    struct ProtocolQuestTemplate {
        address protocol;           // Protocol contract address
        uint256 minInteractions;   // Minimum number of interactions required
        uint256 minVolume;         // Minimum volume required (if applicable)
        uint256 rewardAmount;      // Base reward amount
        uint256 bonusRewardCap;    // Maximum bonus reward
        uint256 duration;          // Time allowed to complete the quest
        bool active;               // Whether the quest is currently active
    }

    struct UserQuestProgress {
        uint256 startTime;
        uint256 interactionCount;
        uint256 volumeTraded;
        bool completed;
    }

    // Quest template ID => Quest template
    mapping(uint256 => ProtocolQuestTemplate) public questTemplates;
    
    // Quest template ID => Character ID => User progress
    mapping(uint256 => mapping(uint256 => UserQuestProgress)) public userProgress;
    
    // Protocol => Whether it's approved
    mapping(address => bool) public approvedProtocols;

    // Protocol => Character ID => Last interaction timestamp
    mapping(address => mapping(uint256 => uint256)) public lastInteraction;

    event ProtocolQuestCreated(uint256 indexed questId, address protocol, uint256 rewardAmount);
    event ProtocolQuestStarted(uint256 indexed questId, uint256 indexed characterId);
    event ProtocolQuestCompleted(uint256 indexed questId, uint256 indexed characterId, uint256 reward);
    event ProtocolInteractionRecorded(uint256 indexed questId, uint256 indexed characterId, uint256 volume);
    event ProtocolApprovalUpdated(address indexed protocol, bool approved);

    constructor(
        address _character,
        address _gameToken,
        address _questContract
    ) Ownable(msg.sender) {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        questContract = Quest(_questContract);
    }

    /// @notice Set approval status for a protocol
    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
        emit ProtocolApprovalUpdated(protocol, approved);
    }

    /// @notice Create a new protocol quest template
    function createProtocolQuest(
        address protocol,
        uint256 minInteractions,
        uint256 minVolume,
        uint256 rewardAmount,
        uint256 bonusRewardCap,
        uint256 duration
    ) external onlyOwner returns (uint256) {
        require(approvedProtocols[protocol], "Protocol not approved");
        require(minInteractions > 0, "Min interactions must be > 0");
        require(rewardAmount > 0, "Reward must be > 0");
        require(duration > 0, "Duration must be > 0");

        uint256 questId = uint256(
            keccak256(
                abi.encodePacked(
                    protocol,
                    minInteractions,
                    minVolume,
                    rewardAmount,
                    bonusRewardCap,
                    duration,
                    block.timestamp
                )
            )
        );

        questTemplates[questId] = ProtocolQuestTemplate({
            protocol: protocol,
            minInteractions: minInteractions,
            minVolume: minVolume,
            rewardAmount: rewardAmount,
            bonusRewardCap: bonusRewardCap,
            duration: duration,
            active: true
        });

        emit ProtocolQuestCreated(questId, protocol, rewardAmount);
        return questId;
    }

    /// @notice Start a protocol quest for a character
    function startQuest(uint256 characterId, uint256 questId) external nonReentrant {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        require(questTemplates[questId].active, "Quest not active");
        require(!userProgress[questId][characterId].completed, "Quest already completed");
        require(userProgress[questId][characterId].startTime == 0, "Quest already started");

        userProgress[questId][characterId] = UserQuestProgress({
            startTime: block.timestamp,
            interactionCount: 0,
            volumeTraded: 0,
            completed: false
        });

        emit ProtocolQuestStarted(questId, characterId);
    }

    /// @notice Record a protocol interaction for a quest
    function recordInteraction(
        uint256 characterId,
        uint256 questId,
        uint256 volume
    ) external nonReentrant {
        ProtocolQuestTemplate storage quest = questTemplates[questId];
        require(msg.sender == quest.protocol, "Only protocol can record");
        require(quest.active, "Quest not active");

        UserQuestProgress storage progress = userProgress[questId][characterId];
        require(progress.startTime > 0, "Quest not started");
        require(block.timestamp <= progress.startTime + quest.duration, "Quest expired");

        // Update progress
        progress.interactionCount++;
        progress.volumeTraded += volume;

        // Record last interaction time
        lastInteraction[quest.protocol][characterId] = block.timestamp;

        emit ProtocolInteractionRecorded(questId, characterId, volume);

        // Auto-complete if requirements are met
        if (canCompleteQuest(characterId, questId)) {
            completeQuest(characterId, questId);
        }
    }

    /// @notice Check if a quest can be completed
    function canCompleteQuest(uint256 characterId, uint256 questId) public view returns (bool) {
        ProtocolQuestTemplate storage quest = questTemplates[questId];
        UserQuestProgress storage progress = userProgress[questId][characterId];

        if (!quest.active || progress.completed || progress.startTime == 0) {
            return false;
        }

        return progress.interactionCount >= quest.minInteractions &&
               progress.volumeTraded >= quest.minVolume &&
               block.timestamp <= progress.startTime + quest.duration;
    }

    /// @notice Complete a protocol quest
    function completeQuest(uint256 characterId, uint256 questId) public nonReentrant {
        require(canCompleteQuest(characterId, questId), "Cannot complete quest");
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");

        ProtocolQuestTemplate storage quest = questTemplates[questId];
        UserQuestProgress storage progress = userProgress[questId][characterId];

        // Calculate bonus reward based on excess volume
        uint256 bonusReward = 0;
        if (progress.volumeTraded > quest.minVolume && quest.bonusRewardCap > 0) {
            uint256 excessVolume = progress.volumeTraded - quest.minVolume;
            bonusReward = (excessVolume * quest.bonusRewardCap) / quest.minVolume;
            bonusReward = bonusReward.min(quest.bonusRewardCap);
        }

        // Mark as completed and distribute rewards
        progress.completed = true;
        uint256 totalReward = quest.rewardAmount + bonusReward;
        gameToken.mint(msg.sender, totalReward);

        emit ProtocolQuestCompleted(questId, characterId, totalReward);
    }

    /// @notice Get user's quest progress
    function getQuestProgress(uint256 characterId, uint256 questId)
        external
        view
        returns (
            uint256 startTime,
            uint256 interactionCount,
            uint256 volumeTraded,
            bool completed,
            uint256 timeRemaining
        )
    {
        UserQuestProgress storage progress = userProgress[questId][characterId];
        ProtocolQuestTemplate storage quest = questTemplates[questId];

        timeRemaining = progress.startTime > 0 && !progress.completed
            ? Math.max(0, (progress.startTime + quest.duration) - block.timestamp)
            : 0;

        return (
            progress.startTime,
            progress.interactionCount,
            progress.volumeTraded,
            progress.completed,
            timeRemaining
        );
    }
}