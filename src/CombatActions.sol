// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./ProvableRandom.sol";
import "./CombatDamageCalculator.sol";

// Custom errors for gas optimization
error NotCharacterOwner();
error NotAuthorized();
error BattleInProgress();
error NoActiveBattle();
error NoEligibleMoves();
error MoveOnCooldown();
error InvalidMoves();
error ChanceTooHigh();
error AmountTooHigh();
error NameRequired();
error TriggersRequired();

/// @title CombatActions
/// @notice Manages combat actions and special moves in the game
contract CombatActions is Ownable, ReentrancyGuard {
    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    ProvableRandom public immutable randomness;
    CombatDamageCalculator public damageCalculator;

    // Constants - using smaller uint types where possible
    uint16 public constant MAX_CRIT_CHANCE = 5000; // 50%
    uint16 public constant MAX_LIFE_STEAL = 2000; // 20%
    uint8 public constant CHAIN_ATTACK_WINDOW = 5; // 5 seconds
    uint16 public constant COMBO_BONUS_PERCENT = 1000; // 10% per combo
    uint16 public constant MAX_RANDOM = 10_000; // Base for percentage calculations

    // Enums
    enum ActionType {
        NONE,
        TRADE,
        YIELD_FARM,
        GOVERNANCE_VOTE,
        BRIDGE_TOKENS,
        FLASH_LOAN,
        NFT_TRADE,
        CREATE_PROPOSAL,
        DELEGATE
    }

    enum SpecialEffect {
        NONE,
        CHAIN_ATTACK,
        CRITICAL_HIT,
        LIFE_STEAL,
        ARMOR_BREAK,
        COMBO_ENABLER,
        MULTI_STRIKE,
        DOT
    }

    // Packed structs for gas optimization
    struct CombatMove {
        string name;
        uint32 baseDamage; // Reduced from uint256
        uint32 scalingFactor; // Reduced from uint256
        uint32 cooldown; // Reduced from uint256
        uint32 minValue; // Reduced from uint256
        uint32 effectValue; // Reduced from uint256
        ActionType[] triggers;
        SpecialEffect effect;
        bool active;
        uint16 criticalChance;
    }

    struct PackedBattleState {
        bytes32 targetId;
        uint128 remainingHealth; // Reduced from uint256
        uint40 battleStartTime; // Reduced from uint256, good until year 2104
        uint8 comboCount; // Reduced from uint256
        bool isActive;
    }

    struct EffectState {
        uint40 endTime; // Reduced from uint256
        uint32 value; // Reduced from uint256
    }

    // Mappings
    mapping(bytes32 => CombatMove) public moves;
    mapping(uint256 => PackedBattleState) public battles;
    mapping(address => bool) public approvedProtocols;
    mapping(bytes32 => mapping(bytes32 => bool)) public comboPaths;
    mapping(uint256 => bytes32) public lastMove;
    mapping(uint256 => uint16) public criticalChances; // Reduced from uint256
    mapping(uint256 => uint16) public lifeStealAmounts; // Reduced from uint256
    mapping(uint256 => mapping(bytes32 => uint40)) public moveCooldowns; // Reduced from uint256
    mapping(uint256 => mapping(SpecialEffect => EffectState)) private effectStates;

    // Events
    event MoveCreated(bytes32 indexed moveId, string name, ActionType[] triggers);
    event MoveTriggered(bytes32 indexed moveId, uint256 indexed characterId, uint256 damage);
    event BattleStarted(uint256 indexed characterId, bytes32 indexed targetId, uint256 health);
    event BattleEnded(uint256 indexed characterId, bytes32 indexed targetId, bool victory);
    event DamageDealt(uint256 indexed characterId, bytes32 indexed targetId, uint256 damage);
    event ComboTriggered(uint256 indexed characterId, uint8 comboCount, uint256 bonusDamage);
    event SpecialEffectTriggered(uint256 indexed characterId, SpecialEffect effect, uint32 value);
    event CriticalHit(uint256 indexed characterId, uint256 originalDamage, uint256 criticalDamage);

    constructor(address _character, address _gameToken, address _randomness, address _damageCalculator) Ownable() {
        _transferOwnership(msg.sender);
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        randomness = ProvableRandom(_randomness);
        damageCalculator = CombatDamageCalculator(_damageCalculator);
    }

    /// @notice Set approval status for a protocol
    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
    }

    /// @notice Create a new combat move
    function createMove(
        string calldata name,
        uint32 baseDamage,
        uint32 scalingFactor,
        uint32 cooldown,
        ActionType[] calldata triggers,
        uint32 minValue,
        SpecialEffect effect,
        uint32 effectValue,
        uint16 criticalChance
    ) external onlyOwner returns (bytes32) {
        if (bytes(name).length == 0) revert NameRequired();
        if (triggers.length == 0) revert TriggersRequired();

        bytes32 moveId = keccak256(
            abi.encodePacked(
                name, baseDamage, scalingFactor, cooldown, triggers, minValue, effect, effectValue, block.timestamp
            )
        );

        moves[moveId] = CombatMove({
            name: name,
            baseDamage: baseDamage,
            scalingFactor: scalingFactor,
            cooldown: cooldown,
            triggers: triggers,
            minValue: minValue,
            effect: effect,
            effectValue: effectValue,
            active: true,
            criticalChance: criticalChance
        });

        emit MoveCreated(moveId, name, triggers);
        return moveId;
    }

    /// @notice Create a combo path between two moves
    function createComboPath(bytes32 firstMoveId, bytes32 secondMoveId) external onlyOwner {
        if (!moves[firstMoveId].active || !moves[secondMoveId].active) revert InvalidMoves();
        comboPaths[firstMoveId][secondMoveId] = true;
    }

    /// @notice Set critical hit chance for a character
    function setCriticalChance(uint256 characterId, uint16 chance) external onlyOwner {
        if (chance > MAX_CRIT_CHANCE) revert ChanceTooHigh();
        criticalChances[characterId] = chance;
    }

    /// @notice Set life steal amount for a character
    function setLifeSteal(uint256 characterId, uint16 amount) external onlyOwner {
        if (amount > MAX_LIFE_STEAL) revert AmountTooHigh();
        lifeStealAmounts[characterId] = amount;
    }

    /// @notice Start a battle with a target
    function startBattle(uint256 characterId, bytes32 targetId, uint128 targetHealth) external {
        if (character.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();
        if (battles[characterId].isActive) revert BattleInProgress();

        battles[characterId] = PackedBattleState({
            targetId: targetId,
            remainingHealth: targetHealth,
            battleStartTime: uint40(block.timestamp),
            comboCount: 0,
            isActive: true
        });

        emit BattleStarted(characterId, targetId, targetHealth);
    }

    /// @notice Calculate damage for a combat move
    function calculateDamage(uint256 characterId, bytes32 moveId) internal returns (uint256) {
        CombatMove memory move = moves[moveId];
        uint256 baseDamage = move.baseDamage;
        
        // Apply scaling factor
        if (move.scalingFactor > 0) {
            baseDamage = (baseDamage * move.scalingFactor) / MAX_RANDOM;
        }

        // Apply critical hit if applicable
        baseDamage = _calculateCriticalHit(characterId, baseDamage, move.criticalChance);

        // Apply special effects
        baseDamage = _calculateSpecialEffectDamage(characterId, baseDamage, move);

        return baseDamage;
    }

    /// @notice Trigger a combat move
    function triggerMove(uint256 characterId, ActionType actionType, uint256 actionValue) external returns (uint256) {
        if (!approvedProtocols[msg.sender]) revert NotAuthorized();
        if (!battles[characterId].isActive) revert NoActiveBattle();

        // Initialize random seed for this character and context
        address owner = character.ownerOf(characterId);
        bytes32 context = bytes32(uint256(uint160(address(this))));
        randomness.initializeSeed(owner, context);

        bytes32 moveId = findBestMove(characterId, actionType, actionValue);
        if (moveId == bytes32(0)) revert NoEligibleMoves();

        // Check cooldown
        uint40 lastUsed = moveCooldowns[characterId][moveId];
        if (lastUsed > 0 && block.timestamp < lastUsed + moves[moveId].cooldown) revert MoveOnCooldown();

        // Calculate damage
        uint256 damage = calculateDamage(characterId, moveId);

        // Apply critical hit if applicable
        uint16 critChance = criticalChances[characterId];
        if (critChance > 0) {
            // Generate random number and check for crit
            uint256[] memory numbers = randomness.generateNumbers(owner, context);
            if (numbers[0] % MAX_RANDOM < critChance) {
                uint256 originalDamage = damage;
                damage = damage * 2;
                emit CriticalHit(characterId, originalDamage, damage);
            }
        }

        // Update battle state
        PackedBattleState storage battle = battles[characterId];
        battle.remainingHealth = uint128(battle.remainingHealth > damage ? battle.remainingHealth - damage : 0);

        // Update move cooldown
        moveCooldowns[characterId][moveId] = uint40(block.timestamp);

        // Check for combo
        bytes32 lastMoveId = lastMove[characterId];
        if (lastMoveId != bytes32(0) && comboPaths[lastMoveId][moveId]) {
            battle.comboCount++;
            uint256 bonusDamage = (damage * COMBO_BONUS_PERCENT * battle.comboCount) / MAX_RANDOM;
            damage += bonusDamage;
            emit ComboTriggered(characterId, battle.comboCount, bonusDamage);
        } else {
            battle.comboCount = 0;
        }

        // Update last move
        lastMove[characterId] = moveId;

        // Check for battle end
        if (battle.remainingHealth == 0) {
            battle.isActive = false;
            emit BattleEnded(characterId, battle.targetId, true);
        }

        emit DamageDealt(characterId, battle.targetId, damage);
        return damage;
    }

    /// @notice Execute a combat move and calculate damage
    function executeCombatMove(uint256 characterId, bytes32 moveId, uint256 actionValue) internal returns (uint256) {
        CombatMove storage move = moves[moveId];
        PackedBattleState storage battle = battles[characterId];

        if (block.timestamp < moveCooldowns[characterId][moveId]) revert MoveOnCooldown();

        // Calculate base damage
        uint256 damage = damageCalculator.calculateDamage(characterId, uint256(battle.targetId));

        // Apply move-specific scaling
        damage = damage + ((actionValue * move.scalingFactor) / 10_000);

        // Apply combo bonus if applicable
        bytes32 previousMove = lastMove[characterId];
        if (previousMove != bytes32(0) && comboPaths[previousMove][moveId]) {
            unchecked {
                ++battle.comboCount;
            }
            uint256 bonusDamage = (damage * COMBO_BONUS_PERCENT * battle.comboCount) / 10_000;
            damage += bonusDamage;
            emit ComboTriggered(characterId, battle.comboCount, bonusDamage);
        } else {
            battle.comboCount = 0;
        }

        // Check for critical hit
        uint16 critChance = criticalChances[characterId];
        if (critChance > 0) {
            // Generate random number and check for crit
            uint256[] memory numbers = randomness.generateNumbers(msg.sender, bytes32(uint256(uint160(address(this)))));
            if (numbers[0] % MAX_RANDOM < critChance) {
                uint256 originalDamage = damage;
                damage *= 2;
                emit CriticalHit(characterId, originalDamage, damage);
            }
        }

        // Update state
        lastMove[characterId] = moveId;
        moveCooldowns[characterId][moveId] = uint40(block.timestamp + move.cooldown);

        return damage;
    }

    /// @notice Find the best available move for the given action
    function findBestMove(uint256 characterId, ActionType actionType, uint256 actionValue)
        internal
        view
        returns (bytes32)
    {
        bytes32 bestMove;
        uint256 highestDamage;

        for (uint256 i = 0; i < 100; i++) {
            bytes32 moveId = keccak256(abi.encodePacked("move", i));
            if (!moves[moveId].active) continue;

            CombatMove storage move = moves[moveId];
            bool validTrigger = false;

            for (uint256 j = 0; j < move.triggers.length; j++) {
                if (move.triggers[j] == actionType) {
                    validTrigger = true;
                    break;
                }
            }

            if (!validTrigger) continue;
            if (actionValue < move.minValue) continue;
            if (block.timestamp < moveCooldowns[characterId][moveId]) continue;

            uint256 potentialDamage = move.baseDamage + ((actionValue * move.scalingFactor) / 10_000);
            if (potentialDamage > highestDamage) {
                highestDamage = potentialDamage;
                bestMove = moveId;
            }
        }

        return bestMove;
    }

    /// @notice Apply special effects to damage calculation
    function applySpecialEffects(uint256 characterId, SpecialEffect effect, uint256 effectValue, uint256 damage)
        internal
        returns (uint256)
    {
        if (effect == SpecialEffect.CHAIN_ATTACK) {
            effectStates[characterId][SpecialEffect.CHAIN_ATTACK] =
                EffectState({ endTime: uint40(block.timestamp + CHAIN_ATTACK_WINDOW), value: uint32(effectValue) });
            emit SpecialEffectTriggered(characterId, effect, uint32(effectValue));
        } else if (effect == SpecialEffect.MULTI_STRIKE) {
            damage *= effectValue;
            emit SpecialEffectTriggered(characterId, effect, uint32(effectValue));
        } else if (effect == SpecialEffect.LIFE_STEAL) {
            uint256 healAmount = (damage * effectValue) / 10_000;
            emit SpecialEffectTriggered(characterId, effect, uint32(healAmount));
        }

        // Apply active chain attack effect
        EffectState storage chainAttack = effectStates[characterId][SpecialEffect.CHAIN_ATTACK];
        if (chainAttack.value > 0 && block.timestamp <= chainAttack.endTime) {
            damage += (damage * chainAttack.value) / 10_000;
        }

        return damage;
    }

    /// @notice Get the current battle state for a character
    function getBattleState(uint256 characterId)
        external
        view
        returns (bytes32 targetId, uint256 remainingHealth, uint256 battleDuration, bool isActive)
    {
        PackedBattleState storage battle = battles[characterId];
        return (battle.targetId, battle.remainingHealth, block.timestamp - battle.battleStartTime, battle.isActive);
    }

    /// @notice Calculate damage for a combat move
    function calculateMoveDamage(uint256 characterId, uint256 targetId, bytes32 moveId, uint256 actionValue)
        internal
        returns (uint256)
    {
        CombatMove storage move = moves[moveId];

        // Get base damage from damage calculator
        uint256 damage = damageCalculator.calculateDamage(characterId, targetId);

        // Apply move-specific scaling
        damage = damage + ((actionValue * move.scalingFactor) / 10_000);

        // Apply critical hit chance
        uint256 critChance = move.criticalChance;
        if (critChance > 0) {
            // Generate random number and check for crit
            address owner = character.ownerOf(characterId);
            uint256[] memory numbers = randomness.generateNumbers(owner, bytes32(uint256(uint160(address(this)))));
            if (numbers[0] % MAX_RANDOM < critChance) {
                uint256 originalDamage = damage;
                damage *= 2;
                emit CriticalHit(characterId, originalDamage, damage);
            }
        }

        return damage;
    }

    /// @notice Calculate critical hit damage
    function _calculateCriticalHit(uint256 characterId, uint256 baseDamage, uint16 critChanceParam) internal returns (uint256) {
        uint16 critChance = criticalChances[characterId];
        if (critChance > 0) {
            // Generate random number and check for crit
            address owner = character.ownerOf(characterId);
            bytes32 context = bytes32(uint256(uint160(address(this))));
            uint256[] memory numbers = randomness.generateNumbers(owner, context);
            if (numbers[0] % MAX_RANDOM < critChance) {
                uint256 criticalDamage = baseDamage * 2;
                emit CriticalHit(characterId, baseDamage, criticalDamage);
                return criticalDamage;
            }
        }
        return baseDamage;
    }

    /// @notice Calculate special effect damage
    function _calculateSpecialEffectDamage(uint256 characterId, uint256 baseDamage, CombatMove memory move) internal returns (uint256) {
        uint256 critChance = move.criticalChance;
        if (critChance > 0) {
            // Generate random number and check for crit
            address owner = character.ownerOf(characterId);
            bytes32 context = bytes32(uint256(uint160(address(this))));
            uint256[] memory numbers = randomness.generateNumbers(owner, context);
            if (numbers[0] % MAX_RANDOM < critChance) {
                uint256 criticalDamage = baseDamage * 2;
                emit CriticalHit(characterId, baseDamage, criticalDamage);
                return criticalDamage;
            }
        }
        return baseDamage;
    }
}
