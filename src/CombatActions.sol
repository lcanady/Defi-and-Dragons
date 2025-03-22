// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./ProvableRandom.sol";

/// @title CombatActions
/// @notice Manages combat actions and special moves in the game
contract CombatActions is Ownable, ReentrancyGuard {
    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    ProvableRandom public immutable randomness;

    // Constants
    uint256 public constant MAX_CRIT_CHANCE = 5000; // 50%
    uint256 public constant MAX_LIFE_STEAL = 2000; // 20%
    uint256 public constant CHAIN_ATTACK_WINDOW = 5; // 5 seconds
    uint256 public constant COMBO_BONUS_PERCENT = 1000; // 10% per combo
    uint256 public constant MAX_RANDOM = 10000; // Base for percentage calculations

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

    // Structs
    struct CombatMove {
        string name;
        uint256 baseDamage;
        uint256 scalingFactor;
        uint256 cooldown;
        ActionType[] triggers;
        uint256 minValue;
        SpecialEffect effect;
        uint256 effectValue;
        bool active;
    }

    struct BattleState {
        bytes32 targetId;
        uint256 remainingHealth;
        uint256 battleStartTime;
        bool isActive;
        uint256 comboCount;
        mapping(SpecialEffect => uint256) activeEffects;
        mapping(SpecialEffect => uint256) effectEndTimes;
    }

    // Mappings
    mapping(bytes32 => CombatMove) public moves;
    mapping(uint256 => BattleState) public battles;
    mapping(address => bool) public approvedProtocols;
    mapping(bytes32 => mapping(bytes32 => bool)) public comboPaths;
    mapping(uint256 => bytes32) public lastMove;
    mapping(uint256 => uint256) public criticalChances;
    mapping(uint256 => uint256) public lifeStealAmounts;
    mapping(uint256 => mapping(bytes32 => uint256)) public moveCooldowns;

    // Events
    event MoveCreated(bytes32 indexed moveId, string name, ActionType[] triggers);
    event MoveTriggered(bytes32 indexed moveId, uint256 indexed characterId, uint256 damage);
    event BattleStarted(uint256 indexed characterId, bytes32 indexed targetId, uint256 health);
    event BattleEnded(uint256 indexed characterId, bytes32 indexed targetId, bool victory);
    event DamageDealt(uint256 indexed characterId, bytes32 indexed targetId, uint256 damage);
    event ComboTriggered(uint256 indexed characterId, uint256 comboCount, uint256 bonusDamage);
    event SpecialEffectTriggered(uint256 indexed characterId, SpecialEffect effect, uint256 value);
    event CriticalHit(uint256 indexed characterId, uint256 originalDamage, uint256 criticalDamage);

    constructor(
        address _character,
        address _gameToken,
        address _randomness
    ) Ownable(msg.sender) {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        randomness = ProvableRandom(_randomness);
    }

    /// @notice Set approval status for a protocol
    function setProtocolApproval(address protocol, bool approved) external onlyOwner {
        approvedProtocols[protocol] = approved;
    }

    /// @notice Create a new combat move
    function createMove(
        string memory name,
        uint256 baseDamage,
        uint256 scalingFactor,
        uint256 cooldown,
        ActionType[] memory triggers,
        uint256 minValue,
        SpecialEffect effect,
        uint256 effectValue
    ) external onlyOwner returns (bytes32) {
        require(bytes(name).length > 0, "Name required");
        require(triggers.length > 0, "Triggers required");

        bytes32 moveId = keccak256(
            abi.encodePacked(
                name,
                baseDamage,
                scalingFactor,
                cooldown,
                triggers,
                minValue,
                effect,
                effectValue,
                block.timestamp
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
            active: true
        });

        emit MoveCreated(moveId, name, triggers);
        return moveId;
    }

    /// @notice Create a combo path between two moves
    function createComboPath(bytes32 firstMoveId, bytes32 secondMoveId) external onlyOwner {
        require(moves[firstMoveId].active && moves[secondMoveId].active, "Invalid moves");
        comboPaths[firstMoveId][secondMoveId] = true;
    }

    /// @notice Set critical hit chance for a character
    function setCriticalChance(uint256 characterId, uint256 chance) external onlyOwner {
        require(chance <= MAX_CRIT_CHANCE, "Chance too high");
        criticalChances[characterId] = chance;
    }

    /// @notice Set life steal amount for a character
    function setLifeSteal(uint256 characterId, uint256 amount) external onlyOwner {
        require(amount <= MAX_LIFE_STEAL, "Amount too high");
        lifeStealAmounts[characterId] = amount;
    }

    /// @notice Start a battle with a target
    function startBattle(
        uint256 characterId,
        bytes32 targetId,
        uint256 targetHealth
    ) external {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        require(!battles[characterId].isActive, "Battle in progress");

        BattleState storage battle = battles[characterId];
        battle.targetId = targetId;
        battle.remainingHealth = targetHealth;
        battle.battleStartTime = block.timestamp;
        battle.isActive = true;
        battle.comboCount = 0;

        emit BattleStarted(characterId, targetId, targetHealth);
    }

    /// @notice Trigger a combat move
    function triggerMove(
        uint256 characterId,
        ActionType actionType,
        uint256 actionValue
    ) external returns (uint256) {
        require(approvedProtocols[msg.sender], "Not authorized");
        require(battles[characterId].isActive, "No active battle");

        bytes32 moveId = findBestMove(characterId, actionType, actionValue);
        require(moveId != bytes32(0), "No eligible moves");

        uint256 damage = executeCombatMove(characterId, moveId, actionValue);
        emit MoveTriggered(moveId, characterId, damage);

        return damage;
    }

    /// @notice Execute a combat move and calculate damage
    function executeCombatMove(
        uint256 characterId,
        bytes32 moveId,
        uint256 actionValue
    ) internal returns (uint256) {
        CombatMove storage move = moves[moveId];
        BattleState storage battle = battles[characterId];

        require(
            block.timestamp >= moveCooldowns[characterId][moveId],
            "Move on cooldown"
        );

        // Calculate base damage
        uint256 damage = move.baseDamage + ((actionValue * move.scalingFactor) / 10000);

        // Apply combo bonus if applicable
        if (lastMove[characterId] != bytes32(0) && comboPaths[lastMove[characterId]][moveId]) {
            battle.comboCount++;
            uint256 bonusDamage = (damage * COMBO_BONUS_PERCENT * battle.comboCount) / 10000;
            damage += bonusDamage;
            emit ComboTriggered(characterId, battle.comboCount, bonusDamage);
        } else {
            battle.comboCount = 0;
        }

        // Check for critical hit
        if (criticalChances[characterId] > 0) {
            // Initialize seed if not already done
            if (randomness.getCurrentSeed(address(this)) == bytes32(0)) {
                randomness.initializeSeed(keccak256(abi.encodePacked(block.timestamp, characterId)));
            }

            // Generate random number and check for crit
            uint256[] memory numbers = randomness.generateNumbers(1);
            uint256 roll = numbers[0] % MAX_RANDOM;
            
            if (roll < criticalChances[characterId]) {
                uint256 originalDamage = damage;
                damage *= 2;
                emit CriticalHit(characterId, originalDamage, damage);
            }
        }

        // Apply special effects
        damage = applySpecialEffects(characterId, move.effect, move.effectValue, damage);

        // Update state
        lastMove[characterId] = moveId;
        moveCooldowns[characterId][moveId] = block.timestamp + move.cooldown;
        battle.remainingHealth = battle.remainingHealth > damage ? battle.remainingHealth - damage : 0;

        emit DamageDealt(characterId, battle.targetId, damage);

        // Check for battle completion
        if (battle.remainingHealth == 0) {
            battle.isActive = false;
            emit BattleEnded(characterId, battle.targetId, true);
        }

        return damage;
    }

    /// @notice Find the best available move for the given action
    function findBestMove(
        uint256 characterId,
        ActionType actionType,
        uint256 actionValue
    ) internal view returns (bytes32) {
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

            uint256 potentialDamage = move.baseDamage + ((actionValue * move.scalingFactor) / 10000);
            if (potentialDamage > highestDamage) {
                highestDamage = potentialDamage;
                bestMove = moveId;
            }
        }

        return bestMove;
    }

    /// @notice Apply special effects to damage calculation
    function applySpecialEffects(
        uint256 characterId,
        SpecialEffect effect,
        uint256 effectValue,
        uint256 damage
    ) internal returns (uint256) {
        BattleState storage battle = battles[characterId];

        if (effect == SpecialEffect.CHAIN_ATTACK) {
            battle.activeEffects[SpecialEffect.CHAIN_ATTACK] = effectValue;
            battle.effectEndTimes[SpecialEffect.CHAIN_ATTACK] = block.timestamp + CHAIN_ATTACK_WINDOW;
            emit SpecialEffectTriggered(characterId, effect, effectValue);
        }
        else if (effect == SpecialEffect.MULTI_STRIKE) {
            damage *= effectValue;
            emit SpecialEffectTriggered(characterId, effect, effectValue);
        }
        else if (effect == SpecialEffect.LIFE_STEAL) {
            uint256 healAmount = (damage * effectValue) / 10000;
            emit SpecialEffectTriggered(characterId, effect, healAmount);
        }

        // Apply active chain attack effect
        if (battle.activeEffects[SpecialEffect.CHAIN_ATTACK] > 0 &&
            block.timestamp <= battle.effectEndTimes[SpecialEffect.CHAIN_ATTACK]) {
            damage += (damage * battle.activeEffects[SpecialEffect.CHAIN_ATTACK]) / 10000;
        }

        return damage;
    }

    /// @notice Get the current battle state for a character
    function getBattleState(uint256 characterId)
        external
        view
        returns (
            bytes32 targetId,
            uint256 remainingHealth,
            uint256 battleDuration,
            bool isActive
        )
    {
        BattleState storage battle = battles[characterId];
        return (
            battle.targetId,
            battle.remainingHealth,
            block.timestamp - battle.battleStartTime,
            battle.isActive
        );
    }
} 