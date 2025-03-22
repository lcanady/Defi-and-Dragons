// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./CombatAbilities.sol";

/// @title CombatQuest
/// @notice Manages combat-based quests including boss fights and monster hunts
contract CombatQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    CombatAbilities public immutable abilities;

    struct Monster {
        string name;
        uint256 level;           // Monster's level
        uint256 health;          // Base health points
        uint256 damage;          // Base damage per hit
        uint256 defense;         // Damage reduction
        uint256 rewardBase;      // Base reward for defeating
        bool isBoss;            // Whether this is a boss monster
        string[] requiredItems;  // Items needed to fight (empty if none)
        bool active;            // Whether this monster is currently active
    }

    struct BossFight {
        bytes32 monsterId;      // ID of the boss monster
        uint256 startTime;      // When the boss fight starts
        uint256 duration;       // How long the boss is available
        uint256 totalDamage;    // Cumulative damage dealt to boss
        uint256 participants;   // Number of participants
        bool defeated;          // Whether boss was defeated
        mapping(uint256 => uint256) damageDealt;  // Character => damage dealt
    }

    struct Hunt {
        bytes32 monsterId;      // Monster to hunt
        uint256 count;          // Number to defeat
        uint256 timeLimit;      // Time limit for hunt
        uint256 bonusReward;    // Additional reward for completion
        bool active;            // Whether hunt is active
    }

    struct HuntProgress {
        uint256 startTime;      // When the hunt was started
        uint256 monstersSlain;  // Number of monsters defeated
        bool completed;         // Whether hunt was completed
    }

    struct MonsterAbility {
        bytes32[] abilityIds;     // Available abilities
        uint256[] weights;        // Probability weights for each ability
        uint256 totalWeight;      // Sum of weights for random selection
    }

    struct LootTable {
        string[] items;           // Possible items
        uint256[] weights;        // Drop weights
        uint256 totalWeight;      // Sum of weights
        uint256 dropChance;       // Chance to drop any item (100 = 1%)
    }

    // Monster ID => Monster details
    mapping(bytes32 => Monster) public monsters;
    
    // Boss fight ID => Fight details
    mapping(bytes32 => BossFight) public bossFights;
    
    // Hunt ID => Hunt details
    mapping(bytes32 => Hunt) public hunts;
    
    // Hunt ID => Character ID => Progress
    mapping(bytes32 => mapping(uint256 => HuntProgress)) public huntProgress;

    // Character ID => Last combat timestamp
    mapping(uint256 => uint256) public lastCombatTime;

    // Combat cooldown period (5 minutes)
    uint256 public constant COMBAT_COOLDOWN = 5 minutes;

    // Monster ID => Monster abilities
    mapping(bytes32 => MonsterAbility) public monsterAbilities;
    
    // Monster ID => Loot table
    mapping(bytes32 => LootTable) public lootTables;

    event MonsterCreated(bytes32 indexed id, string name, bool isBoss);
    event BossFightStarted(bytes32 indexed fightId, bytes32 indexed monsterId, uint256 startTime);
    event BossDamageDealt(bytes32 indexed fightId, uint256 indexed characterId, uint256 damage);
    event BossDefeated(bytes32 indexed fightId, uint256 totalDamage, uint256 participants);
    event HuntCreated(bytes32 indexed id, bytes32 indexed monsterId, uint256 count);
    event HuntStarted(bytes32 indexed huntId, uint256 indexed characterId);
    event MonsterSlain(bytes32 indexed huntId, uint256 indexed characterId, uint256 reward);
    event HuntCompleted(bytes32 indexed huntId, uint256 indexed characterId, uint256 totalReward);
    event AbilityUsed(bytes32 indexed monsterId, bytes32 indexed abilityId, uint256 indexed targetId);
    event LootDropped(bytes32 indexed monsterId, uint256 indexed characterId, string item);

    constructor(
        address _character,
        address _gameToken,
        address _abilities
    ) Ownable(msg.sender) {
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        abilities = CombatAbilities(_abilities);
    }

    /// @notice Create a new monster
    function createMonster(
        string calldata name,
        uint256 level,
        uint256 health,
        uint256 damage,
        uint256 defense,
        uint256 rewardBase,
        bool isBoss,
        string[] calldata requiredItems
    ) external onlyOwner returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(name, level, block.timestamp));
        
        monsters[id] = Monster({
            name: name,
            level: level,
            health: health,
            damage: damage,
            defense: defense,
            rewardBase: rewardBase,
            isBoss: isBoss,
            requiredItems: requiredItems,
            active: true
        });

        emit MonsterCreated(id, name, isBoss);
        return id;
    }

    /// @notice Start a new boss fight
    function startBossFight(
        bytes32 monsterId,
        uint256 duration
    ) external onlyOwner returns (bytes32) {
        Monster storage monster = monsters[monsterId];
        require(monster.active && monster.isBoss, "Not an active boss");
        
        bytes32 fightId = keccak256(abi.encodePacked(monsterId, block.timestamp));
        BossFight storage fight = bossFights[fightId];
        
        fight.monsterId = monsterId;
        fight.startTime = block.timestamp;
        fight.duration = duration;
        
        emit BossFightStarted(fightId, monsterId, block.timestamp);
        return fightId;
    }

    /// @notice Attack a boss
    function attackBoss(
        bytes32 fightId,
        uint256 characterId,
        uint256 damage,
        bytes32 abilityId
    ) external nonReentrant {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        require(canFight(characterId), "Combat on cooldown");
        
        BossFight storage fight = bossFights[fightId];
        Monster storage boss = monsters[fight.monsterId];
        
        require(boss.active, "Boss not active");
        require(
            block.timestamp >= fight.startTime &&
            block.timestamp <= fight.startTime + fight.duration,
            "Fight not active"
        );
        require(!fight.defeated, "Boss already defeated");

        // Apply ability effects if used
        if (abilityId != bytes32(0)) {
            damage = applyAbilityEffects(abilityId, damage, characterId, uint256(fight.monsterId));
        }

        // Record damage and update fight status
        if (fight.damageDealt[characterId] == 0) {
            fight.participants++;
        }
        
        fight.damageDealt[characterId] += damage;
        fight.totalDamage += damage;
        lastCombatTime[characterId] = block.timestamp;

        emit BossDamageDealt(fightId, characterId, damage);

        // Boss counter-attack with random ability
        useRandomBossAbility(fight.monsterId, characterId);

        // Check if boss is defeated
        if (fight.totalDamage >= boss.health) {
            defeatBoss(fightId);
        }
    }

    /// @notice Handle boss defeat and reward distribution
    function defeatBoss(bytes32 fightId) internal {
        BossFight storage fight = bossFights[fightId];
        Monster storage boss = monsters[fight.monsterId];
        
        // Calculate rewards based on participation
        uint256 totalReward = boss.rewardBase * (100 + fight.participants) / 100;
        
        // Distribute rewards proportionally to damage dealt
        for (uint256 i = 0; i < fight.participants; i++) {
            uint256 characterId = uint256(keccak256(abi.encodePacked(fightId, i)));
            if (fight.damageDealt[characterId] > 0) {
                uint256 share = (fight.damageDealt[characterId] * totalReward) / fight.totalDamage;
                gameToken.mint(character.ownerOf(characterId), share);
            }
        }

        fight.defeated = true;
        emit BossDefeated(fightId, fight.totalDamage, fight.participants);
    }

    /// @notice Create a monster hunt quest
    function createHunt(
        bytes32 monsterId,
        uint256 count,
        uint256 timeLimit,
        uint256 bonusReward
    ) external onlyOwner returns (bytes32) {
        Monster storage monster = monsters[monsterId];
        require(monster.active && !monster.isBoss, "Invalid monster");
        
        bytes32 huntId = keccak256(abi.encodePacked(monsterId, count, block.timestamp));
        
        hunts[huntId] = Hunt({
            monsterId: monsterId,
            count: count,
            timeLimit: timeLimit,
            bonusReward: bonusReward,
            active: true
        });

        emit HuntCreated(huntId, monsterId, count);
        return huntId;
    }

    /// @notice Start a hunt
    function startHunt(bytes32 huntId, uint256 characterId) external nonReentrant {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        
        Hunt storage hunt = hunts[huntId];
        require(hunt.active, "Hunt not active");
        
        HuntProgress storage progress = huntProgress[huntId][characterId];
        require(progress.startTime == 0, "Hunt already started");

        progress.startTime = block.timestamp;
        emit HuntStarted(huntId, characterId);
    }

    /// @notice Record a monster kill for a hunt
    function recordKill(
        bytes32 huntId,
        uint256 characterId
    ) external {
        require(msg.sender == owner() || approvedTrackers[msg.sender], "Not authorized");
        require(canFight(characterId), "Combat on cooldown");
        
        Hunt storage hunt = hunts[huntId];
        require(hunt.active, "Hunt not active");
        
        HuntProgress storage progress = huntProgress[huntId][characterId];
        require(progress.startTime > 0, "Hunt not started");
        require(
            block.timestamp <= progress.startTime + hunt.timeLimit,
            "Hunt expired"
        );

        Monster storage monster = monsters[hunt.monsterId];
        progress.monstersSlain++;
        lastCombatTime[characterId] = block.timestamp;

        // Grant base reward for kill
        uint256 reward = monster.rewardBase;
        gameToken.mint(character.ownerOf(characterId), reward);
        
        emit MonsterSlain(huntId, characterId, reward);

        // Process loot drops
        processLootDrop(hunt.monsterId, characterId);

        // Check for hunt completion
        if (progress.monstersSlain >= hunt.count) {
            completeHunt(huntId, characterId);
        }
    }

    /// @notice Complete a hunt
    function completeHunt(bytes32 huntId, uint256 characterId) internal {
        Hunt storage hunt = hunts[huntId];
        HuntProgress storage progress = huntProgress[huntId][characterId];
        
        // Grant completion bonus
        gameToken.mint(character.ownerOf(characterId), hunt.bonusReward);
        progress.completed = true;
        
        emit HuntCompleted(huntId, characterId, hunt.bonusReward);
    }

    /// @notice Check if character can engage in combat
    function canFight(uint256 characterId) public view returns (bool) {
        return block.timestamp >= lastCombatTime[characterId] + COMBAT_COOLDOWN;
    }

    /// @notice Get hunt progress
    function getHuntProgress(bytes32 huntId, uint256 characterId)
        external
        view
        returns (
            uint256 startTime,
            uint256 monstersSlain,
            bool completed,
            uint256 timeRemaining
        )
    {
        HuntProgress storage progress = huntProgress[huntId][characterId];
        Hunt storage hunt = hunts[huntId];
        
        timeRemaining = progress.startTime > 0 && !progress.completed
            ? Math.max(0, (progress.startTime + hunt.timeLimit) - block.timestamp)
            : 0;

        return (
            progress.startTime,
            progress.monstersSlain,
            progress.completed,
            timeRemaining
        );
    }

    /// @notice Get boss fight progress
    function getBossFightProgress(bytes32 fightId, uint256 characterId)
        external
        view
        returns (
            uint256 totalDamage,
            uint256 characterDamage,
            uint256 participants,
            bool defeated,
            uint256 timeRemaining
        )
    {
        BossFight storage fight = bossFights[fightId];
        
        timeRemaining = !fight.defeated
            ? Math.max(0, (fight.startTime + fight.duration) - block.timestamp)
            : 0;

        return (
            fight.totalDamage,
            fight.damageDealt[characterId],
            fight.participants,
            fight.defeated,
            timeRemaining
        );
    }

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    /// @notice Set approval for progress trackers
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }

    /// @notice Set monster abilities
    function setMonsterAbilities(
        bytes32 monsterId,
        bytes32[] calldata abilityIds,
        uint256[] calldata weights
    ) external onlyOwner {
        require(abilityIds.length == weights.length, "Array length mismatch");
        require(abilityIds.length > 0, "No abilities provided");
        
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        
        monsterAbilities[monsterId] = MonsterAbility({
            abilityIds: abilityIds,
            weights: weights,
            totalWeight: totalWeight
        });
    }

    /// @notice Set monster loot table
    function setLootTable(
        bytes32 monsterId,
        string[] calldata items,
        uint256[] calldata weights,
        uint256 dropChance
    ) external onlyOwner {
        require(items.length == weights.length, "Array length mismatch");
        require(items.length > 0, "No items provided");
        require(dropChance <= 10000, "Invalid drop chance"); // Max 100%
        
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }
        
        lootTables[monsterId] = LootTable({
            items: items,
            weights: weights,
            totalWeight: totalWeight,
            dropChance: dropChance
        });
    }

    /// @notice Apply ability effects to damage
    function applyAbilityEffects(
        bytes32 abilityId,
        uint256 baseDamage,
        uint256 userId,
        uint256 targetId
    ) internal returns (uint256) {
        uint256 effectPower = abilities.useAbility(abilityId, userId, targetId);
        return (baseDamage * effectPower) / 100;
    }

    /// @notice Use a random ability from monster's ability pool
    function useRandomBossAbility(bytes32 monsterId, uint256 targetId) internal {
        MonsterAbility storage monsterAbility = monsterAbilities[monsterId];
        if (monsterAbility.abilityIds.length == 0) return;
        
        // Generate random number for ability selection
        uint256 rand = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            monsterId,
            targetId
        ))) % monsterAbility.totalWeight;
        
        // Select ability based on weights
        uint256 cumulative = 0;
        for (uint256 i = 0; i < monsterAbility.weights.length; i++) {
            cumulative += monsterAbility.weights[i];
            if (rand < cumulative) {
                bytes32 selectedAbility = monsterAbility.abilityIds[i];
                abilities.useAbility(selectedAbility, uint256(monsterId), targetId);
                emit AbilityUsed(monsterId, selectedAbility, targetId);
                break;
            }
        }
    }

    /// @notice Process loot drops for a monster kill
    function processLootDrop(bytes32 monsterId, uint256 characterId) internal {
        LootTable storage loot = lootTables[monsterId];
        if (loot.items.length == 0) return;
        
        // Check if any item drops
        uint256 dropRoll = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            monsterId,
            characterId
        ))) % 10000;
        
        if (dropRoll >= loot.dropChance) return;
        
        // Select item based on weights
        uint256 rand = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            monsterId,
            characterId,
            dropRoll
        ))) % loot.totalWeight;
        
        uint256 cumulative = 0;
        for (uint256 i = 0; i < loot.weights.length; i++) {
            cumulative += loot.weights[i];
            if (rand < cumulative) {
                // Here you would integrate with your item system
                // For now, we just emit an event
                emit LootDropped(monsterId, characterId, loot.items[i]);
                break;
            }
        }
    }
} 