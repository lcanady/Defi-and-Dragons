// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";
import "../src/GameToken.sol";
import "../src/Equipment.sol";
import "../src/ItemDrop.sol";
import "../src/CombatQuest.sol";
import "../src/CombatAbilities.sol";
import "../src/interfaces/Types.sol";
import "../src/ProvableRandom.sol";

contract CombatQuestTest is Test {
    Character public character;
    GameToken public gameToken;
    Equipment public equipment;
    ItemDrop public itemDrop;
    CombatQuest public combatQuest;
    CombatAbilities public abilities;
    ProvableRandom public random;

    address public owner;
    address public user;
    uint256 public characterId;
    bytes32 public monsterId;
    bytes32 public bossId;
    uint256 public weaponId;

    event MonsterCreated(bytes32 indexed id, string name, bool isBoss);
    event BossFightStarted(bytes32 indexed fightId, bytes32 indexed monsterId, uint256 startTime);
    event BossDamageDealt(bytes32 indexed fightId, uint256 indexed characterId, uint256 damage);
    event BossDefeated(bytes32 indexed fightId, uint256 totalDamage, uint256 participants);
    event MonsterSlain(bytes32 indexed huntId, uint256 indexed characterId, uint256 reward);
    event LootDropped(bytes32 indexed monsterId, uint256 indexed characterId, uint256 itemId);

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);

        // Deploy core contracts
        random = new ProvableRandom();
        equipment = new Equipment();
        itemDrop = new ItemDrop();
        
        // Initialize random seed
        random.initializeSeed(bytes32(uint256(1)));
        
        // Setup equipment
        equipment.transferOwnership(owner);
        equipment.grantRole(equipment.DEFAULT_ADMIN_ROLE(), owner);
        
        // Initialize itemDrop
        itemDrop.initialize(address(equipment));
        itemDrop.transferOwnership(owner);
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
        
        // Setup character
        character = new Character(address(equipment), address(random));
        character.transferOwnership(owner);
        equipment.setCharacterContract(address(character));
        
        // Setup game token
        gameToken = new GameToken();
        gameToken.grantRole(gameToken.DEFAULT_ADMIN_ROLE(), owner);
        gameToken.grantRole(gameToken.MINTER_ROLE(), owner);
        
        // Setup abilities and combat quest
        abilities = new CombatAbilities(owner);
        
        // Deploy CombatQuest with owner as initialOwner
        combatQuest = new CombatQuest(
            address(character),
            address(gameToken),
            address(abilities),
            address(itemDrop),
            owner
        );
        
        // Grant additional roles and permissions
        gameToken.grantRole(gameToken.DEFAULT_ADMIN_ROLE(), address(combatQuest));
        gameToken.grantRole(gameToken.MINTER_ROLE(), address(combatQuest));
        gameToken.setQuestContract(address(combatQuest), true);
        
        // Grant CombatQuest permission to request drops from ItemDrop
        itemDrop.transferOwnership(address(combatQuest));
        
        // Grant Equipment permissions
        equipment.grantRole(equipment.DEFAULT_ADMIN_ROLE(), address(itemDrop));
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
        equipment.grantRole(equipment.DEFAULT_ADMIN_ROLE(), address(combatQuest));
        equipment.grantRole(equipment.MINTER_ROLE(), address(combatQuest));

        // Create initial weapon for testing
        weaponId = equipment.createEquipment(
            "Test Sword",
            "A basic sword for testing",
            5, // strength bonus
            2, // agility bonus
            0  // magic bonus
        );

        // Set up combat quest authorization and create test monsters
        combatQuest.setTrackerApproval(owner, true);

        string[] memory requiredItems = new string[](0);
        monsterId = combatQuest.createMonster(
            "Test Monster",
            1,
            100,
            10,
            5,
            100,
            false,
            requiredItems
        );
        
        bossId = combatQuest.createMonster(
            "Test Boss",
            10,
            1000,
            50,
            20,
            1000,
            true,
            requiredItems
        );

        // Mint initial game tokens for user
        gameToken.mint(user, 1000);
        vm.stopPrank();

        // Create test character
        vm.startPrank(user);
        characterId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();
    }

    function testMonsterHunt() public {
        vm.startPrank(owner);
        bytes32 testMonsterId = combatQuest.createMonster(
            "Test Monster",
            5,
            100,
            50,
            25,
            100,
            false,
            new string[](0)
        );
        bytes32 testHuntId = combatQuest.createHunt(testMonsterId, 5, 1 hours, 500);
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        vm.stopPrank();

        vm.startPrank(user);
        combatQuest.startHunt(testHuntId, characterId);

        // Wait for cooldown to expire
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);

        for (uint i = 0; i < 5; i++) {
            combatQuest.recordKill(testHuntId, characterId);
            if (i < 4) vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);
        }

        (, uint256 monstersSlain, bool completed) = combatQuest.huntProgress(testHuntId, characterId);
        assertEq(monstersSlain, 5);
        assertTrue(completed);
        vm.stopPrank();
    }

    function testBossFight() public {
        vm.startPrank(owner);
        bytes32 testBossId = combatQuest.createMonster(
            "Test Boss",
            10,
            1000,
            100,
            50,
            1000,
            true,
            new string[](0)
        );
        bytes32 testFightId = combatQuest.startBossFight(testBossId, 1 hours);
        vm.stopPrank();

        // Wait for cooldown to expire
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);

        vm.startPrank(user);
        combatQuest.attackBoss(testFightId, characterId, 200, bytes32(0));
        vm.stopPrank();

        (uint256 totalDamage, uint256 characterDamage, uint256 participants, bool defeated, uint256 timeRemaining) = 
            combatQuest.getBossFightProgress(testFightId, characterId);

        assertEq(totalDamage, 200);
        assertEq(characterDamage, 200);
        assertEq(participants, 1);
        assertFalse(defeated);
    }

    function testLootTableSetup() public {
        vm.startPrank(owner);
        // Create new equipment for testing
        uint256 newWeaponId = equipment.createEquipment(
            "Rare Sword",
            "A powerful sword",
            10, // strength bonus
            5,  // agility bonus
            0   // magic bonus
        );

        // Set up new loot table
        uint256[] memory itemIds = new uint256[](2);
        itemIds[0] = weaponId;
        itemIds[1] = newWeaponId;
        
        uint256[] memory weights = new uint256[](2);
        weights[0] = 70;  // 70% chance for basic sword
        weights[1] = 30;  // 30% chance for rare sword

        combatQuest.setLootTable(
            monsterId,
            itemIds,
            weights,
            8000,   // 80% drop chance
            1500    // 15% drop rate bonus
        );

        // Get loot table and verify setup
        (uint256[] memory tableItemIds, uint256[] memory tableWeights, uint256 dropChance, uint256 dropRateBonus) = 
            combatQuest.getLootTable(monsterId);
        
        assertEq(tableItemIds.length, 2, "Should have 2 items");
        assertEq(tableWeights.length, 2, "Should have 2 weights");
        assertEq(dropChance, 8000, "Drop chance should be 8000");
        assertEq(dropRateBonus, 1500, "Drop rate bonus should be 1500");
        assertEq(tableWeights[0], 70, "First weight should be 70");
        assertEq(tableWeights[1], 30, "Second weight should be 30");
        vm.stopPrank();
    }

    function testInvalidLootTableSetup() public {
        vm.startPrank(owner);
        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = weaponId;
        
        uint256[] memory weights = new uint256[](2);
        weights[0] = 100;
        weights[1] = 100;

        // Create single item array for valid tests
        uint256[] memory singleWeight = new uint256[](1);
        singleWeight[0] = 100;

        // Should revert due to array length mismatch
        vm.expectRevert("Array length mismatch");
        combatQuest.setLootTable(
            monsterId,
            itemIds,
            weights,
            8000,
            1500
        );
        vm.stopPrank();
    }

    function testDropRateBonus() public {
        vm.startPrank(owner);
        bytes32 testMonsterId = combatQuest.createMonster(
            "Test Monster",
            5,
            100,
            50,
            25,
            100,
            false,
            new string[](0)
        );

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = weaponId;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 100;

        // Set up loot tables with different drop rate bonuses
        combatQuest.setLootTable(testMonsterId, itemIds, weights, 5000, 0);
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        
        // Create hunt
        bytes32 testHuntId = combatQuest.createHunt(testMonsterId, 1, 1 hours, 0);
        vm.stopPrank();

        vm.startPrank(user);
        combatQuest.startHunt(testHuntId, characterId);
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);
        combatQuest.recordKill(testHuntId, characterId);
        vm.stopPrank();
    }

    function testRequiredItemsForMonster() public {
        vm.startPrank(owner);
        string[] memory requiredItems = new string[](1);
        requiredItems[0] = "Required Item";

        bytes32 testBossId = combatQuest.createMonster(
            "Test Boss",
            10,
            1000,
            100,
            50,
            1000,
            true,
            requiredItems
        );
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("Missing required item");
        combatQuest.startBossFight(testBossId, 1 hours);
        vm.stopPrank();
    }

    function testInvalidMonsterCreation() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        combatQuest.createMonster("Invalid Monster", 1, 100, 50, 25, 100, false, new string[](0));
        vm.stopPrank();
    }

    function testMonsterHuntTimeout() public {
        vm.startPrank(owner);
        bytes32 testMonsterId = combatQuest.createMonster(
            "Test Monster",
            5,
            100,
            50,
            25,
            100,
            false,
            new string[](0)
        );
        bytes32 testHuntId = combatQuest.createHunt(testMonsterId, 5, 1 hours, 500);
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        vm.stopPrank();

        vm.startPrank(user);
        combatQuest.startHunt(testHuntId, characterId);

        // Wait for cooldown to expire
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);

        // Record some kills
        combatQuest.recordKill(testHuntId, characterId);
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);
        combatQuest.recordKill(testHuntId, characterId);

        // Move time past hunt duration
        vm.warp(block.timestamp + 2 hours);

        vm.expectRevert("Hunt expired");
        combatQuest.recordKill(testHuntId, characterId);
        vm.stopPrank();
    }

    function testConcurrentHunts() public {
        vm.startPrank(owner);
        bytes32 testMonsterId = combatQuest.createMonster(
            "Goblin",
            1,
            100,
            10,
            5,
            100,
            false,
            new string[](0)
        );
        bytes32 testMonsterId2 = combatQuest.createMonster(
            "Orc",
            2,
            200,
            20,
            10,
            200,
            false,
            new string[](0)
        );
        bytes32 testHuntId = combatQuest.createHunt(testMonsterId, 2, 3600, 300);
        bytes32 testHuntId2 = combatQuest.createHunt(testMonsterId2, 2, 3600, 400);
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        vm.stopPrank();

        vm.startPrank(user);
        // Start first hunt with existing character
        combatQuest.startHunt(testHuntId, characterId);
        
        // Create second character with a different seed
        bytes32 seed = keccak256(abi.encodePacked(user, block.timestamp));
        random.initializeSeed(seed);
        uint256 characterId2 = character.mintCharacter(user, Types.Alignment.STRENGTH);
        
        // Start second hunt with new character
        combatQuest.startHunt(testHuntId2, characterId2);

        // Verify both hunts are active
        (uint256 startTime1, uint256 monstersSlain1, bool completed1) = combatQuest.huntProgress(testHuntId, characterId);
        (uint256 startTime2, uint256 monstersSlain2, bool completed2) = combatQuest.huntProgress(testHuntId2, characterId2);
        
        assertTrue(startTime1 > 0, "First hunt should be active");
        assertTrue(startTime2 > 0, "Second hunt should be active");
        assertEq(monstersSlain1, 0, "No monsters should be slain yet in first hunt");
        assertEq(monstersSlain2, 0, "No monsters should be slain yet in second hunt");
        assertFalse(completed1, "First hunt should not be completed");
        assertFalse(completed2, "Second hunt should not be completed");
        vm.stopPrank();
    }

    function testMonsterDeactivation() public {
        vm.startPrank(owner);
        // Deactivate monster
        combatQuest.toggleMonster(monsterId, false);

        // Try to create hunt for deactivated monster
        vm.expectRevert("Invalid monster");
        combatQuest.createHunt(
            monsterId,
            5,          // kill 5 monsters
            1 hours,    // time limit
            500        // bonus reward
        );

        // Reactivate monster
        combatQuest.toggleMonster(monsterId, true);

        // Should now be able to create hunt
        bytes32 huntId = combatQuest.createHunt(
            monsterId,
            5,          // kill 5 monsters
            1 hours,    // time limit
            500        // bonus reward
        );

        // Verify hunt was created
        (bytes32 monsterId_, uint256 count, uint256 timeLimit, uint256 bonusReward, bool active) = combatQuest.hunts(huntId);
        assertTrue(active, "Hunt should be active");
        assertEq(count, 5, "Should have correct monster count");
        assertEq(monsterId_, monsterId, "Should have correct monster ID");
        vm.stopPrank();
    }

    function testItemDropIntegration() public {
        vm.startPrank(owner);
        bytes32 testBossId = combatQuest.createMonster(
            "Dragon",
            10,
            1000,
            200,
            50,
            1000,
            true,
            new string[](0)
        );

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = 1;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        
        combatQuest.setLootTable(testBossId, itemIds, weights, 10000, 0);
        bytes32 testFightId = combatQuest.startBossFight(testBossId, 3600);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 initialBalance = equipment.balanceOf(user, 1);
        
        // Wait for cooldown
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);
        
        // Deal enough damage to defeat the boss (1000 health)
        combatQuest.attackBoss(testFightId, characterId, 1000, bytes32(0));
        vm.stopPrank();

        uint256 finalBalance = equipment.balanceOf(user, 1);
        assertEq(finalBalance - initialBalance, 1, "Should have received one weapon");
    }

    function testBossItemDropGuaranteed() public {
        vm.startPrank(owner);
        bytes32 testBossId = combatQuest.createMonster(
            "Test Boss",
            10,
            200,
            100,
            50,
            1000,
            true,
            new string[](0)
        );

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = weaponId;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 100;
        combatQuest.setLootTable(testBossId, itemIds, weights, 10000, 0);
        bytes32 testFightId = combatQuest.startBossFight(testBossId, 1 hours);
        
        // Set tracker approval for user
        combatQuest.setTrackerApproval(user, true);
        vm.stopPrank();

        // Wait for cooldown to expire
        vm.warp(block.timestamp + combatQuest.COMBAT_COOLDOWN() + 1);

        vm.startPrank(user);
        uint256 initialBalance = equipment.balanceOf(user, weaponId);
        combatQuest.attackBoss(testFightId, characterId, 200, bytes32(0));
        vm.stopPrank();

        (uint256 totalDamage, , , bool defeated,) = combatQuest.getBossFightProgress(testFightId, characterId);
        assertTrue(defeated);
        
        uint256 finalBalance = equipment.balanceOf(user, weaponId);
        assertEq(finalBalance, initialBalance + 1, "Should have received one weapon");
    }

    function testInvalidItemDropSetup() public {
        vm.startPrank(owner);
        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = 999999; // Non-existent item ID
        
        uint256[] memory weights = new uint256[](2);
        weights[0] = 100;
        weights[1] = 100;

        // Create single item array for valid tests
        uint256[] memory singleWeight = new uint256[](1);
        singleWeight[0] = 100;

        // Should revert due to array length mismatch
        vm.expectRevert("Array length mismatch");
        combatQuest.setLootTable(
            monsterId,
            itemIds,
            weights,
            5000,
            1000
        );

        // Should revert due to invalid drop chance
        vm.expectRevert("Invalid drop chance");
        combatQuest.setLootTable(
            monsterId,
            itemIds,
            singleWeight,
            15000, // > 100%
            1000
        );

        // Should revert due to invalid drop rate bonus
        vm.expectRevert("Invalid drop rate bonus");
        combatQuest.setLootTable(
            monsterId,
            itemIds,
            singleWeight,
            5000,
            15000 // > 100%
        );
        vm.stopPrank();
    }
} 