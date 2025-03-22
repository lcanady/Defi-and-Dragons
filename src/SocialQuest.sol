// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./ItemDrop.sol";

/// @title SocialQuest
/// @notice Manages team-based and social quests with collaborative rewards
contract SocialQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    ItemDrop public itemDrop;

    struct TeamQuest {
        string name;
        string description;
        uint256 minTeamSize;      // Minimum team members required
        uint256 maxTeamSize;      // Maximum team members allowed
        uint256 targetValue;      // Target value to achieve (volume, points, etc.)
        uint256 duration;         // Time to complete the quest
        uint256 teamReward;       // Base reward to split among team
        uint256 topReward;        // Additional reward for top contributor
        uint256 dropRateBonus;    // Bonus for item drop rates
        bool active;              // Whether quest is active
    }

    struct Team {
        uint256[] memberIds;      // Character IDs of team members
        uint256 startTime;        // When team started quest
        uint256 totalValue;       // Total value contributed
        bool completed;           // Whether quest was completed
        mapping(uint256 => uint256) contributions;  // Member contributions
    }

    struct ReferralQuest {
        string name;
        uint256 referrerReward;   // Reward for referrer
        uint256 referreeReward;   // Reward for new player
        uint256 requiredLevel;    // Level referree must reach
        uint256 duration;         // Time limit for referree to reach level
        bool active;              // Whether quest is active
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

    event TeamQuestCreated(bytes32 indexed id, string name, uint256 teamReward);
    event TeamFormed(bytes32 indexed questId, bytes32 indexed teamId, uint256[] members);
    event ContributionRecorded(bytes32 indexed questId, bytes32 indexed teamId, uint256 indexed characterId, uint256 amount);
    event TeamQuestCompleted(bytes32 indexed questId, bytes32 indexed teamId, uint256 reward);
    event ReferralQuestCreated(bytes32 indexed id, string name);
    event ReferralRegistered(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId);
    event ReferralCompleted(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId);

    constructor(
        address _character, 
        address _gameToken,
        address _itemDrop
    ) Ownable(msg.sender) {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        itemDrop = ItemDrop(_itemDrop);
    }

    /// @notice Create a new team quest
    function createTeamQuest(
        string calldata name,
        string calldata description,
        uint256 minTeamSize,
        uint256 maxTeamSize,
        uint256 targetValue,
        uint256 duration,
        uint256 teamReward,
        uint256 topReward,
        uint256 dropRateBonus
    ) external onlyOwner returns (bytes32) {
        require(minTeamSize > 0 && maxTeamSize >= minTeamSize, "Invalid team size");
        require(targetValue > 0, "Invalid target");
        require(duration > 0, "Invalid duration");
        
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
    function formTeam(bytes32 questId, uint256[] calldata memberIds) external nonReentrant {
        TeamQuest storage quest = teamQuests[questId];
        require(quest.active, "Quest not active");
        require(
            memberIds.length >= quest.minTeamSize && memberIds.length <= quest.maxTeamSize,
            "Invalid team size"
        );

        // Verify all members and check availability
        for (uint256 i = 0; i < memberIds.length; i++) {
            require(character.ownerOf(memberIds[i]) == msg.sender, "Not character owner");
            require(memberTeams[questId][memberIds[i]] == bytes32(0), "Already in team");
        }

        // Create team
        bytes32 teamId = keccak256(abi.encodePacked(questId, memberIds, block.timestamp));
        Team storage team = teams[teamId];
        team.memberIds = memberIds;
        team.startTime = block.timestamp;

        // Register team members
        for (uint256 i = 0; i < memberIds.length; i++) {
            memberTeams[questId][memberIds[i]] = teamId;
        }

        emit TeamFormed(questId, teamId, memberIds);
    }

    /// @notice Record contribution for team quest
    function recordContribution(
        bytes32 questId,
        uint256 characterId,
        uint256 value
    ) external {
        require(msg.sender == owner() || approvedTrackers[msg.sender], "Not authorized");
        
        bytes32 teamId = memberTeams[questId][characterId];
        require(teamId != bytes32(0), "Not in team");

        TeamQuest storage quest = teamQuests[questId];
        Team storage team = teams[teamId];
        
        require(!team.completed, "Quest completed");
        require(
            block.timestamp <= team.startTime + quest.duration,
            "Quest expired"
        );

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
    function completeTeamQuest(bytes32 questId, bytes32 teamId) internal {
        TeamQuest storage quest = teamQuests[questId];
        Team storage team = teams[teamId];

        // Find top contributor
        uint256 topContribution = 0;
        uint256 topContributor = 0;
        
        for (uint256 i = 0; i < team.memberIds.length; i++) {
            uint256 memberId = team.memberIds[i];
            if (team.contributions[memberId] > topContribution) {
                topContribution = team.contributions[memberId];
                topContributor = memberId;
            }
        }

        // Calculate individual rewards
        uint256 baseReward = quest.teamReward / team.memberIds.length;
        
        // Distribute rewards
        for (uint256 i = 0; i < team.memberIds.length; i++) {
            uint256 memberId = team.memberIds[i];
            uint256 reward = baseReward;
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

        team.completed = true;
        emit TeamQuestCompleted(questId, teamId, quest.teamReward + quest.topReward);
    }

    /// @notice Create a referral quest
    function createReferralQuest(
        string calldata name,
        uint256 referrerReward,
        uint256 referreeReward,
        uint256 requiredLevel,
        uint256 duration
    ) external onlyOwner returns (bytes32) {
        require(requiredLevel > 0, "Invalid level requirement");
        require(duration > 0, "Invalid duration");
        
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
    function registerReferral(
        bytes32 questId,
        uint256 referrerId,
        uint256 referreeId
    ) external {
        require(character.ownerOf(referrerId) == msg.sender, "Not referrer");
        require(referralQuests[questId].active, "Quest not active");
        require(!referralProgress[referrerId][referreeId][questId], "Already referred");

        referralProgress[referrerId][referreeId][questId] = true;
        emit ReferralRegistered(referrerId, referreeId, questId);
    }

    /// @notice Complete a referral quest
    function completeReferral(
        bytes32 questId,
        uint256 referrerId,
        uint256 referreeId
    ) external {
        ReferralQuest storage quest = referralQuests[questId];
        require(quest.active, "Quest not active");
        require(referralProgress[referrerId][referreeId][questId], "Not referred");

        // Verify referree level
        (,, Types.CharacterState memory state) = character.getCharacter(referreeId);
        require(state.level >= quest.requiredLevel, "Level too low");

        address referrerAddress = character.ownerOf(referrerId);
        address referreeAddress = character.ownerOf(referreeId);

        // Distribute rewards
        gameToken.mint(referrerAddress, quest.referrerReward);
        gameToken.mint(referreeAddress, quest.referreeReward);

        // Give both players a chance for item drops
        itemDrop.requestRandomDrop(referrerAddress, 100); // Base drop rate bonus for referrer
        itemDrop.requestRandomDrop(referreeAddress, 50);  // Smaller bonus for referree

        emit ReferralCompleted(referrerId, referreeId, questId);
    }

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    /// @notice Set approval for progress trackers
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }
} 