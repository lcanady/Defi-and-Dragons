// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockCombatQuestValidator {
    struct CombatRequirement {
        uint256 minLevel;
        uint256 minPartySize;
        uint256 targetEnemyType;
        uint256 targetCount;
        uint256 maxTimeLimit;
        bool requiresFullParty;
        uint256[] requiredClasses;
    }

    // Test state variables to track calls
    bool public enemyDefeatedCalled;
    bytes32 public lastPartyId;
    uint256 public lastQuestId;
    uint256 public lastEnemyType;

    // Mock combat requirements for testing
    mapping(uint256 => CombatRequirement) public requirements;

    constructor() {
        // Initialize with a default combat requirement for testing
        uint256[] memory emptyClasses = new uint256[](0);
        requirements[1] = CombatRequirement({
            minLevel: 1,
            minPartySize: 1,
            targetEnemyType: 100,
            targetCount: 5,
            maxTimeLimit: 3600, // 1 hour
            requiresFullParty: false,
            requiredClasses: emptyClasses
        });
    }

    // This function is needed for ActionCombatManager.getEnemyType
    function combatRequirements(uint256 questId) external view returns (
        uint256 minLevel,
        uint256 minPartySize,
        uint256 targetEnemyType,
        uint256 targetCount,
        uint256 maxTimeLimit,
        bool requiresFullParty
    ) {
        CombatRequirement storage req = requirements[questId];
        return (
            req.minLevel,
            req.minPartySize,
            req.targetEnemyType,
            req.targetCount,
            req.maxTimeLimit,
            req.requiresFullParty
        );
    }

    function recordEnemyDefeated(bytes32 partyId, uint256 questId, uint256 enemyType) external {
        enemyDefeatedCalled = true;
        lastPartyId = partyId;
        lastQuestId = questId;
        lastEnemyType = enemyType;
        
        // We don't perform any validation in the mock to simplify testing
    }

    // Mock for setting specific combat requirements for testing
    function setCombatRequirement(
        uint256 questId,
        uint256 targetEnemyType
    ) external {
        uint256[] memory emptyClasses = new uint256[](0);
        requirements[questId] = CombatRequirement({
            minLevel: 1,
            minPartySize: 1,
            targetEnemyType: targetEnemyType,
            targetCount: 5,
            maxTimeLimit: 3600,
            requiresFullParty: false,
            requiredClasses: emptyClasses
        });
    }

    // Reset the test state
    function reset() external {
        enemyDefeatedCalled = false;
        lastPartyId = bytes32(0);
        lastQuestId = 0;
        lastEnemyType = 0;
    }
} 