// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { NotWeaponOwner } from "../src/interfaces/Errors.sol";

contract CharacterWalletTest is Test {
    CharacterWallet public wallet;
    Equipment public equipment;
    address public owner;
    address public characterContract;
    uint256 public constant CHARACTER_ID = 1;

    function setUp() public {
        owner = address(this);
        characterContract = makeAddr("characterContract");

        // Deploy contracts
        equipment = new Equipment();
        wallet = new CharacterWallet(address(equipment), CHARACTER_ID, characterContract);

        // Setup equipment
        equipment.setCharacterContract(characterContract);
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

        // Transfer wallet ownership to owner
        vm.prank(address(this));
        wallet.transferOwnership(owner);

        // Approve equipment for wallet
        vm.prank(owner);
        equipment.setApprovalForAll(address(wallet), true);
    }

    function testWalletCreation() public view {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.characterId(), CHARACTER_ID);
        assertEq(wallet.characterContract(), characterContract);
    }

    function testEquipUnequip() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(characterContract);
        wallet.equip(1, 2);

        // Check equipped items
        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 1);
        assertEq(slots.armorId, 2);

        // Unequip items
        vm.prank(characterContract);
        wallet.unequip(true, true);

        // Check unequipped items
        slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 0);
        assertEq(slots.armorId, 0);
    }

    function testEquipmentTransferWithCharacter() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(characterContract);
        wallet.equip(1, 2);

        // Transfer wallet to new owner
        address newOwner = makeAddr("newOwner");
        vm.prank(owner);
        wallet.transferOwnership(newOwner);

        // Verify new owner can equip/unequip
        vm.startPrank(address(this));
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        vm.prank(characterContract);
        wallet.equip(1, 2);

        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 1);
        assertEq(slots.armorId, 2);
    }

    function testPartialUnequip() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(characterContract);
        wallet.equip(1, 2);

        // Unequip only weapon
        vm.prank(characterContract);
        wallet.unequip(true, false);

        // Check that only weapon was unequipped
        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 0, "Weapon should be unequipped");
        assertEq(slots.armorId, 2, "Armor should remain equipped");
    }

    function testEquipmentBalanceAfterTransfer() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 2;
        amounts[1] = 3;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Check initial balances
        uint256[] memory initialBalances = _checkEquipmentBalances(equipment, address(wallet), itemIds);
        assertEq(initialBalances[0], 2, "Should have 2 weapons initially");
        assertEq(initialBalances[1], 3, "Should have 3 armor pieces initially");

        // Transfer some equipment
        vm.startPrank(address(wallet));
        equipment.safeTransferFrom(address(wallet), makeAddr("recipient"), 1, 1, "");
        equipment.safeTransferFrom(address(wallet), makeAddr("recipient"), 2, 2, "");
        vm.stopPrank();

        // Check final balances
        uint256[] memory finalBalances = _checkEquipmentBalances(equipment, address(wallet), itemIds);
        assertEq(finalBalances[0], 1, "Should have 1 weapon after transfer");
        assertEq(finalBalances[1], 1, "Should have 1 armor piece after transfer");
    }

    function testFailEquipNonexistentItem() public {
        // Mint some valid equipment to owner first
        vm.startPrank(owner);
        equipment.mint(owner, 1, 1, "");
        vm.stopPrank();

        // Approve equipment for wallet
        vm.prank(owner);
        equipment.setApprovalForAll(address(wallet), true);

        // Try to equip nonexistent item
        vm.startPrank(characterContract);
        vm.expectRevert(NotWeaponOwner.selector);
        wallet.equip(999, 0);
        vm.stopPrank();
    }

    function testFailEquipUnauthorized() public {
        address unauthorized = makeAddr("unauthorized");
        vm.expectRevert("Only character contract");
        vm.prank(unauthorized);
        wallet.equip(1, 2);
    }

    function _mintTestEquipment(Equipment _equipment, address _to, uint256[] memory _itemIds, uint256[] memory _amounts)
        internal
    {
        for (uint256 i = 0; i < _itemIds.length; i++) {
            _equipment.mint(_to, _itemIds[i], _amounts[i], "");
        }
    }

    function _checkEquipmentBalances(Equipment _equipment, address _owner, uint256[] memory _itemIds)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_itemIds.length);
        for (uint256 i = 0; i < _itemIds.length; i++) {
            balances[i] = _equipment.balanceOf(_owner, _itemIds[i]);
        }
        return balances;
    }
}
