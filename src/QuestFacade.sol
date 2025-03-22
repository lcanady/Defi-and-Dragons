// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SocialQuest.sol";
import "./interfaces/Types.sol";

/// @title QuestFacade
/// @notice Provides a unified interface for managing different types of quests
contract QuestFacade is Ownable {
    SocialQuest public immutable socialQuest;

    // Quest type enumeration
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

    // Unified quest view structure
    struct QuestView {
        bytes32 questId;
        QuestType questType;
        string name;
        string description;
        uint256 duration;
        QuestStatus status;
        uint256[] rewards;        // Array of reward amounts (tokens, items, etc)
        uint256 progress;         // Current progress (0-100)
        uint256 completionTime;   // When quest was completed (0 if not completed)
    }

    event QuestStarted(bytes32 indexed questId, QuestType indexed questType, address indexed player);
    event QuestProgressed(bytes32 indexed questId, QuestType indexed questType, uint256 progress);
    event QuestCompleted(bytes32 indexed questId, QuestType indexed questType, address indexed player);

    constructor(address _socialQuest) Ownable(msg.sender) {
        socialQuest = SocialQuest(_socialQuest);
    }

    /// @notice Start a team quest
    /// @param questId The ID of the quest to start
    /// @param memberIds Array of character IDs to form the team
    function startTeamQuest(bytes32 questId, uint256[] calldata memberIds) external {
        socialQuest.formTeam(questId, memberIds);
        emit QuestStarted(questId, QuestType.TEAM, msg.sender);
    }

    /// @notice Start a referral quest
    /// @param questId The ID of the quest to start
    /// @param referrerId The character ID of the referrer
    /// @param referreeId The character ID of the new player
    function startReferralQuest(
        bytes32 questId,
        uint256 referrerId,
        uint256 referreeId
    ) external {
        socialQuest.registerReferral(questId, referrerId, referreeId);
        emit QuestStarted(questId, QuestType.REFERRAL, msg.sender);
    }

    /// @notice Record progress for a team quest
    /// @param questId The ID of the quest
    /// @param characterId The character ID making the contribution
    /// @param value The contribution value
    function recordTeamProgress(
        bytes32 questId,
        uint256 characterId,
        uint256 value
    ) external {
        socialQuest.recordContribution(questId, characterId, value);
        emit QuestProgressed(questId, QuestType.TEAM, value);
    }

    /// @notice Complete a referral quest
    /// @param questId The ID of the quest
    /// @param referrerId The character ID of the referrer
    /// @param referreeId The character ID of the referred player
    function completeReferralQuest(
        bytes32 questId,
        uint256 referrerId,
        uint256 referreeId
    ) external {
        socialQuest.completeReferral(questId, referrerId, referreeId);
        emit QuestCompleted(questId, QuestType.REFERRAL, msg.sender);
    }

    /// @notice Get quest details
    /// @param questId The ID of the quest
    /// @param questType The type of quest
    /// @return QuestView struct containing quest details
    function getQuestDetails(
        bytes32 questId,
        QuestType questType
    ) external view returns (QuestView memory) {
        if (questType == QuestType.TEAM) {
            SocialQuest.TeamQuest memory teamQuest = socialQuest.teamQuests(questId);
            uint256[] memory rewards = new uint256[](2);
            rewards[0] = teamQuest.teamReward;
            rewards[1] = teamQuest.topReward;

            return QuestView({
                questId: questId,
                questType: QuestType.TEAM,
                name: teamQuest.name,
                description: teamQuest.description,
                duration: teamQuest.duration,
                status: teamQuest.active ? QuestStatus.ACTIVE : QuestStatus.INACTIVE,
                rewards: rewards,
                progress: 0, // Would need to calculate based on team progress
                completionTime: 0 // Would need to track in team struct
            });
        } else if (questType == QuestType.REFERRAL) {
            SocialQuest.ReferralQuest memory referralQuest = socialQuest.referralQuests(questId);
            uint256[] memory rewards = new uint256[](2);
            rewards[0] = referralQuest.referrerReward;
            rewards[1] = referralQuest.referreeReward;

            return QuestView({
                questId: questId,
                questType: QuestType.REFERRAL,
                name: referralQuest.name,
                description: "", // Could add description to ReferralQuest struct
                duration: referralQuest.duration,
                status: referralQuest.active ? QuestStatus.ACTIVE : QuestStatus.INACTIVE,
                rewards: rewards,
                progress: 0, // Would need to track referree level progress
                completionTime: 0 // Would need to track completion time
            });
        }

        revert("Invalid quest type");
    }

    /// @notice Get all active quests for a character
    /// @param characterId The character ID to get quests for
    /// @return activeQuests Array of active quest views
    function getActiveQuests(uint256 characterId) external view returns (QuestView[] memory) {
        // Implementation would require tracking active quests per character
        // This is a placeholder that would need to be implemented based on your needs
        QuestView[] memory activeQuests = new QuestView[](0);
        return activeQuests;
    }

    /// @notice Get completed quests for a character
    /// @param characterId The character ID to get quests for
    /// @return completedQuests Array of completed quest views
    function getCompletedQuests(uint256 characterId) external view returns (QuestView[] memory) {
        // Implementation would require tracking completed quests per character
        // This is a placeholder that would need to be implemented based on your needs
        QuestView[] memory completedQuests = new QuestView[](0);
        return completedQuests;
    }
} 