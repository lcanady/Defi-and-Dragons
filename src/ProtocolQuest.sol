// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./interfaces/Errors.sol";
import "./Quest.sol";

/// @title ProtocolQuest
/// @notice Manages protocol-based quests that require specific actions or achievements
/// @dev Optimized for gas efficiency with custom errors and storage packing
contract ProtocolQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    // Custom errors
    error ProtocolNotApproved();
    error InvalidMinInteractions();
    error InvalidReward();
    error InvalidDuration();
    error QuestAlreadyCompleted();
    error QuestAlreadyStarted();
    error OnlyProtocolCanRecord();
    error QuestNotStarted();
    error QuestExpired();
    error CannotCompleteQuest();

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    Quest public immutable questContract;

    struct ProtocolQuestTemplate {
        address protocol; // Protocol contract address
        uint32 minInteractions; // Minimum number of interactions required
        uint128 minVolume; // Minimum volume required (if applicable)
        uint128 rewardAmount; // Base reward amount
        uint128 bonusRewardCap; // Maximum bonus reward
        uint32 duration; // Time allowed to complete the quest (in seconds)
        bool active; // Whether the quest is currently active
    }

    struct UserQuestProgress {
        uint64 startTime; // Timestamp when quest started
        uint32 interactionCount; // Number of interactions completed
        uint128 volumeTraded; // Total volume traded
        bool completed; // Whether quest is completed
    }

    // Quest template ID => Quest template
    mapping(uint256 => ProtocolQuestTemplate) public questTemplates;

    // Quest template ID => Character ID => User progress
    mapping(uint256 => mapping(uint256 => UserQuestProgress)) public userProgress;

    // Protocol => Whether it's approved
    mapping(address => bool) public approvedProtocols;

    // Protocol => Character ID => Last interaction timestamp
    mapping(address => mapping(uint256 => uint64)) public lastInteraction;

    event ProtocolQuestCreated(uint256 indexed questId, address protocol, uint128 rewardAmount);
    event ProtocolQuestStarted(uint256 indexed questId, uint256 indexed characterId);
    event ProtocolQuestCompleted(uint256 indexed questId, uint256 indexed characterId, uint128 reward);
    event ProtocolInteractionRecorded(uint256 indexed questId, uint256 indexed characterId, uint128 volume);
    event ProtocolApprovalUpdated(address indexed protocol, bool approved);

    constructor(address _character, address _gameToken, address _questContract) Ownable() {
        _transferOwnership(msg.sender);
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        questContract = Quest(_questContract);
    }

    /// @notice Set approval status for a protocol
    /// @param protocol Protocol address to approve/disapprove
    /// @param approved New approval status
    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
        emit ProtocolApprovalUpdated(protocol, approved);
    }

    /// @notice Create a new protocol quest template
    /// @param protocol Protocol address for the quest
    /// @param minInteractions Minimum interactions required
    /// @param minVolume Minimum volume required
    /// @param rewardAmount Base reward amount
    /// @param bonusRewardCap Maximum bonus reward
    /// @param duration Quest duration in seconds
    /// @return questId The unique identifier for the quest
    function createProtocolQuest(
        address protocol,
        uint32 minInteractions,
        uint128 minVolume,
        uint128 rewardAmount,
        uint128 bonusRewardCap,
        uint32 duration
    ) external onlyOwner returns (uint256) {
        if (!approvedProtocols[protocol]) revert ProtocolNotApproved();
        if (minInteractions == 0) revert InvalidMinInteractions();
        if (rewardAmount == 0) revert InvalidReward();
        if (duration == 0) revert InvalidDuration();

        uint256 questId = uint256(
            keccak256(
                abi.encodePacked(
                    protocol, minInteractions, minVolume, rewardAmount, bonusRewardCap, duration, block.timestamp
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
    /// @param characterId Character ID to start the quest
    /// @param questId Quest template ID
    function startQuest(uint256 characterId, uint256 questId) external nonReentrant {
        if (character.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();

        ProtocolQuestTemplate storage quest = questTemplates[questId];
        if (!quest.active) revert QuestNotActive();

        UserQuestProgress storage progress = userProgress[questId][characterId];
        if (progress.completed) revert QuestAlreadyCompleted();
        if (progress.startTime != 0) revert QuestAlreadyStarted();

        progress.startTime = uint64(block.timestamp);
        // Other fields are initialized to 0 by default

        emit ProtocolQuestStarted(questId, characterId);
    }

    /// @notice Record a protocol interaction for a quest
    /// @param characterId Character ID making the interaction
    /// @param questId Quest template ID
    /// @param volume Volume of the interaction
    function recordInteraction(uint256 characterId, uint256 questId, uint128 volume) external nonReentrant {
        ProtocolQuestTemplate storage quest = questTemplates[questId];
        if (msg.sender != quest.protocol) revert OnlyProtocolCanRecord();
        if (!quest.active) revert QuestNotActive();

        UserQuestProgress storage progress = userProgress[questId][characterId];
        if (progress.startTime == 0) revert QuestNotStarted();

        uint256 questEndTime;
        unchecked {
            questEndTime = progress.startTime + quest.duration;
        }
        if (block.timestamp > questEndTime) revert QuestExpired();

        // Update progress
        unchecked {
            progress.interactionCount++;
            progress.volumeTraded += volume;
        }

        // Record last interaction time
        lastInteraction[quest.protocol][characterId] = uint64(block.timestamp);

        emit ProtocolInteractionRecorded(questId, characterId, volume);

        // Auto-complete if requirements are met
        if (canCompleteQuest(characterId, questId)) {
            completeQuest(characterId, questId);
        }
    }

    /// @notice Check if a quest can be completed
    /// @param characterId Character ID to check
    /// @param questId Quest template ID
    /// @return Whether the quest can be completed
    function canCompleteQuest(uint256 characterId, uint256 questId) public view returns (bool) {
        ProtocolQuestTemplate storage quest = questTemplates[questId];
        UserQuestProgress storage progress = userProgress[questId][characterId];

        if (!quest.active || progress.completed || progress.startTime == 0) {
            return false;
        }

        uint256 questEndTime;
        unchecked {
            questEndTime = progress.startTime + quest.duration;
        }

        return progress.interactionCount >= quest.minInteractions && progress.volumeTraded >= quest.minVolume
            && block.timestamp <= questEndTime;
    }

    /// @notice Complete a protocol quest
    /// @param characterId Character ID completing the quest
    /// @param questId Quest template ID
    function completeQuest(uint256 characterId, uint256 questId) public nonReentrant {
        if (!canCompleteQuest(characterId, questId)) revert CannotCompleteQuest();
        if (character.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();

        ProtocolQuestTemplate storage quest = questTemplates[questId];
        UserQuestProgress storage progress = userProgress[questId][characterId];

        // Calculate bonus reward based on excess volume
        uint128 bonusReward;
        if (progress.volumeTraded > quest.minVolume && quest.bonusRewardCap > 0) {
            uint256 excessVolume;
            unchecked {
                excessVolume = progress.volumeTraded - quest.minVolume;
            }
            bonusReward = uint128((excessVolume * quest.bonusRewardCap) / quest.minVolume);
            bonusReward = uint128(Math.min(bonusReward, quest.bonusRewardCap));
        }

        // Mark as completed and distribute rewards
        progress.completed = true;
        uint128 totalReward;
        unchecked {
            totalReward = quest.rewardAmount + bonusReward;
        }
        gameToken.mint(msg.sender, totalReward);

        emit ProtocolQuestCompleted(questId, characterId, totalReward);
    }

    /// @notice Get user's quest progress
    /// @param characterId Character ID to check
    /// @param questId Quest template ID
    /// @return startTime Quest start time
    /// @return interactionCount Number of interactions completed
    /// @return volumeTraded Total volume traded
    /// @return completed Whether quest is completed
    /// @return timeRemaining Time remaining to complete quest
    function getQuestProgress(uint256 characterId, uint256 questId)
        external
        view
        returns (uint64 startTime, uint32 interactionCount, uint128 volumeTraded, bool completed, uint32 timeRemaining)
    {
        UserQuestProgress storage progress = userProgress[questId][characterId];
        ProtocolQuestTemplate storage quest = questTemplates[questId];

        if (progress.startTime > 0 && !progress.completed) {
            uint256 endTime;
            unchecked {
                endTime = progress.startTime + quest.duration;
            }
            if (block.timestamp < endTime) {
                timeRemaining = uint32(endTime - block.timestamp);
            }
        }

        return (progress.startTime, progress.interactionCount, progress.volumeTraded, progress.completed, timeRemaining);
    }
}
