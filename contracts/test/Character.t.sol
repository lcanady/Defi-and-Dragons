// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";

contract CharacterTest is Test {
    Character public character;
    Equipment public equipment;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        equipment = new Equipment();
        character = new Character(address(equipment));

        // Create test equipment
        equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0 // magic bonus
        );

        equipment.createEquipment(
            "Test Armor",
            "A test armor",
            0, // strength bonus
            5, // agility bonus
            0 // magic bonus
        );
    }

    function testMintCharacter() public {
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        assertEq(character.ownerOf(tokenId), user, "Character owner should be user");
        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        assertEq(stats.strength, 10, "Incorrect strength");
        assertEq(stats.agility, 8, "Incorrect agility");
        assertEq(stats.magic, 6, "Incorrect magic");
    }

    function testEquipItems() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Get the character's wallet
        address walletAddress = address(character.characterWallets(tokenId));
        require(walletAddress != address(0), "Character wallet not created");

        // Mint equipment to the character's wallet
        equipment.mint(walletAddress, 0, 1, "");
        equipment.mint(walletAddress, 1, 1, "");

        // Equip items
        vm.startPrank(user);
        character.equip(tokenId, 0, 1);
        vm.stopPrank();

        // Check equipped items
        (, Types.EquipmentSlots memory equippedItems,) = character.getCharacter(tokenId);
        assertEq(equippedItems.weaponId, 0, "Incorrect weapon ID");
        assertEq(equippedItems.armorId, 1, "Incorrect armor ID");
    }

    function testUnequipItems() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Get the character's wallet
        address walletAddress = address(character.characterWallets(tokenId));
        require(walletAddress != address(0), "Character wallet not created");

        // Mint equipment to the character's wallet
        equipment.mint(walletAddress, 0, 1, "");
        equipment.mint(walletAddress, 1, 1, "");

        // Equip and unequip items
        vm.startPrank(user);
        character.equip(tokenId, 0, 1);
        character.unequip(tokenId, true, true);
        vm.stopPrank();

        // Check unequipped items
        (, Types.EquipmentSlots memory equippedItems,) = character.getCharacter(tokenId);
        assertEq(equippedItems.weaponId, 0, "Weapon should be unequipped");
        assertEq(equippedItems.armorId, 0, "Armor should be unequipped");
    }

    function testUpdateStats() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Update stats
        Types.Stats memory newStats = Types.Stats({ strength: 15, agility: 12, magic: 9 });
        character.updateStats(tokenId, newStats);

        // Check updated stats
        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        assertEq(stats.strength, 15, "Incorrect updated strength");
        assertEq(stats.agility, 12, "Incorrect updated agility");
        assertEq(stats.magic, 9, "Incorrect updated magic");
    }

    function testUpdateState() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Update state
        Types.CharacterState memory newState = Types.CharacterState({
            health: 80,
            consecutiveHits: 3,
            damageReceived: 20,
            roundsParticipated: 5,
            alignment: Types.Alignment.AGILITY,
            level: 2
        });
        character.updateState(tokenId, newState);

        // Check updated state
        (,, Types.CharacterState memory state) = character.getCharacter(tokenId);
        assertEq(state.health, 80, "Incorrect updated health");
        assertEq(state.consecutiveHits, 3, "Incorrect updated consecutive hits");
        assertEq(state.damageReceived, 20, "Incorrect updated damage received");
        assertEq(state.roundsParticipated, 5, "Incorrect updated rounds participated");
        assertEq(uint256(state.alignment), uint256(Types.Alignment.AGILITY), "Incorrect updated alignment");
        assertEq(state.level, 2, "Incorrect updated level");
    }

    function testFailMintToZeroAddress() public {
        character.mintCharacter(
            address(0), Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH
        );
    }

    function testFailEquipUnauthorized() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Try to equip items as non-owner
        character.equip(tokenId, 0, 1);
    }

    function testFailUnequipUnauthorized() public {
        // Mint character
        uint256 tokenId =
            character.mintCharacter(user, Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH);

        // Try to unequip items as non-owner
        character.unequip(tokenId, true, true);
    }
}
