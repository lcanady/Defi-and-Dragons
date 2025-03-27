// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Quest.sol";
import "./interfaces/ICharacter.sol";

contract CombatQuestValidator is AccessControl {
    bytes32 public constant COMBAT_MANAGER_ROLE = keccak256("COMBAT_MANAGER_ROLE");
    bytes32 public constant QUEST_DESIGNER_ROLE = keccak256("QUEST_DESIGNER_ROLE");

    Quest public immutable questContract;
    ICharacter public immutable characterContract;

    // Combat quest requirements
    struct CombatRequirement {
        uint256 minLevel; // Minimum level required
        uint256 minPartySize; // Minimum party size (1 for solo)
        uint256 targetEnemyType; // Type of enemy that must be defeated
        uint256 targetCount; // Number of enemies to defeat
        uint256 maxTimeLimit; // Maximum time to complete (0 for no limit)
        bool requiresFullParty; // Whether all party members must survive
        uint256[] requiredClasses; // Required character classes (empty for any)
    }

    // Combat tracking
    struct CombatSession {
        bytes32 partyId;
        uint256 startTime;
        uint256 enemiesDefeated;
        uint256 originalPartySize;
        mapping(uint256 => bool) partyMemberDefeated; // characterId => defeated
    }

    // Quest tracking
    mapping(uint256 => CombatRequirement) public combatRequirements; // questId => requirements
    mapping(bytes32 => mapping(uint256 => CombatSession)) public activeCombatSessions; // partyId => questId => session
    mapping(address => mapping(uint256 => bytes32)) public walletActiveQuests; // wallet => questId => partyId

    event CombatSessionStarted(bytes32 indexed partyId, uint256 indexed questId, uint256 partySize);

    event EnemyDefeated(bytes32 indexed partyId, uint256 indexed questId, uint256 enemyType, uint256 totalDefeated);

    event PartyMemberDefeated(bytes32 indexed partyId, uint256 indexed questId, uint256 characterId);

    event CombatQuestCompleted(bytes32 indexed partyId, uint256 indexed questId, bool success);

    constructor(address _questContract, address _characterContract) {
        questContract = Quest(_questContract);
        characterContract = ICharacter(_characterContract);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Quest Designer Functions
    function setCombatRequirements(
        uint256 questId,
        uint256 minLevel,
        uint256 minPartySize,
        uint256 targetEnemyType,
        uint256 targetCount,
        uint256 maxTimeLimit,
        bool requiresFullParty,
        uint256[] calldata requiredClasses
    ) external onlyRole(QUEST_DESIGNER_ROLE) {
        combatRequirements[questId] = CombatRequirement({
            minLevel: minLevel,
            minPartySize: minPartySize,
            targetEnemyType: targetEnemyType,
            targetCount: targetCount,
            maxTimeLimit: maxTimeLimit,
            requiresFullParty: requiresFullParty,
            requiredClasses: requiredClasses
        });
    }

    // Combat Management Functions
    function startCombatSession(address wallet, uint256 questId, bytes32 partyId, uint256[] calldata partyMembers)
        external
        onlyRole(COMBAT_MANAGER_ROLE)
    {
        require(walletActiveQuests[wallet][questId] == bytes32(0), "Already in combat quest");

        CombatRequirement memory req = combatRequirements[questId];
        require(partyMembers.length >= req.minPartySize, "Party too small");

        // Validate party members
        for (uint256 i = 0; i < partyMembers.length; i++) {
            // Check level requirement
            (,, Types.CharacterState memory state) =
                characterContract.getCharacter(partyMembers[i]);
            require(state.level >= req.minLevel, "Character level too low");

            // Check class requirements if any
            if (req.requiredClasses.length > 0) {
                bool validClass = false;
                for (uint256 j = 0; j < req.requiredClasses.length; j++) {
                    if (state.class == req.requiredClasses[j]) {
                        validClass = true;
                        break;
                    }
                }
                require(validClass, "Invalid character class");
            }
        }

        // Initialize combat session
        CombatSession storage session = activeCombatSessions[partyId][questId];
        session.partyId = partyId;
        session.startTime = block.timestamp;
        session.enemiesDefeated = 0;
        session.originalPartySize = partyMembers.length;

        walletActiveQuests[wallet][questId] = partyId;

        emit CombatSessionStarted(partyId, questId, partyMembers.length);
    }

    function recordEnemyDefeated(bytes32 partyId, uint256 questId, uint256 enemyType)
        external
        onlyRole(COMBAT_MANAGER_ROLE)
    {
        CombatSession storage session = activeCombatSessions[partyId][questId];
        require(session.partyId != bytes32(0), "No active session");

        CombatRequirement memory req = combatRequirements[questId];
        require(enemyType == req.targetEnemyType, "Wrong enemy type");

        // Check time limit if any
        if (req.maxTimeLimit > 0) {
            require(block.timestamp - session.startTime <= req.maxTimeLimit, "Time limit exceeded");
        }

        session.enemiesDefeated++;

        emit EnemyDefeated(partyId, questId, enemyType, session.enemiesDefeated);

        // Check if quest is complete
        if (session.enemiesDefeated >= req.targetCount) {
            _completeCombatQuest(partyId, questId);
        }
    }

    function recordPartyMemberDefeated(bytes32 partyId, uint256 questId, uint256 characterId)
        external
        onlyRole(COMBAT_MANAGER_ROLE)
    {
        CombatSession storage session = activeCombatSessions[partyId][questId];
        require(session.partyId != bytes32(0), "No active session");

        session.partyMemberDefeated[characterId] = true;

        emit PartyMemberDefeated(partyId, questId, characterId);

        // If full party required and too many defeated, fail the quest
        CombatRequirement memory req = combatRequirements[questId];
        if (req.requiresFullParty) {
            uint256 defeatedCount = 0;
            for (uint256 i = 0; i < session.originalPartySize; i++) {
                if (session.partyMemberDefeated[i]) defeatedCount++;
            }

            if (defeatedCount > 0) {
                _failCombatQuest(partyId, questId);
            }
        }
    }

    function _completeCombatQuest(bytes32 partyId, uint256 questId) internal {
        CombatSession storage session = activeCombatSessions[partyId][questId];

        // Update quest progress
        questContract.updateQuestProgress(
            questId, partyId, questContract.COMBAT_COMPLETED(), uint128(session.enemiesDefeated)
        );

        emit CombatQuestCompleted(partyId, questId, true);

        // Cleanup
        delete activeCombatSessions[partyId][questId];
    }

    function _failCombatQuest(bytes32 partyId, uint256 questId) internal {
        emit CombatQuestCompleted(partyId, questId, false);

        // Cleanup
        delete activeCombatSessions[partyId][questId];
    }

    function getActiveCombatSession(bytes32 partyId, uint256 questId)
        external
        view
        returns (uint256 startTime, uint256 enemiesDefeated, uint256 originalPartySize)
    {
        CombatSession storage session = activeCombatSessions[partyId][questId];
        return (session.startTime, session.enemiesDefeated, session.originalPartySize);
    }
}
