// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";

contract AbilityTest is Test {
    Ability public abilityContract;
    Character public character;
    Equipment public equipment;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    uint256 public characterId;

    function setUp() public {
        // Deploy contracts
        equipment = new Equipment();
        character = new Character(address(equipment));
        abilityContract = new Ability(address(character));

        // Create a character for testing
        characterId = character.mintCharacter(
            user1,
            Types.Stats({ strength: 10, agility: 10, magic: 10 }),
            Types.Alignment.STRENGTH
        );
    }

    function testCreateAbility() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500, // 5% AMM fee reduction
            300, // 3% crafting success boost
            200, // 2% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            5 // Level 5 required
        );

        (
            string memory name,
            uint256 ammFeeReduction,
            uint256 craftingBoost,
            uint256 vrfReduction,
            uint256 cooldownReduction,
            bool active,
            uint256 requiredLevel
        ) = abilityContract.abilities(abilityId);

        assertEq(name, "Swift Trading", "Incorrect ability name");
        assertEq(ammFeeReduction, 500, "Incorrect fee reduction");
        assertEq(craftingBoost, 300, "Incorrect crafting boost");
        assertEq(vrfReduction, 200, "Incorrect VRF reduction");
        assertEq(cooldownReduction, 1 hours, "Incorrect cooldown reduction");
        assertTrue(active, "Ability should be active");
        assertEq(requiredLevel, 5, "Incorrect required level");
    }

    function testLearnAbility() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500,
            300,
            200,
            1 hours,
            5
        );

        // Update character level
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 5
        });
        character.updateState(characterId, newState);

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        vm.stopPrank();

        assertTrue(abilityContract.hasActiveAbility(characterId), "Ability should be active");

        (
            uint256 ammFeeReduction,
            uint256 craftingBoost,
            uint256 vrfReduction,
            uint256 cdReduction
        ) = abilityContract.getAbilityBenefits(characterId);

        assertEq(ammFeeReduction, 500, "Incorrect fee reduction");
        assertEq(craftingBoost, 300, "Incorrect crafting boost");
        assertEq(vrfReduction, 200, "Incorrect VRF reduction");
        assertEq(cdReduction, 1 hours, "Incorrect cooldown reduction");
    }

    function testUseAbility() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500,
            300,
            200,
            0, // No cooldown reduction
            5
        );

        // Update character level
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 5
        });
        character.updateState(characterId, newState);

        // Set initial timestamp
        vm.warp(1000);

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        assertTrue(abilityContract.useAbility(characterId), "Should use ability successfully");

        // Try to use ability again immediately (should fail)
        vm.expectRevert(bytes4(keccak256("AbilityCooldown()")));
        abilityContract.useAbility(characterId);

        // Wait for cooldown
        vm.warp(block.timestamp + 2 hours);
        assertTrue(abilityContract.useAbility(characterId), "Should use ability after cooldown");
        vm.stopPrank();
    }

    function testFailLearnAbilityInsufficientLevel() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500,
            300,
            200,
            1 hours,
            10 // Level 10 required
        );

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId); // Should fail, character is level 1
        vm.stopPrank();
    }

    function testDeactivateAbility() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500,
            300,
            200,
            1 hours,
            5
        );

        // Update character level and learn ability
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 5
        });
        character.updateState(characterId, newState);

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        vm.stopPrank();

        // Deactivate ability
        abilityContract.deactivateAbility(abilityId);
        assertFalse(abilityContract.hasActiveAbility(characterId), "Ability should be inactive");

        (
            uint256 ammFeeReduction,
            uint256 craftingBoost,
            uint256 vrfReduction,
            uint256 cdReduction
        ) = abilityContract.getAbilityBenefits(characterId);

        assertEq(ammFeeReduction, 0, "Should have no fee reduction");
        assertEq(craftingBoost, 0, "Should have no crafting boost");
        assertEq(vrfReduction, 0, "Should have no VRF reduction");
        assertEq(cdReduction, 0, "Should have no cooldown reduction");
    }
} 