// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";

/// @title TimeQuest
/// @notice Manages time-based quests with bonus periods and seasonal events
contract TimeQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;

    struct TimeWindow {
        uint256 startTime;        // Start of time window
        uint256 endTime;          // End of time window
        uint256 multiplier;       // Reward multiplier in basis points (100 = 1x)
    }

    struct DailyQuest {
        string name;
        string description;
        uint256 baseReward;       // Base reward amount
        uint256 streakBonus;      // Additional reward per day of streak
        uint256 maxStreakBonus;   // Maximum streak bonus
        uint256 resetTime;        // Time when quest resets (seconds into day)
        bool active;              // Whether quest is active
    }

    struct SeasonalQuest {
        string name;
        string description;
        uint256 startTime;        // Season start
        uint256 endTime;          // Season end
        uint256 targetValue;      // Required value to complete
        uint256 baseReward;       // Base reward amount
        uint256[] milestones;     // Progress milestones
        uint256[] bonuses;        // Milestone bonuses
        bool active;              // Whether quest is active
    }

    struct UserProgress {
        uint256 lastCompletion;   // Last completion timestamp
        uint256 currentStreak;    // Current daily streak
        uint256 bestStreak;       // Best streak achieved
        uint256 seasonalProgress; // Progress in seasonal quest
        uint256 milestone;        // Current milestone index
    }

    // Quest ID => Quest details
    mapping(bytes32 => DailyQuest) public dailyQuests;
    mapping(bytes32 => SeasonalQuest) public seasonalQuests;
    
    // Quest ID => Time windows
    mapping(bytes32 => TimeWindow[]) public bonusWindows;
    
    // Quest ID => Character ID => Progress
    mapping(bytes32 => mapping(uint256 => UserProgress)) public userProgress;

    event DailyQuestCreated(bytes32 indexed id, string name);
    event SeasonalQuestCreated(bytes32 indexed id, string name, uint256 startTime, uint256 endTime);
    event BonusWindowAdded(bytes32 indexed questId, uint256 startTime, uint256 endTime, uint256 multiplier);
    event DailyQuestCompleted(bytes32 indexed questId, uint256 indexed characterId, uint256 reward, uint256 streak);
    event SeasonalProgressUpdated(bytes32 indexed questId, uint256 indexed characterId, uint256 progress);
    event SeasonalQuestCompleted(bytes32 indexed questId, uint256 indexed characterId, uint256 reward);
    event MilestoneReached(bytes32 indexed questId, uint256 indexed characterId, uint256 milestone, uint256 bonus);

    constructor(address _character, address _gameToken) Ownable(msg.sender) {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
    }

    /// @notice Create a new daily quest
    function createDailyQuest(
        string calldata name,
        string calldata description,
        uint256 baseReward,
        uint256 streakBonus,
        uint256 maxStreakBonus,
        uint256 resetTime
    ) external onlyOwner returns (bytes32) {
        require(resetTime < 24 hours, "Invalid reset time");
        
        bytes32 id = keccak256(abi.encodePacked(name, block.timestamp));
        
        dailyQuests[id] = DailyQuest({
            name: name,
            description: description,
            baseReward: baseReward,
            streakBonus: streakBonus,
            maxStreakBonus: maxStreakBonus,
            resetTime: resetTime,
            active: true
        });

        emit DailyQuestCreated(id, name);
        return id;
    }

    /// @notice Create a new seasonal quest
    function createSeasonalQuest(
        string calldata name,
        string calldata description,
        uint256 startTime,
        uint256 duration,
        uint256 targetValue,
        uint256 baseReward,
        uint256[] calldata milestones,
        uint256[] calldata bonuses
    ) external onlyOwner returns (bytes32) {
        require(startTime >= block.timestamp, "Invalid start time");
        require(milestones.length == bonuses.length, "Array length mismatch");
        require(milestones[milestones.length - 1] <= targetValue, "Invalid milestones");
        
        bytes32 id = keccak256(abi.encodePacked(name, startTime));
        
        seasonalQuests[id] = SeasonalQuest({
            name: name,
            description: description,
            startTime: startTime,
            endTime: startTime + duration,
            targetValue: targetValue,
            baseReward: baseReward,
            milestones: milestones,
            bonuses: bonuses,
            active: true
        });

        emit SeasonalQuestCreated(id, name, startTime, startTime + duration);
        return id;
    }

    /// @notice Add a bonus time window to a quest
    function addBonusWindow(
        bytes32 questId,
        uint256 startTime,
        uint256 endTime,
        uint256 multiplier
    ) external onlyOwner {
        require(startTime >= block.timestamp, "Invalid start time");
        require(endTime > startTime, "Invalid end time");
        require(multiplier > 0, "Invalid multiplier");
        
        bonusWindows[questId].push(TimeWindow({
            startTime: startTime,
            endTime: endTime,
            multiplier: multiplier
        }));

        emit BonusWindowAdded(questId, startTime, endTime, multiplier);
    }

    /// @notice Complete a daily quest
    function completeDailyQuest(bytes32 questId, uint256 characterId) external nonReentrant {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        
        DailyQuest storage quest = dailyQuests[questId];
        require(quest.active, "Quest not active");

        UserProgress storage progress = userProgress[questId][characterId];
        
        // Check if enough time has passed since last completion
        uint256 lastResetTime = getLastResetTime(quest.resetTime);
        require(progress.lastCompletion < lastResetTime, "Already completed today");

        // Calculate streak
        if (progress.lastCompletion >= lastResetTime - 24 hours) {
            progress.currentStreak++;
        } else {
            progress.currentStreak = 1;
        }

        // Update best streak
        if (progress.currentStreak > progress.bestStreak) {
            progress.bestStreak = progress.currentStreak;
        }

        // Calculate rewards
        uint256 streakBonus = Math.min(
            progress.currentStreak * quest.streakBonus,
            quest.maxStreakBonus
        );
        
        uint256 baseReward = quest.baseReward + streakBonus;
        uint256 totalReward = applyTimeBonus(questId, baseReward);

        // Update completion time and distribute rewards
        progress.lastCompletion = block.timestamp;
        gameToken.mint(msg.sender, totalReward);

        emit DailyQuestCompleted(questId, characterId, totalReward, progress.currentStreak);
    }

    /// @notice Update progress for seasonal quest
    function updateSeasonalProgress(
        bytes32 questId,
        uint256 characterId,
        uint256 progress
    ) external {
        require(msg.sender == owner() || approvedTrackers[msg.sender], "Not authorized");
        
        SeasonalQuest storage quest = seasonalQuests[questId];
        require(quest.active, "Quest not active");
        require(
            block.timestamp >= quest.startTime && block.timestamp <= quest.endTime,
            "Not in season"
        );

        UserProgress storage userProg = userProgress[questId][characterId];
        userProg.seasonalProgress += progress;

        emit SeasonalProgressUpdated(questId, characterId, userProg.seasonalProgress);

        // Check for milestone completion
        while (
            userProg.milestone < quest.milestones.length &&
            userProg.seasonalProgress >= quest.milestones[userProg.milestone]
        ) {
            uint256 bonus = quest.bonuses[userProg.milestone];
            gameToken.mint(character.ownerOf(characterId), bonus);
            
            emit MilestoneReached(
                questId,
                characterId,
                userProg.milestone,
                bonus
            );
            
            userProg.milestone++;
        }

        // Check for quest completion
        if (userProg.seasonalProgress >= quest.targetValue) {
            completeSeasonalQuest(questId, characterId);
        }
    }

    /// @notice Complete a seasonal quest
    function completeSeasonalQuest(bytes32 questId, uint256 characterId) internal {
        SeasonalQuest storage quest = seasonalQuests[questId];

        // Calculate final reward with time bonus
        uint256 totalReward = applyTimeBonus(questId, quest.baseReward);
        
        gameToken.mint(character.ownerOf(characterId), totalReward);
        emit SeasonalQuestCompleted(questId, characterId, totalReward);
    }

    /// @notice Calculate time bonus for current timestamp
    function applyTimeBonus(bytes32 questId, uint256 baseAmount) public view returns (uint256) {
        TimeWindow[] storage windows = bonusWindows[questId];
        uint256 highestMultiplier = 100; // 1x multiplier by default

        for (uint256 i = 0; i < windows.length; i++) {
            if (
                block.timestamp >= windows[i].startTime &&
                block.timestamp <= windows[i].endTime &&
                windows[i].multiplier > highestMultiplier
            ) {
                highestMultiplier = windows[i].multiplier;
            }
        }

        return (baseAmount * highestMultiplier) / 100;
    }

    /// @notice Get the last reset time for daily quests
    function getLastResetTime(uint256 resetSeconds) public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 dayStart = timestamp - (timestamp % 1 days);
        uint256 resetTime = dayStart + resetSeconds;
        
        return timestamp >= resetTime ? resetTime : resetTime - 1 days;
    }

    /// @notice Get user's quest progress
    function getQuestProgress(bytes32 questId, uint256 characterId)
        external
        view
        returns (
            uint256 lastCompletion,
            uint256 currentStreak,
            uint256 bestStreak,
            uint256 seasonalProgress,
            uint256 currentMilestone
        )
    {
        UserProgress storage progress = userProgress[questId][characterId];
        return (
            progress.lastCompletion,
            progress.currentStreak,
            progress.bestStreak,
            progress.seasonalProgress,
            progress.milestone
        );
    }

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    /// @notice Set approval for progress trackers
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }
} 