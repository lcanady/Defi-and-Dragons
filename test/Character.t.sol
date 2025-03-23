// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/ProvableRandom.sol";
import "../src/interfaces/Types.sol";

contract CharacterTest is Test {
    Character character;
    Equipment equipment;
    ProvableRandom random;
    address user = address(1);
    address owner = address(0);

    event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, Types.Stats stats);
    event StateUpdated(uint256 indexed tokenId, Types.CharacterState state);

    function setUp() public {
        vm.clearMockedCalls();
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));
        vm.label(address(character), "Character");
        vm.label(address(equipment), "Equipment");
        vm.label(address(random), "Random");

        // Grant MINTER_ROLE to owner for equipment tests
        equipment.grantRole(equipment.MINTER_ROLE(), address(this));
    }

    function validateStats(Types.Stats memory stats) internal view {
        // Check individual stats are within bounds
        assertGe(stats.strength, character.MIN_STAT(), "Strength below minimum");
        assertLe(stats.strength, character.MAX_STAT(), "Strength above maximum");
        assertGe(stats.agility, character.MIN_STAT(), "Agility below minimum");
        assertLe(stats.agility, character.MAX_STAT(), "Agility above maximum");
        assertGe(stats.magic, character.MIN_STAT(), "Magic below minimum");
        assertLe(stats.magic, character.MAX_STAT(), "Magic above maximum");

        // Check total points (allow for small rounding differences)
        uint256 total = stats.strength + stats.agility + stats.magic;
        assertApproxEqAbs(total, character.TOTAL_POINTS(), 1, "Total points not within acceptable range");
    }

    function testMintCharacter() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        
        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        validateStats(stats);
        
        assertEq(character.ownerOf(tokenId), user);
        vm.stopPrank();
    }

    function testMintCharacterAlignment() public {
        vm.clearMockedCalls();
        vm.startPrank(user);
        random.initializeSeed(keccak256(abi.encodePacked(block.timestamp, user, uint256(1))));

        // Mock initial stats that will allow room for alignment bonuses
        // Using different values to avoid proportional scaling
        // TOTAL_POINTS = 45, so we start with a lower total
        uint256[] memory stats = new uint256[](3);
        stats[0] = 8;  // Strength
        stats[1] = 7;  // Agility
        stats[2] = 6;  // Magic
        // Total = 21, leaving 24 points to distribute (TOTAL_POINTS = 45)

        emit log_named_uint("Initial Total", stats[0] + stats[1] + stats[2]);

        // Test STRENGTH alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(stats)
        );
        uint256 strengthCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        
        // Change values for AGILITY character to avoid any caching
        stats[0] = 7;  // Strength
        stats[1] = 8;  // Agility
        stats[2] = 6;  // Magic

        vm.clearMockedCalls();
        // Test AGILITY alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(stats)
        );
        uint256 agilityCharId = character.mintCharacter(user, Types.Alignment.AGILITY);
        
        // Change values for MAGIC character
        stats[0] = 6;  // Strength
        stats[1] = 7;  // Agility
        stats[2] = 8;  // Magic

        vm.clearMockedCalls();
        // Test MAGIC alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(stats)
        );
        uint256 magicCharId = character.mintCharacter(user, Types.Alignment.MAGIC);
        
        vm.stopPrank();

        // Get character stats
        (Types.Stats memory strengthChar,,) = character.getCharacter(strengthCharId);
        (Types.Stats memory agilityChar,,) = character.getCharacter(agilityCharId);
        (Types.Stats memory magicChar,,) = character.getCharacter(magicCharId);

        // Log stats for debugging
        emit log_string("STRENGTH Character Stats:");
        emit log_named_uint("Strength", strengthChar.strength);
        emit log_named_uint("Agility", strengthChar.agility);
        emit log_named_uint("Magic", strengthChar.magic);
        emit log_named_uint("Total", strengthChar.strength + strengthChar.agility + strengthChar.magic);

        emit log_string("AGILITY Character Stats:");
        emit log_named_uint("Strength", agilityChar.strength);
        emit log_named_uint("Agility", agilityChar.agility);
        emit log_named_uint("Magic", agilityChar.magic);
        emit log_named_uint("Total", agilityChar.strength + agilityChar.agility + agilityChar.magic);

        emit log_string("MAGIC Character Stats:");
        emit log_named_uint("Strength", magicChar.strength);
        emit log_named_uint("Agility", magicChar.agility);
        emit log_named_uint("Magic", magicChar.magic);
        emit log_named_uint("Total", magicChar.strength + magicChar.magic + magicChar.agility);

        // Verify each character's primary stat is at MAX_STAT
        assertEq(strengthChar.strength, character.MAX_STAT(), "STRENGTH character should have max strength");
        assertEq(agilityChar.agility, character.MAX_STAT(), "AGILITY character should have max agility");
        assertEq(magicChar.magic, character.MAX_STAT(), "MAGIC character should have max magic");

        // Verify total points are correct
        assertEq(
            strengthChar.strength + strengthChar.agility + strengthChar.magic,
            character.TOTAL_POINTS(),
            "STRENGTH character total points should equal TOTAL_POINTS"
        );
        assertEq(
            agilityChar.strength + agilityChar.agility + agilityChar.magic,
            character.TOTAL_POINTS(),
            "AGILITY character total points should equal TOTAL_POINTS"
        );
        assertEq(
            magicChar.strength + magicChar.agility + magicChar.magic,
            character.TOTAL_POINTS(),
            "MAGIC character total points should equal TOTAL_POINTS"
        );
    }

    function testGetCharacter() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        
        (Types.Stats memory stats, Types.EquipmentSlots memory slots, Types.CharacterState memory state) = 
            character.getCharacter(tokenId);
            
        validateStats(stats);
        assertEq(slots.weaponId, 0);
        assertEq(slots.armorId, 0);
        assertEq(uint256(state.alignment), uint256(Types.Alignment.STRENGTH));
        vm.stopPrank();
    }

    function testEquipItems() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();
        
        // Create and mint equipment first
        uint256 weaponId = equipment.createEquipment("Test Weapon", "A test weapon", 100, 0, 0);
        uint256 armorId = equipment.createEquipment("Test Armor", "A test armor", 0, 100, 0);
        equipment.mint(user, weaponId, 1, "");
        equipment.mint(user, armorId, 1, "");
        
        vm.startPrank(user);
        // Approve equipment for character wallet
        address wallet = address(character.characterWallets(tokenId));
        equipment.setApprovalForAll(wallet, true);

        // Transfer equipment to character wallet
        equipment.safeTransferFrom(user, wallet, weaponId, 1, "");
        equipment.safeTransferFrom(user, wallet, armorId, 1, "");

        // Expect the EquipmentChanged event with correct parameters
        vm.expectEmit(true, true, true, true);
        emit EquipmentChanged(tokenId, weaponId, armorId);
        character.equip(tokenId, weaponId, armorId);

        (,Types.EquipmentSlots memory equippedItems,) = character.getCharacter(tokenId);
        assertEq(equippedItems.weaponId, weaponId);
        assertEq(equippedItems.armorId, armorId);
        vm.stopPrank();
    }

    function testUnequipItems() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();
        
        // Create and mint equipment first
        uint256 weaponId = equipment.createEquipment("Test Weapon", "A test weapon", 100, 0, 0);
        uint256 armorId = equipment.createEquipment("Test Armor", "A test armor", 0, 100, 0);
        equipment.mint(user, weaponId, 1, "");
        equipment.mint(user, armorId, 1, "");
        
        vm.startPrank(user);
        // Approve equipment for character wallet
        address wallet = address(character.characterWallets(tokenId));
        equipment.setApprovalForAll(wallet, true);

        // Transfer equipment to character wallet
        equipment.safeTransferFrom(user, wallet, weaponId, 1, "");
        equipment.safeTransferFrom(user, wallet, armorId, 1, "");

        // Equip items first
        character.equip(tokenId, weaponId, armorId);

        // Unequip items and verify the event
        vm.expectEmit(true, true, true, true, address(character));
        emit EquipmentChanged(tokenId, 0, 0);
        character.unequip(tokenId, true, true);

        // Verify equipment is unequipped
        (,Types.EquipmentSlots memory equippedItems,) = character.getCharacter(tokenId);
        assertEq(equippedItems.weaponId, 0);
        assertEq(equippedItems.armorId, 0);
        vm.stopPrank();
    }

    function testUpdateStats() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        Types.Stats memory newStats = Types.Stats({
            strength: 15,
            agility: 12,
            magic: 8
        });

        vm.prank(address(this));
        vm.expectEmit(true, false, false, true);
        emit StatsUpdated(tokenId, newStats);
        character.updateStats(tokenId, newStats);

        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        assertEq(stats.strength, newStats.strength);
        assertEq(stats.agility, newStats.agility);
        assertEq(stats.magic, newStats.magic);
    }

    function testUpdateState() public {
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        Types.CharacterState memory newState = Types.CharacterState({
            health: 90,
            consecutiveHits: 2,
            damageReceived: 10,
            roundsParticipated: 1,
            alignment: Types.Alignment.STRENGTH,
            level: 2
        });

        vm.prank(address(this));
        vm.expectEmit(true, false, false, true);
        emit StateUpdated(tokenId, newState);
        character.updateState(tokenId, newState);

        (,,Types.CharacterState memory state) = character.getCharacter(tokenId);
        assertEq(state.health, newState.health);
        assertEq(state.consecutiveHits, newState.consecutiveHits);
        assertEq(state.damageReceived, newState.damageReceived);
        assertEq(state.roundsParticipated, newState.roundsParticipated);
        assertEq(uint256(state.alignment), uint256(newState.alignment));
        assertEq(state.level, newState.level);
    }

    function testFailMintToZeroAddress() public {
        character.mintCharacter(address(0), Types.Alignment.STRENGTH);
    }

    function testFailEquipUnownedCharacter() public {
        address otherUser = makeAddr("otherUser");
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        vm.prank(otherUser);
        character.equip(tokenId, 1, 2);
    }

    function testFailUnequipUnownedCharacter() public {
        address otherUser = makeAddr("otherUser");
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        vm.prank(otherUser);
        character.unequip(tokenId, true, true);
    }

    function testFailGetNonexistentCharacter() public view {
        character.getCharacter(999);
    }

    function testFailUpdateStatsNonexistentCharacter() public {
        Types.Stats memory newStats = Types.Stats({
            strength: 15,
            agility: 12,
            magic: 8
        });
        character.updateStats(999, newStats);
    }

    function testFailUpdateStateNonexistentCharacter() public {
        Types.CharacterState memory newState = Types.CharacterState({
            health: 90,
            consecutiveHits: 2,
            damageReceived: 10,
            roundsParticipated: 1,
            alignment: Types.Alignment.STRENGTH,
            level: 2
        });
        character.updateState(999, newState);
    }
}
