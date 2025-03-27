// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { NotWeaponOwner } from "../src/interfaces/Errors.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";
import { Character } from "../src/Character.sol";
import { MockEquipment } from "./mocks/MockEquipment.sol";
import { IEquipment } from "../src/interfaces/IEquipment.sol";

contract CharacterWalletTest is Test {
    CharacterWallet public wallet;
    MockEquipment public equipment;
    address public owner;
    address public characterContract;
    uint256 public constant CHARACTER_ID = 1;
    ProvableRandom public random;
    Character public character;
    uint256[] public itemIds;

    function setUp() public {
        owner = address(this);

        // Deploy contracts in correct order
        random = new ProvableRandom();
        equipment = new MockEquipment(address(this)); // Use MockEquipment instead
        character = new Character(address(equipment), address(random));

        // Create wallet first
        wallet = new CharacterWallet(address(equipment), CHARACTER_ID, address(character));

        // Initialize itemIds
        itemIds = new uint256[](2);
        itemIds[0] = 1; // Use simple IDs for MockEquipment
        itemIds[1] = 2;

        // Mint a character to the wallet
        character.mintCharacter(address(wallet), Types.Alignment.STRENGTH);

        // Create test equipment and mint directly to wallet
        vm.startPrank(address(this));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Mint equipment directly to wallet
        for (uint256 i = 0; i < itemIds.length; i++) {
            equipment.mint(address(wallet), itemIds[i], amounts[i], "");
        }
        vm.stopPrank();

        // Transfer wallet ownership to owner
        vm.prank(address(this));
        wallet.transferOwnership(owner);

        // Approve equipment for wallet
        vm.prank(owner);
        equipment.setApprovalForAll(address(wallet), true);
    }

    function testInitialization() public view {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.characterId(), CHARACTER_ID);
        assertEq(wallet.characterContract(), address(character));
    }

    function testEquipUnequip() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(address(character));
        wallet.equip(1, 2);

        // Check equipped items
        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 1);
        assertEq(slots.armorId, 2);

        // Unequip items
        vm.prank(address(character));
        wallet.unequip(true, true);

        // Check unequipped items
        slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 0);
        assertEq(slots.armorId, 0);
    }

    function testEquipmentTransferWithCharacter() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(address(character));
        wallet.equip(1, 2);

        // Transfer wallet to new owner
        address newOwner = makeAddr("newOwner");
        vm.prank(owner);
        wallet.transferOwnership(newOwner);

        // Verify new owner can equip/unequip
        vm.startPrank(address(this));
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        vm.prank(address(character));
        wallet.equip(1, 2);

        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 1);
        assertEq(slots.armorId, 2);
    }

    function testPartialUnequip() public {
        // Mint equipment to wallet
        vm.startPrank(address(this));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        _mintTestEquipment(equipment, address(wallet), itemIds, amounts);
        vm.stopPrank();

        // Equip items
        vm.prank(address(character));
        wallet.equip(1, 2);

        // Unequip only weapon
        vm.prank(address(character));
        wallet.unequip(true, false);

        // Check that only weapon was unequipped
        Types.EquipmentSlots memory slots = wallet.getEquippedItems();
        assertEq(slots.weaponId, 0, "Weapon should be unequipped");
        assertEq(slots.armorId, 2, "Armor should remain equipped");
    }

    function testEquipmentBalanceAfterTransfer() public {
        uint256[] memory initialBalances = _checkEquipmentBalances(equipment, address(wallet), itemIds);
        assertEq(initialBalances[0], 1, "Should have 1 weapon initially");
        assertEq(initialBalances[1], 1, "Should have 1 armor piece initially");

        // Transfer some equipment
        vm.startPrank(address(wallet));
        equipment.safeTransferFrom(address(wallet), makeAddr("recipient"), 1, 1, "");
        equipment.safeTransferFrom(address(wallet), makeAddr("recipient"), 2, 1, "");
        vm.stopPrank();

        // Check final balances
        uint256[] memory finalBalances = _checkEquipmentBalances(equipment, address(wallet), itemIds);
        assertEq(finalBalances[0], 0, "Should have 0 weapons after transfer");
        assertEq(finalBalances[1], 0, "Should have 0 armor pieces after transfer");
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
        vm.startPrank(address(character));
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

    function _mintTestEquipment(IEquipment _equipment, address to, uint256[] memory itmIds, uint256[] memory amounts)
        internal
    {
        for (uint256 i = 0; i < itmIds.length; i++) {
            MockEquipment(address(_equipment)).mint(to, itmIds[i], amounts[i], "");
        }
    }

    function _checkEquipmentBalances(IEquipment eqContract, address target, uint256[] memory idsToCheck)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](idsToCheck.length);
        for (uint256 i = 0; i < idsToCheck.length; i++) {
            balances[i] = eqContract.balanceOf(target, idsToCheck[i]);
        }
        return balances;
    }
}
