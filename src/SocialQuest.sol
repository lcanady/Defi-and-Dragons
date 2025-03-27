// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./interfaces/Errors.sol";
import "./ItemDrop.sol";

/// @title SocialQuest
/// @notice Manages team-based and social quests with collaborative rewards
/// @dev Optimized for gas efficiency with custom errors and storage packing
contract SocialQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    // Custom errors
    error InvalidTeamSize();
    error InvalidTarget();
    error InvalidDuration();
    error AlreadyInTeam();
    error NotInTeam();
    error QuestCompleted();
    error QuestExpired();
    error InvalidLevelRequirement();
    error AlreadyReferred();
    error NotReferred();
    error LevelTooLow();

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    ItemDrop public immutable itemDrop;

    struct TeamQuest {
        string name;
        string description;
        uint32 minTeamSize; // Minimum team members required
        uint32 maxTeamSize; // Maximum team members allowed
        uint128 targetValue; // Target value to achieve (volume, points, etc.)
        uint32 duration; // Time to complete the quest in seconds
        uint128 teamReward; // Base reward to split among team
        uint128 topReward; // Additional reward for top contributor
        uint32 dropRateBonus; // Bonus for item drop rates
        bool active; // Whether quest is active
    }

    struct Team {
        uint256[] memberIds; // Character IDs of team members
        uint64 startTime; // When team started quest
        uint128 totalValue; // Total value contributed
        bool completed; // Whether quest was completed
        mapping(uint256 => uint128) contributions; // Member contributions
    }

    struct ReferralQuest {
        string name;
        uint128 referrerReward; // Reward for referrer
        uint128 referreeReward; // Reward for new player
        uint32 requiredLevel; // Level referree must reach
        uint32 duration; // Time limit for referree to reach level
        bool active; // Whether quest is active
    }

    // Quest ID => Quest details
    mapping(bytes32 => TeamQuest) public teamQuests;

    // Quest ID => Team details
    mapping(bytes32 => Team) public teams;

    // Quest ID => Character ID => Team ID
    mapping(bytes32 => mapping(uint256 => bytes32)) public memberTeams;

    // Referral quest details
    mapping(bytes32 => ReferralQuest) public referralQuests;

    // Referrer => Referree => Quest ID => Progress
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => bool))) public referralProgress;

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    event TeamQuestCreated(bytes32 indexed id, string name, uint128 teamReward);
    event TeamFormed(bytes32 indexed questId, bytes32 indexed teamId, uint256[] members);
    event ContributionRecorded(
        bytes32 indexed questId, bytes32 indexed teamId, uint256 indexed characterId, uint128 amount
    );
    event TeamQuestCompleted(bytes32 indexed questId, bytes32 indexed teamId, uint128 totalReward);
    event ReferralQuestCreated(bytes32 indexed id, string name);
    event ReferralRegistered(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId);
    event ReferralCompleted(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId);

    constructor(address _character, address _gameToken, address _itemDrop) Ownable() {
        _transferOwnership(msg.sender);
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        itemDrop = ItemDrop(_itemDrop);
    }

    /// @notice Create a new team quest
    /// @param name Quest name
    /// @param description Quest description
    /// @param minTeamSize Minimum team size required
    /// @param maxTeamSize Maximum team size allowed
    /// @param targetValue Target value to achieve
    /// @param duration Quest duration in seconds
    /// @param teamReward Base reward for the team
    /// @param topReward Additional reward for top contributor
    /// @param dropRateBonus Bonus for item drop rates
    /// @return questId The unique identifier for the quest
    function createTeamQuest(
        string calldata name,
        string calldata description,
        uint32 minTeamSize,
        uint32 maxTeamSize,
        uint128 targetValue,
        uint32 duration,
        uint128 teamReward,
        uint128 topReward,
        uint32 dropRateBonus
    ) external onlyOwner returns (bytes32) {
        if (minTeamSize == 0 || maxTeamSize < minTeamSize) revert InvalidTeamSize();
        if (targetValue == 0) revert InvalidTarget();
        if (duration == 0) revert InvalidDuration();

        bytes32 id = keccak256(abi.encodePacked(name, block.timestamp));

        teamQuests[id] = TeamQuest({
            name: name,
            description: description,
            minTeamSize: minTeamSize,
            maxTeamSize: maxTeamSize,
            targetValue: targetValue,
            duration: duration,
            teamReward: teamReward,
            topReward: topReward,
            dropRateBonus: dropRateBonus,
            active: true
        });

        emit TeamQuestCreated(id, name, teamReward);
        return id;
    }

    /// @notice Form a team for a quest
    /// @param questId The quest identifier
    /// @param memberIds Array of character IDs to form the team
    function formTeam(bytes32 questId, uint256[] calldata memberIds) external nonReentrant {
        TeamQuest storage quest = teamQuests[questId];
        if (!quest.active) revert QuestNotActive();

        uint256 len = memberIds.length;
        if (len < quest.minTeamSize || len > quest.maxTeamSize) revert InvalidTeamSize();

        // Verify all members and check availability
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (character.ownerOf(memberIds[i]) != msg.sender) revert NotCharacterOwner();
                if (memberTeams[questId][memberIds[i]] != bytes32(0)) revert AlreadyInTeam();
            }
        }

        // Create team
        bytes32 teamId = keccak256(abi.encodePacked(questId, memberIds, block.timestamp));
        Team storage team = teams[teamId];
        team.memberIds = memberIds;
        team.startTime = uint64(block.timestamp);

        // Register team members
        unchecked {
            for (uint256 i; i < len; ++i) {
                memberTeams[questId][memberIds[i]] = teamId;
            }
        }

        emit TeamFormed(questId, teamId, memberIds);
    }

    /// @notice Record contribution for team quest
    /// @param questId The quest identifier
    /// @param characterId The character making the contribution
    /// @param value The contribution value
    function recordContribution(bytes32 questId, uint256 characterId, uint128 value) external {
        if (msg.sender != owner() && !approvedTrackers[msg.sender]) revert NotAuthorized();

        bytes32 teamId = memberTeams[questId][characterId];
        if (teamId == bytes32(0)) revert NotInTeam();

        TeamQuest storage quest = teamQuests[questId];
        Team storage team = teams[teamId];

        if (team.completed) revert QuestCompleted();
        if (block.timestamp > team.startTime + quest.duration) revert QuestExpired();

        // Update contribution
        team.contributions[characterId] += value;
        team.totalValue += value;

        emit ContributionRecorded(questId, teamId, characterId, value);

        // Check for completion
        if (team.totalValue >= quest.targetValue) {
            completeTeamQuest(questId, teamId);
        }
    }

    /// @notice Complete a team quest
    /// @param questId The quest identifier
    /// @param teamId The team identifier
    function completeTeamQuest(bytes32 questId, bytes32 teamId) internal {
        TeamQuest storage quest = teamQuests[questId];
        Team storage team = teams[teamId];

        // Find top contributor
        uint128 topContribution;
        uint256 topContributor;
        uint256[] memory members = team.memberIds;
        uint256 len = members.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                uint256 memberId = members[i];
                uint128 contribution = team.contributions[memberId];
                if (contribution > topContribution) {
                    topContribution = contribution;
                    topContributor = memberId;
                }
            }
        }

        // Calculate individual rewards
        uint128 baseReward = uint128(uint256(quest.teamReward) / len);

        // Distribute rewards
        unchecked {
            for (uint256 i; i < len; ++i) {
                uint256 memberId = members[i];
                uint128 reward = baseReward;
                address playerAddress = character.ownerOf(memberId);

                // Add top contributor bonus
                if (memberId == topContributor) {
                    reward += quest.topReward;
                }

                // Mint game tokens
                gameToken.mint(playerAddress, reward);

                // Request item drops with bonus rate
                if (quest.dropRateBonus > 0) {
                    itemDrop.requestRandomDrop(playerAddress, quest.dropRateBonus);
                }
            }
        }

        team.completed = true;
        emit TeamQuestCompleted(questId, teamId, uint128(quest.teamReward + quest.topReward));
    }

    /// @notice Create a referral quest
    /// @param name Quest name
    /// @param referrerReward Reward for the referrer
    /// @param referreeReward Reward for the referred player
    /// @param requiredLevel Level the referred player must reach
    /// @param duration Time limit for completion
    /// @return questId The unique identifier for the quest
    function createReferralQuest(
        string calldata name,
        uint128 referrerReward,
        uint128 referreeReward,
        uint32 requiredLevel,
        uint32 duration
    ) external onlyOwner returns (bytes32) {
        if (requiredLevel == 0) revert InvalidLevelRequirement();
        if (duration == 0) revert InvalidDuration();

        bytes32 id = keccak256(abi.encodePacked(name, block.timestamp));

        referralQuests[id] = ReferralQuest({
            name: name,
            referrerReward: referrerReward,
            referreeReward: referreeReward,
            requiredLevel: requiredLevel,
            duration: duration,
            active: true
        });

        emit ReferralQuestCreated(id, name);
        return id;
    }

    /// @notice Register a referral
    /// @param questId The quest identifier
    /// @param referrerId The referrer's character ID
    /// @param referreeId The referred player's character ID
    function registerReferral(bytes32 questId, uint256 referrerId, uint256 referreeId) external {
        if (character.ownerOf(referrerId) != msg.sender) revert NotCharacterOwner();
        if (!referralQuests[questId].active) revert QuestNotActive();
        if (referralProgress[referrerId][referreeId][questId]) revert AlreadyReferred();

        referralProgress[referrerId][referreeId][questId] = true;
        emit ReferralRegistered(referrerId, referreeId, questId);
    }

    /// @notice Complete a referral quest
    /// @param questId The quest identifier
    /// @param referrerId The referrer's character ID
    /// @param referreeId The referred player's character ID
    function completeReferral(bytes32 questId, uint256 referrerId, uint256 referreeId) external {
        ReferralQuest storage quest = referralQuests[questId];
        if (!quest.active) revert QuestNotActive();
        if (!referralProgress[referrerId][referreeId][questId]) revert NotReferred();

        // Verify referree level
        (,, Types.CharacterState memory state) = character.getCharacter(referreeId);
        if (state.level < quest.requiredLevel) revert LevelTooLow();

        address referrerAddress = character.ownerOf(referrerId);
        address referreeAddress = character.ownerOf(referreeId);

        // Distribute rewards
        gameToken.mint(referrerAddress, quest.referrerReward);
        gameToken.mint(referreeAddress, quest.referreeReward);

        // Give both players a chance for item drops
        itemDrop.requestRandomDrop(referrerAddress, 100); // Base drop rate bonus for referrer
        itemDrop.requestRandomDrop(referreeAddress, 50); // Smaller bonus for referree

        emit ReferralCompleted(referrerId, referreeId, questId);
    }

    /// @notice Set approval for progress trackers
    /// @param tracker Address to approve/disapprove
    /// @param approved Approval status
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }

    /// @notice Get team quest details
    /// @param questId The quest identifier
    /// @return Quest details
    function getTeamQuest(bytes32 questId) external view returns (TeamQuest memory) {
        return teamQuests[questId];
    }

    /// @notice Get referral quest details
    /// @param questId The quest identifier
    /// @return Quest details
    function getReferralQuest(bytes32 questId) external view returns (ReferralQuest memory) {
        return referralQuests[questId];
    }
}
