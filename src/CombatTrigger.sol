// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICharacter.sol";
import "./CombatQuest.sol";
import "./ProtocolQuest.sol";
import "./TimeQuest.sol";

/// @title CombatTrigger
/// @notice Manages combat encounters triggered by protocol interactions and quest completions
contract CombatTrigger is Ownable, ReentrancyGuard {
    
    CombatQuest public immutable combatQuest;
    ProtocolQuest public immutable protocolQuest;
    TimeQuest public immutable timeQuest;
    ICharacter public immutable character;

    struct CombatTriggerRule {
        TriggerType triggerType;      // Type of trigger
        bytes32 sourceId;             // ID of source quest/protocol
        uint256 threshold;            // Required value to trigger
        bytes32 monsterId;           // Monster/boss to spawn
        uint256 spawnDuration;       // How long monster remains
        uint256 cooldown;            // Cooldown between spawns
        bool isActive;               // Whether rule is active
    }

    struct TriggerState {
        uint256 lastTrigger;         // Last time triggered
        uint256 progress;            // Current progress
        bool isActive;               // Whether currently triggered
    }

    enum TriggerType {
        PROTOCOL_VOLUME,             // Based on trading volume
        PROTOCOL_INTERACTIONS,       // Based on number of interactions
        TIME_STREAK,                // Based on daily quest streaks
        QUEST_COMPLETION            // Based on completing specific quests
    }

    // Rule ID => Rule details
    mapping(bytes32 => CombatTriggerRule) public triggerRules;
    
    // Rule ID => Character ID => Trigger state
    mapping(bytes32 => mapping(uint256 => TriggerState)) public triggerStates;
    
    // Protocol => Whether it can trigger combat
    mapping(address => bool) public approvedTriggers;

    event CombatTriggerCreated(bytes32 indexed ruleId, TriggerType triggerType, bytes32 monsterId);
    event CombatTriggered(bytes32 indexed ruleId, uint256 indexed characterId, bytes32 monsterId, bytes32 encounterId);
    event ProgressUpdated(bytes32 indexed ruleId, uint256 indexed characterId, uint256 progress);
    event TriggerCompleted(bytes32 indexed ruleId, uint256 indexed characterId);

    constructor(
        address _combatQuest,
        address _protocolQuest,
        address _timeQuest,
        address _character
    ) Ownable(msg.sender) {
        combatQuest = CombatQuest(_combatQuest);
        protocolQuest = ProtocolQuest(_protocolQuest);
        timeQuest = TimeQuest(_timeQuest);
        character = ICharacter(_character);
    }

    /// @notice Create a new combat trigger rule
    function createTriggerRule(
        TriggerType triggerType,
        bytes32 sourceId,
        uint256 threshold,
        bytes32 monsterId,
        uint256 spawnDuration,
        uint256 cooldown
    ) external onlyOwner returns (bytes32) {
        bytes32 ruleId = keccak256(abi.encodePacked(
            triggerType,
            sourceId,
            threshold,
            monsterId,
            block.timestamp
        ));

        triggerRules[ruleId] = CombatTriggerRule({
            triggerType: triggerType,
            sourceId: sourceId,
            threshold: threshold,
            monsterId: monsterId,
            spawnDuration: spawnDuration,
            cooldown: cooldown,
            isActive: true
        });

        emit CombatTriggerCreated(ruleId, triggerType, monsterId);
        return ruleId;
    }

    /// @notice Update progress for a trigger rule
    function updateProgress(
        bytes32 ruleId,
        uint256 characterId,
        uint256 amount
    ) public {
        require(approvedTriggers[msg.sender], "Not approved trigger");
        
        CombatTriggerRule storage rule = triggerRules[ruleId];
        require(rule.isActive, "Rule not active");

        TriggerState storage state = triggerStates[ruleId][characterId];
        require(
            block.timestamp >= state.lastTrigger + rule.cooldown,
            "Still in cooldown"
        );

        // Update progress
        state.progress += amount;
        emit ProgressUpdated(ruleId, characterId, state.progress);

        // Check if threshold reached
        if (state.progress >= rule.threshold && !state.isActive) {
            triggerCombat(ruleId, characterId);
        }
    }

    /// @notice Trigger combat encounter
    function triggerCombat(bytes32 ruleId, uint256 characterId) internal {
        CombatTriggerRule storage rule = triggerRules[ruleId];
        TriggerState storage state = triggerStates[ruleId][characterId];

        // Start boss fight or spawn monster
        bytes32 encounterId = combatQuest.startBossFight(
            rule.monsterId,
            rule.spawnDuration
        );

        // Update state
        state.lastTrigger = block.timestamp;
        state.progress = 0;
        state.isActive = true;

        emit CombatTriggered(ruleId, characterId, rule.monsterId, encounterId);
    }

    /// @notice Record protocol interaction progress
    function recordProtocolProgress(
        address protocol,
        uint256 characterId,
        uint256 volume
    ) external {
        require(msg.sender == address(protocolQuest), "Only protocol quest");
        
        bytes32[] memory activeRules = getActiveRulesByType(TriggerType.PROTOCOL_VOLUME);
        
        for (uint256 i = 0; i < activeRules.length; i++) {
            CombatTriggerRule storage rule = triggerRules[activeRules[i]];
            if (bytes32(uint256(uint160(protocol))) == rule.sourceId) {
                updateProgress(activeRules[i], characterId, volume);
            }
        }
    }

    /// @notice Record time quest streak progress
    function recordTimeProgress(
        bytes32 questId,
        uint256 characterId,
        uint256 streak
    ) external {
        require(msg.sender == address(timeQuest), "Only time quest");
        
        bytes32[] memory activeRules = getActiveRulesByType(TriggerType.TIME_STREAK);
        
        for (uint256 i = 0; i < activeRules.length; i++) {
            CombatTriggerRule storage rule = triggerRules[activeRules[i]];
            if (questId == rule.sourceId) {
                updateProgress(activeRules[i], characterId, streak);
            }
        }
    }

    /// @notice Record quest completion
    function recordQuestCompletion(
        bytes32 questId,
        uint256 characterId
    ) external {
        require(
            msg.sender == address(protocolQuest) ||
            msg.sender == address(timeQuest),
            "Invalid quest contract"
        );
        
        bytes32[] memory activeRules = getActiveRulesByType(TriggerType.QUEST_COMPLETION);
        
        for (uint256 i = 0; i < activeRules.length; i++) {
            CombatTriggerRule storage rule = triggerRules[activeRules[i]];
            if (questId == rule.sourceId) {
                updateProgress(activeRules[i], characterId, 1);
            }
        }
    }

    /// @notice Get active rules by trigger type
    function getActiveRulesByType(TriggerType triggerType)
        public
        view
        returns (bytes32[] memory)
    {
        uint256 count = 0;
        bytes32[] memory allRules = new bytes32[](100); // Arbitrary limit
        
        // First pass: count active rules
        for (uint256 i = 0; i < allRules.length; i++) {
            bytes32 ruleId = bytes32(i);
            CombatTriggerRule storage rule = triggerRules[ruleId];
            if (rule.isActive && rule.triggerType == triggerType) {
                allRules[count] = ruleId;
                count++;
            }
        }
        
        // Second pass: create correctly sized array
        bytes32[] memory activeRules = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            activeRules[i] = allRules[i];
        }
        
        return activeRules;
    }

    /// @notice Set approval for trigger sources
    function setTriggerApproval(address trigger, bool approved) external onlyOwner {
        approvedTriggers[trigger] = approved;
    }

    /// @notice Get trigger progress
    function getTriggerProgress(bytes32 ruleId, uint256 characterId)
        external
        view
        returns (
            uint256 progress,
            uint256 threshold,
            uint256 cooldownEnds,
            bool isActive
        )
    {
        CombatTriggerRule storage rule = triggerRules[ruleId];
        TriggerState storage state = triggerStates[ruleId][characterId];
        
        return (
            state.progress,
            rule.threshold,
            state.lastTrigger + rule.cooldown,
            state.isActive
        );
    }
} 