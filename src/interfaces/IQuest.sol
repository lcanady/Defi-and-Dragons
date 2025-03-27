// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IQuest {
    enum QuestType {
        COMBAT, // Requires combat victories/stats
        SOCIAL, // Requires social interactions
        ACHIEVEMENT, // Requires reaching milestones
        PROTOCOL, // Requires DeFi interactions
        TIME // Requires time-based completion

    }

    struct QuestObjective {
        uint256 targetValue; // The value that needs to be reached
        uint256 currentValue; // Current progress
        bytes32 objectiveType; // What needs to be tracked (kills, trades, etc)
    }

    struct QuestTemplate {
        uint8 requiredLevel;
        uint8 requiredStrength;
        uint8 requiredAgility;
        uint8 requiredMagic;
        uint256 rewardAmount;
        uint256 cooldown;
        bool supportsParty;
        uint256 maxPartySize;
        uint256 partyBonusPercent;
        bool isRaid;
        uint256 maxParties;
        QuestType questType;
        QuestObjective[] objectives;
    }

    function questTemplates(uint256 questId) external view returns (QuestTemplate memory);
    function updateQuestProgress(uint256 questId, bytes32 partyId, bytes32 objectiveType, uint256 progress) external;
    function getPartyParticipatingCharacters(uint256 questId, bytes32 partyId)
        external
        view
        returns (uint256[] memory);
    function LIQUIDITY_PROVIDED() external view returns (bytes32);
}
