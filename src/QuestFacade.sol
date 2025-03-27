// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./interfaces/Errors.sol";
import "./SocialQuest.sol";
import "./ProtocolQuest.sol";
import "./CombatQuest.sol";

/// @title QuestFacade
/// @notice Provides a unified interface for managing different types of quests
/// @dev Optimized for gas efficiency with custom errors and storage packing
contract QuestFacade is Ownable, ReentrancyGuard {
    using Math for uint256;

    // Custom errors
    error InvalidQuestType();
    error InvalidQuestId();
    error InvalidCharacterId();
    error InvalidValue();
    error QuestAlreadyCompleted();

    SocialQuest public immutable socialQuest;

    // Quest type enumeration (uint8 by default for enums)
    enum QuestType {
        TEAM,
        REFERRAL
    }

    // Quest status enumeration
    enum QuestStatus {
        INACTIVE,
        ACTIVE,
        COMPLETED
    }

    // Unified quest view structure - optimized packing
    struct QuestView {
        bytes32 questId; // 32 bytes
        string name; // 32+ bytes
        string description; // 32+ bytes
        uint32 duration; // 4 bytes
        uint32 completionTime; // 4 bytes
        uint32 progress; // 4 bytes (0-100)
        QuestType questType; // 1 byte
        QuestStatus status; // 1 byte
        uint128[] rewards; // 32+ bytes (array of reward amounts)
    }

    // Mapping to track quest completion times
    mapping(bytes32 => uint32) public questCompletionTimes;

    // Mapping to track quest progress
    mapping(bytes32 => uint32) public questProgress;

    // Mapping to track player's active quests
    mapping(address => bytes32[]) public playerActiveQuests;

    // Mapping to track player's completed quests
    mapping(address => bytes32[]) public playerCompletedQuests;

    event QuestStarted(bytes32 indexed questId, QuestType indexed questType, address indexed player);
    event QuestProgressed(bytes32 indexed questId, QuestType indexed questType, uint32 progress);
    event QuestCompleted(bytes32 indexed questId, QuestType indexed questType, address indexed player);

    constructor(address _socialQuest) Ownable() {
        _transferOwnership(msg.sender);
        socialQuest = SocialQuest(_socialQuest);
    }

    /// @notice Start a team quest
    /// @param questId The ID of the quest to start
    /// @param memberIds Array of character IDs to form the team
    function startTeamQuest(bytes32 questId, uint256[] calldata memberIds) external {
        if (questId == bytes32(0)) revert InvalidQuestId();
        if (memberIds.length == 0) revert InvalidCharacterId();

        socialQuest.formTeam(questId, memberIds);
        playerActiveQuests[msg.sender].push(questId);
        emit QuestStarted(questId, QuestType.TEAM, msg.sender);
    }

    /// @notice Start a referral quest
    /// @param questId The ID of the quest to start
    /// @param referrerId The character ID of the referrer
    /// @param referreeId The character ID of the new player
    function startReferralQuest(bytes32 questId, uint256 referrerId, uint256 referreeId) external {
        if (questId == bytes32(0)) revert InvalidQuestId();
        if (referrerId == 0 || referreeId == 0) revert InvalidCharacterId();

        socialQuest.registerReferral(questId, referrerId, referreeId);
        playerActiveQuests[msg.sender].push(questId);
        emit QuestStarted(questId, QuestType.REFERRAL, msg.sender);
    }

    /// @notice Record progress for a team quest
    /// @param questId The ID of the quest
    /// @param characterId The character ID making the contribution
    /// @param value The contribution value
    function recordTeamProgress(bytes32 questId, uint256 characterId, uint256 value) external {
        if (questId == bytes32(0)) revert InvalidQuestId();
        if (characterId == 0) revert InvalidCharacterId();
        if (value == 0) revert InvalidValue();

        socialQuest.recordContribution(questId, characterId, uint128(value));

        // Update progress (0-100)
        SocialQuest.TeamQuest memory quest = socialQuest.getTeamQuest(questId);
        uint32 newProgress = uint32((value * 100) / quest.targetValue);
        questProgress[questId] = newProgress;

        emit QuestProgressed(questId, QuestType.TEAM, newProgress);
    }

    /// @notice Complete a referral quest
    /// @param questId The ID of the quest
    /// @param referrerId The character ID of the referrer
    /// @param referreeId The character ID of the referred player
    function completeReferralQuest(bytes32 questId, uint256 referrerId, uint256 referreeId) external {
        if (questId == bytes32(0)) revert InvalidQuestId();
        if (referrerId == 0 || referreeId == 0) revert InvalidCharacterId();

        socialQuest.completeReferral(questId, referrerId, referreeId);

        // Update completion status
        questCompletionTimes[questId] = uint32(block.timestamp);

        // Move quest from active to completed
        bytes32[] storage activeQuests = playerActiveQuests[msg.sender];
        bytes32[] storage completedQuests = playerCompletedQuests[msg.sender];

        // Find and remove from active quests
        uint256 len = activeQuests.length;
        for (uint256 i = 0; i < len;) {
            if (activeQuests[i] == questId) {
                activeQuests[i] = activeQuests[len - 1];
                activeQuests.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        completedQuests.push(questId);
        emit QuestCompleted(questId, QuestType.REFERRAL, msg.sender);
    }

    /// @notice Get quest details
    /// @param questId The ID of the quest
    /// @param questType The type of quest
    /// @return Quest details as a QuestView struct
    function getQuestDetails(bytes32 questId, QuestType questType) external view returns (QuestView memory) {
        QuestView memory questView;
        questView.questId = questId;
        questView.questType = questType;
        questView.progress = questProgress[questId];
        questView.completionTime = questCompletionTimes[questId];

        if (questType == QuestType.TEAM) {
            SocialQuest.TeamQuest memory teamQuest = socialQuest.getTeamQuest(questId);
            questView.name = teamQuest.name;
            questView.description = teamQuest.description;
            questView.duration = teamQuest.duration;
            questView.status = teamQuest.active ? QuestStatus.ACTIVE : QuestStatus.INACTIVE;

            uint128[] memory rewards = new uint128[](2);
            rewards[0] = teamQuest.teamReward;
            rewards[1] = teamQuest.topReward;
            questView.rewards = rewards;
        } else if (questType == QuestType.REFERRAL) {
            SocialQuest.ReferralQuest memory referralQuest = socialQuest.getReferralQuest(questId);
            questView.name = referralQuest.name;
            questView.description = "Refer a new player and help them level up";
            questView.duration = referralQuest.duration;
            questView.status = referralQuest.active ? QuestStatus.ACTIVE : QuestStatus.INACTIVE;

            uint128[] memory rewards = new uint128[](2);
            rewards[0] = referralQuest.referrerReward;
            rewards[1] = referralQuest.referreeReward;
            questView.rewards = rewards;
        } else {
            revert InvalidQuestType();
        }

        // Update status if completed
        if (questView.completionTime > 0) {
            questView.status = QuestStatus.COMPLETED;
        }

        return questView;
    }

    /// @notice Get all active quests for a player
    /// @param player The player's address
    /// @return activeQuests Array of active quest IDs
    function getActiveQuests(address player) external view returns (bytes32[] memory) {
        return playerActiveQuests[player];
    }

    /// @notice Get completed quests for a player
    /// @param player The player's address
    /// @return completedQuests Array of completed quest IDs
    function getCompletedQuests(address player) external view returns (bytes32[] memory) {
        return playerCompletedQuests[player];
    }
}
