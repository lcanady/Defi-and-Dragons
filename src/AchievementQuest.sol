// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";

/// @title AchievementQuest
/// @notice Manages achievement-based quests with milestones and repeatable challenges
contract AchievementQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;

    struct Achievement {
        string name;
        string description;
        uint256 difficulty; // 1-10 scale
        uint256 baseReward; // Base reward amount
        bool repeatable; // Whether achievement can be repeated
        uint256 maxRepeats; // Maximum times it can be repeated (0 for unlimited)
        uint256 cooldown; // Time between repeats
        uint256[] milestones; // Required values for each milestone
        uint256[] bonuses; // Bonus rewards for each milestone
    }

    struct UserProgress {
        uint256 currentValue; // Current progress value
        uint256 completions; // Number of times completed
        uint256 lastCompletion; // Timestamp of last completion
        uint256 milestone; // Current milestone index
    }

    // Achievement ID => Achievement details
    mapping(bytes32 => Achievement) public achievements;

    // Achievement ID => Character ID => Progress
    mapping(bytes32 => mapping(uint256 => UserProgress)) public userProgress;

    // Character ID => Achievement IDs completed
    mapping(uint256 => bytes32[]) public characterAchievements;

    event AchievementCreated(bytes32 indexed id, string name, uint256 difficulty);
    event AchievementProgressed(bytes32 indexed id, uint256 indexed characterId, uint256 value);
    event MilestoneCompleted(bytes32 indexed id, uint256 indexed characterId, uint256 milestone, uint256 reward);
    event AchievementCompleted(bytes32 indexed id, uint256 indexed characterId, uint256 totalReward);

    constructor(address _character, address _gameToken) Ownable() {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        _transferOwnership(msg.sender);
    }

    /// @notice Create a new achievement
    function createAchievement(
        string calldata name,
        string calldata description,
        uint256 difficulty,
        uint256 baseReward,
        bool repeatable,
        uint256 maxRepeats,
        uint256 cooldown,
        uint256[] calldata milestones,
        uint256[] calldata bonuses
    ) external onlyOwner returns (bytes32) {
        require(difficulty > 0 && difficulty <= 10, "Invalid difficulty");
        require(milestones.length > 0, "No milestones");
        require(milestones.length == bonuses.length, "Mismatched arrays");

        bytes32 id = keccak256(abi.encodePacked(name, block.timestamp));

        achievements[id] = Achievement({
            name: name,
            description: description,
            difficulty: difficulty,
            baseReward: baseReward,
            repeatable: repeatable,
            maxRepeats: maxRepeats,
            cooldown: cooldown,
            milestones: milestones,
            bonuses: bonuses
        });

        emit AchievementCreated(id, name, difficulty);
        return id;
    }

    /// @notice Record progress for an achievement
    function recordProgress(bytes32 achievementId, uint256 characterId, uint256 value) external {
        require(msg.sender == owner() || approvedTrackers[msg.sender], "Not authorized");
        require(character.ownerOf(characterId) != address(0), "Invalid character");

        Achievement storage achievement = achievements[achievementId];
        require(achievement.difficulty > 0, "Achievement doesn't exist");

        UserProgress storage progress = userProgress[achievementId][characterId];

        // Check if achievement can be progressed
        if (!achievement.repeatable) {
            require(progress.completions == 0, "Already completed");
        } else {
            require(
                progress.completions < achievement.maxRepeats || achievement.maxRepeats == 0, "Max completions reached"
            );
            require(block.timestamp >= progress.lastCompletion + achievement.cooldown, "On cooldown");
        }

        // Update progress
        progress.currentValue += value;
        emit AchievementProgressed(achievementId, characterId, progress.currentValue);

        // Check for milestone completion
        while (
            progress.milestone < achievement.milestones.length
                && progress.currentValue >= achievement.milestones[progress.milestone]
        ) {
            // Award milestone bonus
            uint256 bonus = achievement.bonuses[progress.milestone];
            gameToken.mint(character.ownerOf(characterId), bonus);

            emit MilestoneCompleted(achievementId, characterId, progress.milestone, bonus);

            progress.milestone++;
        }

        // Check for achievement completion
        if (
            progress.milestone == achievement.milestones.length
                && progress.currentValue >= achievement.milestones[achievement.milestones.length - 1]
        ) {
            completeAchievement(achievementId, characterId);
        }
    }

    /// @notice Complete an achievement and award rewards
    function completeAchievement(bytes32 achievementId, uint256 characterId) internal {
        Achievement storage achievement = achievements[achievementId];
        UserProgress storage progress = userProgress[achievementId][characterId];

        // Calculate total reward (base + difficulty bonus)
        uint256 totalReward = achievement.baseReward + (achievement.baseReward * achievement.difficulty) / 10;

        // Award rewards
        gameToken.mint(character.ownerOf(characterId), totalReward);

        // Update completion status
        progress.completions++;
        progress.lastCompletion = block.timestamp;

        // Reset progress if repeatable
        if (achievement.repeatable) {
            progress.currentValue = 0;
            progress.milestone = 0;
        }

        // Add to character's achievements if first time
        if (progress.completions == 1) {
            characterAchievements[characterId].push(achievementId);
        }

        emit AchievementCompleted(achievementId, characterId, totalReward);
    }

    /// @notice Get all achievements completed by a character
    function getCharacterAchievements(uint256 characterId) external view returns (bytes32[] memory) {
        return characterAchievements[characterId];
    }

    /// @notice Get detailed progress for an achievement
    function getAchievementProgress(bytes32 achievementId, uint256 characterId)
        external
        view
        returns (
            uint256 currentValue,
            uint256 completions,
            uint256 currentMilestone,
            uint256 nextMilestone,
            uint256 timeUntilAvailable
        )
    {
        Achievement storage achievement = achievements[achievementId];
        UserProgress storage progress = userProgress[achievementId][characterId];

        nextMilestone =
            progress.milestone < achievement.milestones.length ? achievement.milestones[progress.milestone] : 0;

        timeUntilAvailable = progress.lastCompletion + achievement.cooldown > block.timestamp
            ? progress.lastCompletion + achievement.cooldown - block.timestamp
            : 0;

        return (progress.currentValue, progress.completions, progress.milestone, nextMilestone, timeUntilAvailable);
    }

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    /// @notice Set approval for progress trackers
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }
}
