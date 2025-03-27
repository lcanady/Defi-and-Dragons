// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Types.sol";
import "./interfaces/Errors.sol";
import "./CombatAbilities.sol";
import "./ItemDrop.sol";
import "./CombatDamageCalculator.sol";

/// @title CombatQuest
/// @notice Manages combat-based quests including boss fights and monster hunts
contract CombatQuest is Ownable, ReentrancyGuard {
    using Math for uint256;

    ICharacter public immutable character;
    IGameToken public immutable gameToken;
    CombatAbilities public immutable abilities;
    ItemDrop public immutable itemDrop;
    CombatDamageCalculator public immutable damageCalculator;

    // Packed structs for gas optimization
    struct Monster {
        string name;
        uint32 level; // Reduced from uint256
        uint128 health; // Reduced from uint256
        uint32 damage; // Reduced from uint256
        uint32 defense; // Reduced from uint256
        uint32 rewardBase; // Reduced from uint256
        bool isBoss;
        string[] requiredItems;
        bool active;
    }

    struct PackedBossFight {
        bytes32 monsterId;
        uint40 startTime; // Reduced from uint256, good until year 2104
        uint40 duration; // Reduced from uint256
        uint128 totalDamage; // Reduced from uint256
        uint16 participants; // Reduced from uint256, max 65535 participants
        bool defeated;
        uint256[] participantIds;
    }

    struct PackedHunt {
        bytes32 monsterId;
        uint32 count; // Reduced from uint256
        uint40 timeLimit; // Reduced from uint256
        uint32 bonusReward; // Reduced from uint256
        bool active;
    }

    struct PackedHuntProgress {
        uint40 startTime; // Reduced from uint256
        uint32 monstersSlain; // Reduced from uint256
        bool completed;
    }

    struct MonsterAbility {
        bytes32[] abilityIds;
        uint32[] weights; // Reduced from uint256
        uint32 totalWeight; // Reduced from uint256
    }

    struct LootTable {
        uint256[] itemIds;
        uint32[] weights; // Reduced from uint256
        uint32 totalWeight; // Reduced from uint256
        uint16 dropChance; // Reduced from uint256 (100 = 1%)
        uint16 dropRateBonus; // Reduced from uint256 (100 = 1%)
    }

    // State variables
    mapping(bytes32 => Monster) public monsters;
    mapping(bytes32 => PackedBossFight) public bossFights;
    mapping(bytes32 => mapping(uint256 => uint128)) public damageDealt; // Separate mapping for boss fight damage
    mapping(bytes32 => PackedHunt) public hunts;
    mapping(bytes32 => mapping(uint256 => PackedHuntProgress)) public huntProgress;
    mapping(uint256 => uint40) public lastCombatTime; // Reduced from uint256
    mapping(bytes32 => MonsterAbility) public monsterAbilities;
    mapping(bytes32 => LootTable) public lootTables;

    // Constants
    uint40 public constant COMBAT_COOLDOWN = 5 minutes;

    // Events
    event MonsterCreated(bytes32 indexed id, string name, bool isBoss);
    event BossFightStarted(bytes32 indexed fightId, bytes32 indexed monsterId, uint40 startTime);
    event BossDamageDealt(bytes32 indexed fightId, uint256 indexed characterId, uint128 damage);
    event BossDefeated(bytes32 indexed fightId, uint128 totalDamage, uint16 participants);
    event HuntCreated(bytes32 indexed id, bytes32 indexed monsterId, uint32 count);
    event HuntStarted(bytes32 indexed huntId, uint256 indexed characterId);
    event MonsterSlain(bytes32 indexed huntId, uint256 indexed characterId, uint32 reward);
    event HuntCompleted(bytes32 indexed huntId, uint256 indexed characterId, uint32 totalReward);
    event AbilityUsed(bytes32 indexed monsterId, bytes32 indexed abilityId, uint256 indexed targetId);
    event LootDropped(bytes32 indexed monsterId, uint256 indexed characterId, uint256 itemId);
    event MonsterToggled(bytes32 indexed monsterId, bool active);

    constructor(
        address initialOwner,
        address _character,
        address _gameToken,
        address _abilities,
        address _itemDrop,
        address _damageCalculator
    ) Ownable() {
        _transferOwnership(initialOwner);
        character = ICharacter(_character);
        gameToken = IGameToken(_gameToken);
        abilities = CombatAbilities(_abilities);
        itemDrop = ItemDrop(_itemDrop);
        damageCalculator = CombatDamageCalculator(_damageCalculator);
    }

    /// @notice Create a new monster
    function createMonster(
        string calldata name,
        uint32 level,
        uint128 health,
        uint32 damage,
        uint32 defense,
        uint32 rewardBase,
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
    function startBossFight(bytes32 monsterId, uint40 duration) external returns (bytes32) {
        Monster storage monster = monsters[monsterId];
        if (!monster.active || !monster.isBoss) revert NotActiveBoss();

        // Check required items first
        uint256 itemCount = monster.requiredItems.length;
        unchecked {
            for (uint256 i; i < itemCount; ++i) {
                if (!hasRequiredItem(msg.sender, monster.requiredItems[i])) {
                    revert MissingRequiredItem();
                }
            }
        }

        if (owner() != msg.sender) revert NotOwner();

        bytes32 fightId = keccak256(abi.encodePacked(monsterId, block.timestamp));

        bossFights[fightId] = PackedBossFight({
            monsterId: monsterId,
            startTime: uint40(block.timestamp),
            duration: duration,
            totalDamage: 0,
            participants: 0,
            defeated: false,
            participantIds: new uint256[](0)
        });

        emit BossFightStarted(fightId, monsterId, uint40(block.timestamp));
        return fightId;
    }

    /// @notice Check if a player has a required item
    function hasRequiredItem(address, /*player*/ string memory /*itemName*/ ) internal pure returns (bool) {
        // TODO: Implement item checking logic
        return false;
    }

    /// @notice Attack a boss
    function attackBoss(bytes32 fightId, uint256 characterId, bytes32 abilityId) external nonReentrant {
        if (character.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();
        if (!canFight(characterId)) revert CombatOnCooldown();

        PackedBossFight storage fight = bossFights[fightId];
        Monster storage boss = monsters[fight.monsterId];

        if (!boss.active) revert NotActiveBoss();
        if (block.timestamp < fight.startTime || block.timestamp > fight.startTime + fight.duration) {
            revert FightNotActive();
        }
        if (fight.defeated) revert BossAlreadyDefeated();

        // Calculate base damage using character stats
        uint128 damage = uint128(damageCalculator.calculateDamage(characterId, uint256(fight.monsterId)));

        // Apply ability effects if used
        if (abilityId != bytes32(0)) {
            damage = uint128(applyAbilityEffects(abilityId, uint256(damage), characterId, uint256(fight.monsterId)));
        }

        // Record damage and update fight status
        uint128 previousDamage = damageDealt[fightId][characterId];
        if (previousDamage == 0) {
            unchecked {
                ++fight.participants;
            }
            fight.participantIds.push(characterId);
        }

        damageDealt[fightId][characterId] = previousDamage + damage;
        fight.totalDamage += damage;
        lastCombatTime[characterId] = uint40(block.timestamp);

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
        PackedBossFight storage fight = bossFights[fightId];
        Monster storage boss = monsters[fight.monsterId];

        // Calculate rewards based on participation
        uint256 totalReward;
        unchecked {
            totalReward = uint256(boss.rewardBase) * (100 + fight.participants) / 100;
        }

        // Distribute rewards proportionally to damage dealt
        uint256[] memory participants = fight.participantIds;
        uint256 participantCount = participants.length;

        unchecked {
            for (uint256 i; i < participantCount; ++i) {
                uint256 characterId = participants[i];
                uint128 charDamage = damageDealt[fightId][characterId];
                if (charDamage > 0) {
                    address player = character.ownerOf(characterId);
                    uint256 share = (uint256(charDamage) * totalReward) / fight.totalDamage;
                    gameToken.mint(player, share);

                    // Handle item drops for each participant
                    handleLootDrop(fight.monsterId, characterId);
                }
            }
        }

        fight.defeated = true;
        emit BossDefeated(fightId, fight.totalDamage, fight.participants);
    }

    /// @notice Check if a character can fight
    function canFight(uint256 characterId) public view returns (bool) {
        return block.timestamp >= lastCombatTime[characterId] + COMBAT_COOLDOWN;
    }

    /// @notice Handle loot drops for a character
    function handleLootDrop(bytes32 monsterId, uint256 /*characterId*/ ) internal view {
        LootTable storage lootTable = lootTables[monsterId];
        if (lootTable.itemIds.length == 0) return;

        // TODO: Implement loot drop logic
    }

    /// @notice Create a monster hunt quest
    function createHunt(bytes32 monsterId, uint256 count, uint256 timeLimit, uint256 bonusReward)
        external
        onlyOwner
        returns (bytes32)
    {
        Monster storage monster = monsters[monsterId];
        require(monster.active && !monster.isBoss, "Invalid monster");

        bytes32 huntId = keccak256(abi.encodePacked(monsterId, count, block.timestamp));

        hunts[huntId] = PackedHunt({
            monsterId: monsterId,
            count: uint32(count),
            timeLimit: uint40(timeLimit),
            bonusReward: uint32(bonusReward),
            active: true
        });

        emit HuntCreated(huntId, monsterId, uint32(count));
        return huntId;
    }

    /// @notice Start a hunt
    function startHunt(bytes32 huntId, uint256 characterId) external nonReentrant {
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");

        PackedHunt storage hunt = hunts[huntId];
        require(hunt.active, "Hunt not active");

        PackedHuntProgress storage progress = huntProgress[huntId][characterId];
        require(progress.startTime == 0, "Hunt already started");

        progress.startTime = uint40(block.timestamp);
        emit HuntStarted(huntId, characterId);
    }

    /// @notice Record a monster kill for a hunt
    function recordKill(bytes32 huntId, uint256 characterId) external {
        require(msg.sender == owner() || approvedTrackers[msg.sender], "Not authorized");
        require(canFight(characterId), "Combat on cooldown");

        PackedHunt storage hunt = hunts[huntId];
        require(hunt.active, "Hunt not active");

        PackedHuntProgress storage progress = huntProgress[huntId][characterId];
        require(progress.startTime > 0, "Hunt not started");
        require(block.timestamp <= progress.startTime + hunt.timeLimit, "Hunt expired");

        Monster storage monster = monsters[hunt.monsterId];
        progress.monstersSlain++;
        lastCombatTime[characterId] = uint40(block.timestamp);

        // Grant base reward for kill
        uint256 reward = monster.rewardBase;
        gameToken.mint(character.ownerOf(characterId), reward);

        emit MonsterSlain(huntId, characterId, uint32(reward));

        // Process loot drops
        processLootDrop(hunt.monsterId, characterId);

        // Check for hunt completion
        if (progress.monstersSlain >= hunt.count) {
            completeHunt(huntId, characterId);
        }
    }

    /// @notice Complete a hunt
    function completeHunt(bytes32 huntId, uint256 characterId) internal {
        PackedHunt storage hunt = hunts[huntId];
        PackedHuntProgress storage progress = huntProgress[huntId][characterId];

        // Grant completion bonus
        gameToken.mint(character.ownerOf(characterId), hunt.bonusReward);
        progress.completed = true;

        emit HuntCompleted(huntId, characterId, hunt.bonusReward);
    }

    /// @notice Get hunt progress
    function getHuntProgress(bytes32 huntId, uint256 characterId)
        external
        view
        returns (uint256 startTime, uint256 monstersSlain, bool completed, uint256 timeRemaining)
    {
        PackedHuntProgress storage progress = huntProgress[huntId][characterId];
        PackedHunt storage hunt = hunts[huntId];

        timeRemaining = progress.startTime > 0 && !progress.completed
            ? Math.max(0, (progress.startTime + hunt.timeLimit) - block.timestamp)
            : 0;

        return (progress.startTime, progress.monstersSlain, progress.completed, timeRemaining);
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
        PackedBossFight storage fight = bossFights[fightId];

        timeRemaining = !fight.defeated ? Math.max(0, (fight.startTime + fight.duration) - block.timestamp) : 0;

        return (fight.totalDamage, damageDealt[fightId][characterId], fight.participants, fight.defeated, timeRemaining);
    }

    // Approved addresses that can record progress
    mapping(address => bool) public approvedTrackers;

    /// @notice Set approval for progress trackers
    function setTrackerApproval(address tracker, bool approved) external onlyOwner {
        approvedTrackers[tracker] = approved;
    }

    /// @notice Set monster abilities and their weights
    function setMonsterAbilities(
        bytes32 monsterId,
        bytes32[] calldata abilityIds,
        uint32[] calldata weights, // Changed parameter type to match struct
        uint32 totalWeight // Changed parameter type to match struct
    ) external onlyOwner {
        require(monsters[monsterId].active, "Monster not active");
        require(abilityIds.length == weights.length, "Array length mismatch");

        monsterAbilities[monsterId] =
            MonsterAbility({ abilityIds: abilityIds, weights: weights, totalWeight: totalWeight });
    }

    /// @notice Set loot table for a monster
    function setLootTable(
        bytes32 monsterId,
        uint256[] calldata itemIds,
        uint32[] calldata weights, // Changed parameter type to match struct
        uint32 totalWeight, // Changed parameter type to match struct
        uint16 dropChance, // Changed parameter type to match struct
        uint16 dropRateBonus // Changed parameter type to match struct
    ) external onlyOwner {
        require(monsters[monsterId].active, "Monster not active");
        require(itemIds.length == weights.length, "Array length mismatch");

        lootTables[monsterId] = LootTable({
            itemIds: itemIds,
            weights: weights,
            totalWeight: totalWeight,
            dropChance: dropChance,
            dropRateBonus: dropRateBonus
        });
    }

    /// @notice Apply ability effects to damage
    function applyAbilityEffects(bytes32 abilityId, uint256 baseDamage, uint256 userId, uint256 targetId)
        internal
        returns (uint256)
    {
        uint256 effectPower = abilities.useAbility(abilityId, userId, targetId);
        return (baseDamage * effectPower) / 100;
    }

    /// @notice Use a random ability from monster's ability pool
    function useRandomBossAbility(bytes32 monsterId, uint256 targetId) internal {
        MonsterAbility storage monsterAbility = monsterAbilities[monsterId];
        if (monsterAbility.abilityIds.length == 0) return;

        // Generate random number for ability selection
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, monsterId, targetId)))
            % monsterAbility.totalWeight;

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
        if (loot.itemIds.length == 0) return;

        // Request random drop through ItemDrop contract
        address player = character.ownerOf(characterId);
        uint256 requestId = itemDrop.requestRandomDrop(player, loot.dropRateBonus);

        // Check if any item drops
        uint256 dropRoll =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, characterId, requestId))) % 10_000;

        if (dropRoll >= loot.dropChance) return;

        // Select item based on weights
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, characterId, requestId)))
            % loot.totalWeight;

        uint256 cumulative = 0;
        for (uint256 i = 0; i < loot.weights.length; i++) {
            cumulative += loot.weights[i];
            if (rand < cumulative) {
                // Request a random drop for the selected item
                itemDrop.requestRandomDrop(player, loot.dropRateBonus);
                emit LootDropped(monsterId, characterId, loot.itemIds[i]);
                break;
            }
        }
    }

    function toggleMonster(bytes32 monsterId, bool active) external onlyOwner {
        Monster storage monster = monsters[monsterId];
        require(monster.level > 0, "Monster does not exist");
        monster.active = active;
        emit MonsterToggled(monsterId, active);
    }

    /// @notice Get loot table for a monster
    function getLootTable(bytes32 monsterId)
        external
        view
        returns (
            uint256[] memory itemIds,
            uint256[] memory weights, // Keep return type as uint256[] for compatibility
            uint256 dropChance, // Keep return type as uint256 for compatibility
            uint256 dropRateBonus // Keep return type as uint256 for compatibility
        )
    {
        LootTable storage table = lootTables[monsterId];

        // Convert uint32[] to uint256[] for weights
        uint256[] memory convertedWeights = new uint256[](table.weights.length);
        for (uint256 i = 0; i < table.weights.length; i++) {
            convertedWeights[i] = table.weights[i];
        }

        return (table.itemIds, convertedWeights, table.dropChance, table.dropRateBonus);
    }
}
