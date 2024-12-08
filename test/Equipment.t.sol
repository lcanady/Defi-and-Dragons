// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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
        equipment.createEquipment(1, "Test Weapon", "A test weapon", 5, 0, 0);
        Types.EquipmentStats memory stats = equipment.getEquipmentStats(1);
        assertEq(stats.strengthBonus, 5);
        assertEq(stats.agilityBonus, 0);
        assertEq(stats.magicBonus, 0);
        assertEq(stats.name, "Test Weapon");
        assertEq(stats.description, "A test weapon");
        assertTrue(stats.isActive);
    }

    function testEquipmentFlow() public {
        // Create equipment
        equipment.createEquipment(1, "Test Weapon", "A test weapon", 5, 0, 0);

        // Set character contract
        equipment.setCharacterContract(address(this));

        // Mint equipment to user
        equipment.mint(user, 1, 1, "");

        // Set up special abilities
        Types.SpecialAbility[] memory abilities = new Types.SpecialAbility[](1);
        abilities[0] = Types.SpecialAbility({
            name: "Power Strike",
            description: "Deals extra damage",
            triggerCondition: Types.TriggerCondition.ON_HIGH_DAMAGE,
            triggerValue: 50,
            effectType: Types.EffectType.DAMAGE_BOOST,
            effectValue: 20,
            cooldown: 3
        });
        equipment.setSpecialAbilities(1, abilities);

        // Check ability
        Types.SpecialAbility memory ability = equipment.getSpecialAbility(1, 0);
        assertEq(ability.name, "Power Strike");
        assertEq(ability.effectValue, 20);

        // Check trigger condition
        equipment.updateAbilityCooldown(1, 1, 0, 5);
        assertTrue(equipment.checkTriggerCondition(1, 1, 0, 10));
    }

    function testEquipmentRequirements() public {
        equipment.createEquipment(1, "Test Weapon", "A test weapon", 5, 0, 0);

        vm.expectRevert("Only character contract");
        equipment.updateAbilityCooldown(1, 1, 0, 5);
    }
}
