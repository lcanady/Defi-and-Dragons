// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";

contract EquipmentTest is Test {
    Equipment public equipment;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        equipment = new Equipment();
    }

    function testCreateEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        (Types.EquipmentStats memory stats, bool exists) = equipment.getEquipmentStats(weaponId);
        assertTrue(exists, "Equipment should exist");
        assertEq(stats.strengthBonus, 5, "Incorrect strength bonus");
        assertEq(stats.agilityBonus, 0, "Incorrect agility bonus");
        assertEq(stats.magicBonus, 0, "Incorrect magic bonus");
        assertTrue(stats.isActive, "Equipment should be active");
    }

    function testMintEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.mint(user, weaponId, 1, "");
        assertEq(equipment.balanceOf(user, weaponId), 1, "User should have 1 weapon");
    }

    function testDeactivateEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.deactivateEquipment(weaponId);
        (Types.EquipmentStats memory stats, bool exists) = equipment.getEquipmentStats(weaponId);
        assertTrue(exists, "Equipment should exist");
        assertFalse(stats.isActive, "Equipment should be inactive");
    }

    function testActivateEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.deactivateEquipment(weaponId);
        equipment.activateEquipment(weaponId);
        (Types.EquipmentStats memory stats, bool exists) = equipment.getEquipmentStats(weaponId);
        assertTrue(exists, "Equipment should exist");
        assertTrue(stats.isActive, "Equipment should be active");
    }

    function testFailMintDeactivatedEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.deactivateEquipment(weaponId);
        equipment.mint(user, weaponId, 1, "");
    }

    function testFailDeactivateNonexistentEquipment() public {
        uint256 nonexistentId = 999;
        equipment.deactivateEquipment(nonexistentId);
    }

    function testFailActivateNonexistentEquipment() public {
        uint256 nonexistentId = 999;
        equipment.activateEquipment(nonexistentId);
    }

    function testFailDeactivateZeroBonus() public {
        // Create equipment with all zero bonuses
        uint256 weaponId = equipment.createEquipment(
            "Zero Bonus Weapon",
            "A weapon with no bonuses",
            0, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.deactivateEquipment(weaponId);
    }

    function testFailActivateZeroBonus() public {
        // Create equipment with all zero bonuses
        uint256 weaponId = equipment.createEquipment(
            "Zero Bonus Weapon",
            "A weapon with no bonuses",
            0, // strength bonus
            0, // agility bonus
            0  // magic bonus
        );

        equipment.activateEquipment(weaponId);
    }
}
