// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";

contract EquipmentTest is Test {
    Character public character;
    Equipment public equipment;
    address public owner;
    address public player1;
    address public player2;

    // Test character stats
    Types.Stats private strengthChar = Types.Stats({ strength: 60, agility: 20, magic: 20 });

    function setUp() public {
        owner = address(this);
        player1 = address(0x1);
        player2 = address(0x2);

        // Deploy contracts
        equipment = new Equipment();
        character = new Character(address(equipment));

        // Set up contract relationships
        equipment.setCharacterContract(address(character));
    }

    function testCreateEquipment() public {
        vm.startPrank(owner);
        // Create a weapon with stat bonuses
        equipment.createEquipment(
            1, // Equipment ID
            "Warrior's Sword",
            "A mighty sword that enhances strength",
            5, // +5 Strength
            2, // +2 Agility
            0 // +0 Magic
        );
        vm.stopPrank();

        Types.EquipmentStats memory stats = equipment.getEquipmentStats(1);
        assertEq(stats.strengthBonus, 5);
        assertEq(stats.agilityBonus, 2);
        assertEq(stats.magicBonus, 0);
        assertEq(stats.name, "Warrior's Sword");
        assertTrue(stats.isActive);
    }

    function testEquipmentFlow() public {
        // Create equipment
        vm.startPrank(owner);
        equipment.createEquipment(
            1, // Weapon
            "Strength Sword",
            "Sword that boosts strength",
            10,
            0,
            0
        );

        equipment.createEquipment(
            2, // Armor
            "Agility Armor",
            "Armor that boosts agility",
            0,
            10,
            0
        );

        // Mint character
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        
        // Get character's wallet
        CharacterWallet wallet = character.characterWallets(tokenId);
        
        // Mint equipment to wallet
        equipment.mint(address(wallet), 1, 1, ""); // Weapon
        equipment.mint(address(wallet), 2, 1, ""); // Armor
        vm.stopPrank();

        // Equip items
        vm.startPrank(player1);
        character.equip(tokenId, 1, 2);
        vm.stopPrank();

        // Verify equipment is equipped
        (, Types.EquipmentSlots memory equipped,) = character.getCharacter(tokenId);
        assertEq(equipped.weaponId, 1);
        assertEq(equipped.armorId, 2);
    }

    function testEquipmentRequirements() public {
        // Create equipment
        vm.startPrank(owner);
        equipment.createEquipment(1, "Test Sword", "Basic sword", 5, 0, 0);

        // Mint character
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        
        // Get character's wallet
        CharacterWallet wallet = character.characterWallets(tokenId);
        vm.stopPrank();

        // Try to equip without owning (should fail)
        vm.startPrank(player1);
        vm.expectRevert("Don't own weapon");
        character.equip(tokenId, 1, 0);
        vm.stopPrank();

        // Mint equipment to wallet and try again (should succeed)
        vm.startPrank(owner);
        equipment.mint(address(wallet), 1, 1, "");
        vm.stopPrank();

        vm.startPrank(player1);
        character.equip(tokenId, 1, 0);
        vm.stopPrank();

        // Verify equipment is equipped
        (, Types.EquipmentSlots memory equipped,) = character.getCharacter(tokenId);
        assertEq(equipped.weaponId, 1);
        assertEq(equipped.armorId, 0);
    }
}
