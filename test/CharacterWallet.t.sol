// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";

contract CharacterWalletTest is Test {
    Character public character;
    Equipment public equipment;
    address public owner;
    address public player1;
    address public player2;

    // Test character stats
    Types.Stats private strengthChar = Types.Stats({
        strength: 60,
        agility: 20,
        magic: 20
    });

    function setUp() public {
        owner = address(this);
        player1 = address(0x1);
        player2 = address(0x2);

        // Deploy contracts
        equipment = new Equipment();
        character = new Character(address(equipment));

        // Set up contract relationships
        vm.startPrank(owner);
        equipment.setCharacterContract(address(character));
        
        // Create test equipment
        equipment.createEquipment(1, "Test Sword", "A basic sword", 5, 0, 0);
        equipment.createEquipment(2, "Test Armor", "Basic armor", 0, 5, 0);
        vm.stopPrank();
    }

    function testWalletCreation() public {
        // Mint character
        vm.startPrank(player1);
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Get wallet address
        CharacterWallet wallet = character.characterWallets(tokenId);
        
        // Verify wallet setup
        assertEq(wallet.owner(), player1);
        assertEq(wallet.characterId(), tokenId);
        assertEq(wallet.characterContract(), address(character));
        assertEq(address(wallet.equipment()), address(equipment));
    }

    function testEquipmentTransferWithCharacter() public {
        // Mint character to player1
        vm.startPrank(player1);
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        vm.stopPrank();

        CharacterWallet wallet = character.characterWallets(tokenId);

        // Mint equipment to wallet
        vm.startPrank(owner);
        equipment.mint(address(wallet), 1, 1, ""); // Sword
        equipment.mint(address(wallet), 2, 1, ""); // Armor
        vm.stopPrank();

        // Player1 equips items
        vm.startPrank(player1);
        character.equip(tokenId, 1, 2);

        // Transfer character to player2
        character.safeTransferFrom(player1, player2, tokenId);
        vm.stopPrank();

        // Verify wallet ownership transferred
        assertEq(wallet.owner(), player2);

        // Verify equipment still equipped
        Types.EquipmentSlots memory equipped = wallet.getEquippedItems();
        assertEq(equipped.weaponId, 1);
        assertEq(equipped.armorId, 2);

        // Verify equipment still in wallet
        assertEq(equipment.balanceOf(address(wallet), 1), 1);
        assertEq(equipment.balanceOf(address(wallet), 2), 1);
    }

    function testEquipUnequip() public {
        // Mint character
        vm.startPrank(player1);
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        vm.stopPrank();

        CharacterWallet wallet = character.characterWallets(tokenId);

        // Mint equipment to wallet
        vm.startPrank(owner);
        equipment.mint(address(wallet), 1, 1, ""); // Sword
        equipment.mint(address(wallet), 2, 1, ""); // Armor
        vm.stopPrank();

        // Equip items
        vm.startPrank(player1);
        character.equip(tokenId, 1, 2);

        // Verify equipment is equipped
        Types.EquipmentSlots memory equipped = wallet.getEquippedItems();
        assertEq(equipped.weaponId, 1);
        assertEq(equipped.armorId, 2);

        // Unequip weapon only
        character.unequip(tokenId, true, false);
        equipped = wallet.getEquippedItems();
        assertEq(equipped.weaponId, 0);
        assertEq(equipped.armorId, 2);

        // Unequip armor
        character.unequip(tokenId, false, true);
        equipped = wallet.getEquippedItems();
        assertEq(equipped.weaponId, 0);
        assertEq(equipped.armorId, 0);
        vm.stopPrank();
    }

    function testFailEquipUnauthorized() public {
        // Mint character to player1
        vm.startPrank(player1);
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        vm.stopPrank();

        CharacterWallet wallet = character.characterWallets(tokenId);

        // Mint equipment to wallet
        vm.startPrank(owner);
        equipment.mint(address(wallet), 1, 1, "");
        vm.stopPrank();

        // Try to equip as player2 (should fail)
        vm.prank(player2);
        character.equip(tokenId, 1, 0);
    }

    function testFailEquipNonexistentItem() public {
        // Mint character
        vm.startPrank(player1);
        uint256 tokenId = character.mintCharacter(player1, strengthChar, Types.Alignment.STRENGTH);
        
        // Try to equip item that wallet doesn't own
        character.equip(tokenId, 1, 0);
        vm.stopPrank();
    }
} 