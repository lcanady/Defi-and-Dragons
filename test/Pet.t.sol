// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Pet } from "../src/pets/Pet.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";

contract PetTest is Test {
    Pet public petContract;
    Character public character;
    Equipment public equipment;

    address public owner;
    address public user;
    uint256 public characterId;
    uint256 public petId;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy contracts
        equipment = new Equipment();
        character = new Character(address(equipment));
        petContract = new Pet(address(character));

        // Create test character
        characterId = character.mintCharacter(
            user, Types.Stats({ strength: 10, agility: 10, magic: 10 }), Types.Alignment.STRENGTH
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
    }

    function testCreatePet() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(newPetId, 1_000_000, "Incorrect pet ID");

        uint256 secondPetId = petContract.createPet(
            "Second Pet",
            "Another companion",
            Pet.Rarity.EPIC,
            3000, // 30% yield boost
            2500, // 25% drop rate boost
            5 // Level 5 required
        );
        assertEq(secondPetId, 1_000_001, "Incorrect second pet ID");

        // Verify pet data
        (
            string memory name,
            string memory description,
            Pet.Rarity rarity,
            uint256 yieldBoost,
            uint256 dropBoost,
            uint256 level,
            bool isActive
        ) = petContract.pets(newPetId);
        assertEq(name, "Test Pet", "Incorrect name");
        assertEq(description, "A loyal companion", "Incorrect description");
        assertEq(uint256(rarity), uint256(Pet.Rarity.RARE), "Incorrect rarity");
        assertEq(yieldBoost, 2000, "Incorrect yield boost");
        assertEq(dropBoost, 1500, "Incorrect drop rate boost");
        assertEq(level, 1, "Incorrect level requirement");
        assertTrue(isActive, "Pet should be active");
        vm.stopPrank();
    }

    function testMintPet() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(newPetId, 1_000_000, "Incorrect pet ID");
        vm.stopPrank();

        vm.startPrank(user);
        petContract.mintPet(characterId, newPetId);
        assertTrue(petContract.hasActivePet(characterId), "Pet should be active");
        vm.stopPrank();
    }

    function testUnassignPet() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(newPetId, 1_000_000, "Incorrect pet ID");
        vm.stopPrank();

        vm.startPrank(user);
        petContract.mintPet(characterId, newPetId);
        assertTrue(petContract.hasActivePet(characterId), "Pet should be active");
        petContract.unassignPet(characterId);
        assertFalse(petContract.hasActivePet(characterId), "Pet should be inactive");
        vm.stopPrank();
    }

    function testMintPetInsufficientLevel() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            10 // Level 10 required (higher than character's level)
        );
        vm.stopPrank();

        // Update character to lower level
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 1
        });
        character.updateState(characterId, newState);

        vm.startPrank(user);
        vm.expectRevert("Insufficient level");
        petContract.mintPet(characterId, newPetId);
        vm.stopPrank();
    }

    function testMintPetTwice() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(newPetId, 1_000_000, "Incorrect pet ID");
        vm.stopPrank();

        vm.startPrank(user);
        petContract.mintPet(characterId, newPetId);
        assertTrue(petContract.hasActivePet(characterId), "Pet should be active");
        vm.expectRevert(Pet.AlreadyHasPet.selector);
        petContract.mintPet(characterId, newPetId);
        vm.stopPrank();
    }

    function testDeactivatePet() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(newPetId, 1_000_000, "Incorrect pet ID");

        petContract.deactivatePet(newPetId);
        (,,,,,, bool isActive) = petContract.pets(newPetId);
        assertFalse(isActive, "Pet should be inactive");
        vm.stopPrank();
    }

    function testExcessiveYieldBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Pet.BoostTooHigh.selector);
        petContract.createPet(
            "Overpowered Pet",
            "Too powerful",
            Pet.Rarity.LEGENDARY,
            5001, // 50.01% yield boost (exceeds max)
            5000,
            10
        );
        vm.stopPrank();
    }

    function testExcessiveDropBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Pet.BoostTooHigh.selector);
        petContract.createPet(
            "Overpowered Pet",
            "Too powerful",
            Pet.Rarity.LEGENDARY,
            5000,
            5001, // 50.01% drop rate boost (exceeds max)
            10
        );
        vm.stopPrank();
    }
}
