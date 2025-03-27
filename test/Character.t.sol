// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import "../src/ProvableRandom.sol";
import { Types } from "../src/interfaces/Types.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract CharacterTest is Test {
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;
    address public owner;
    address public user;
    uint256 public characterId;
    bytes32 public context;

    event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, Types.Stats stats);
    event StateUpdated(uint256 indexed tokenId, Types.CharacterState state);

    // Add IERC721Receiver implementation
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        owner = address(this);
        user = address(0x1);

        // Deploy contracts
        random = new ProvableRandom();
        equipment = new Equipment(address(this));
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));

        // Set context for all operations
        context = bytes32(uint256(uint160(address(character))));

        // Reset random seed for owner
        random.resetSeed(owner, context);
        random.initializeSeed(owner, context);

        // Create test character for user
        vm.startPrank(user);
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        // Mock the random number generation
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 21; // Will result in 12 strength after scaling
        numbers[1] = 21; // Will result in 12 agility after scaling
        numbers[2] = 21; // Will result in 12 magic after scaling
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(numbers)
        );
        characterId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();
    }

    // Add function to reset random seed
    function resetRandomSeed() internal {
        // Reset seeds
        random.resetSeed(msg.sender, context);
        random.resetSeed(user, context);
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
        // Reset seeds
        random.resetSeed(msg.sender, context);
        random.initializeSeed(msg.sender, context);
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        // Mock random number generation
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 10;
        numbers[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(numbers)
        );

        // Test minting
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        assertEq(character.ownerOf(tokenId), user);
    }

    function testMintCharacterAlignment() public {
        resetRandomSeed();
        vm.clearMockedCalls();
        vm.startPrank(user);

        // Mock initial stats that will allow room for alignment bonuses
        // Using different values to avoid proportional scaling
        // TOTAL_POINTS = 45, so we start with a lower total
        uint256[] memory stats = new uint256[](3);
        stats[0] = 8; // Strength
        stats[1] = 7; // Agility
        stats[2] = 6; // Magic
        // Total = 21, leaving 24 points to distribute (TOTAL_POINTS = 45)

        emit log_named_uint("Initial Total", stats[0] + stats[1] + stats[2]);

        // Test STRENGTH alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(stats)
        );
        uint256 strengthCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);

        // Change values for AGILITY character to avoid any caching
        stats[0] = 7; // Strength
        stats[1] = 8; // Agility
        stats[2] = 6; // Magic

        vm.clearMockedCalls();
        // Test AGILITY alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(stats)
        );
        uint256 agilityCharId = character.mintCharacter(user, Types.Alignment.AGILITY);

        // Change values for MAGIC character
        stats[0] = 6; // Strength
        stats[1] = 7; // Agility
        stats[2] = 8; // Magic

        vm.clearMockedCalls();
        // Test MAGIC alignment
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
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
        assertEq(strengthChar.strength, 16, "STRENGTH character should have max strength");
        assertEq(agilityChar.agility, 16, "AGILITY character should have max agility");
        assertEq(magicChar.magic, 16, "MAGIC character should have max magic");

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
        resetRandomSeed();
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
        resetRandomSeed();
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Create and mint equipment first
        uint256 weaponId =
            equipment.createEquipment("Test Weapon", "A test weapon", 100, 0, 0, Types.Alignment.STRENGTH, 1);
        uint256 armorId = equipment.createEquipment("Test Armor", "A test armor", 0, 100, 0, Types.Alignment.AGILITY, 1);
        equipment.mint(user, weaponId, 1, "");
        equipment.mint(user, armorId, 1, "");

        vm.startPrank(user);
        // Approve equipment for character wallet
        address wallet = address(character.characterWallets(tokenId));
        equipment.setApprovalForAll(wallet, true);

        // Transfer equipment to character wallet
        equipment.safeTransferFrom(user, wallet, weaponId, 1, "");
        equipment.safeTransferFrom(user, wallet, armorId, 1, "");

        // Equip items
        character.equip(tokenId, weaponId, armorId);

        // Verify equipment is equipped
        (, Types.EquipmentSlots memory slots,) = character.getCharacter(tokenId);
        assertEq(slots.weaponId, weaponId);
        assertEq(slots.armorId, armorId);
        vm.stopPrank();
    }

    function testUnequipItems() public {
        resetRandomSeed();
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Create and mint equipment first
        uint256 weaponId =
            equipment.createEquipment("Test Weapon", "A test weapon", 100, 0, 0, Types.Alignment.STRENGTH, 1);
        uint256 armorId = equipment.createEquipment("Test Armor", "A test armor", 0, 100, 0, Types.Alignment.AGILITY, 1);
        equipment.mint(user, weaponId, 1, "");
        equipment.mint(user, armorId, 1, "");

        vm.startPrank(user);
        // Approve equipment for character wallet
        address wallet = address(character.characterWallets(tokenId));
        equipment.setApprovalForAll(wallet, true);

        // Transfer equipment to character wallet
        equipment.safeTransferFrom(user, wallet, weaponId, 1, "");
        equipment.safeTransferFrom(user, wallet, armorId, 1, "");

        // Equip items
        character.equip(tokenId, weaponId, armorId);

        // Unequip items
        character.unequip(tokenId, true, true);

        // Verify equipment is unequipped
        (, Types.EquipmentSlots memory slots,) = character.getCharacter(tokenId);
        assertEq(slots.weaponId, 0);
        assertEq(slots.armorId, 0);
        vm.stopPrank();
    }

    function testUpdateStats() public {
        resetRandomSeed();
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        vm.startPrank(owner);
        Types.Stats memory newStats = Types.Stats({ strength: 15, agility: 15, magic: 15 });
        character.updateStats(tokenId, newStats);
        vm.stopPrank();

        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        assertEq(stats.strength, 15);
        assertEq(stats.agility, 15);
        assertEq(stats.magic, 15);
    }

    function testUpdateState() public {
        resetRandomSeed();
        vm.startPrank(user);
        uint256 tokenId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        vm.startPrank(owner);
        Types.CharacterState memory newState = Types.CharacterState({
            health: 90,
            consecutiveHits: 5,
            damageReceived: 1000,
            roundsParticipated: 10,
            alignment: Types.Alignment.STRENGTH,
            level: 2,
            class: 0
        });
        character.updateState(tokenId, newState);
        vm.stopPrank();

        (,, Types.CharacterState memory state) = character.getCharacter(tokenId);
        assertEq(state.health, 90);
        assertEq(state.consecutiveHits, 5);
        assertEq(state.damageReceived, 1000);
        assertEq(state.roundsParticipated, 10);
        assertEq(uint256(state.alignment), uint256(Types.Alignment.STRENGTH));
        assertEq(state.level, 2);
        assertEq(state.class, 0);
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
        Types.Stats memory newStats = Types.Stats({ strength: 15, agility: 12, magic: 8 });
        character.updateStats(999, newStats);
    }

    function testFailUpdateStateNonexistentCharacter() public {
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 1,
            class: 0
        });
        character.updateState(999, newState);
    }

    function testMintCharacterBatch() public {
        // Reset seeds
        random.resetSeed(msg.sender, context);
        random.initializeSeed(msg.sender, context);
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        // Mock random number generation
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 10;
        numbers[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(numbers)
        );

        // Test batch minting
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = character.mintCharacter(user, Types.Alignment.STRENGTH);
            assertEq(character.ownerOf(tokenIds[i]), user);
        }
    }
}
