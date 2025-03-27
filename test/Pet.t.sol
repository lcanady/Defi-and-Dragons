// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Pet } from "../src/pets/Pet.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract PetTest is Test, IERC721Receiver {
    Pet public petContract;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;

    address public owner;
    address public user;
    uint256 public characterId;
    uint256 public petId;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy contracts in correct order
        random = new ProvableRandom();
        equipment = new Equipment(owner);
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));
        petContract = new Pet(address(character));

        // Set up ownership and permissions
        vm.startPrank(owner);
        character.transferOwnership(owner);
        equipment.transferOwnership(owner);
        petContract.transferOwnership(owner);
        equipment.grantRole(keccak256("MINTER_ROLE"), owner);
        equipment.grantRole(keccak256("MINTER_ROLE"), address(character));
        vm.stopPrank();

        // Reset random seed before creating test character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(owner, context);
        random.resetSeed(user, context);

        // Create a character for testing
        vm.startPrank(user);
        random.initializeSeed(user, context);
        characterId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Update character state
        Types.CharacterState memory state = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 10,
            class: 0
        });
        character.updateState(characterId, state);

        // Create and activate test pet
        petId = petContract.createPet(
            "Test Pet",
            "A test pet",
            Pet.Rarity.Common,
            500, // 5% yield boost
            500, // 5% drop rate boost
            5 // Level 5 required
        );
    }

    function testCreatePet() public {
        vm.startPrank(owner);
        uint256 newPetId = petContract.createPet(
            "Test Pet 2",
            "Another test pet",
            Pet.Rarity.Common,
            500, // 5% yield boost
            500, // 5% drop rate boost
            5 // Level 5 required
        );
        vm.stopPrank();

        (
            string memory name,
            string memory description,
            Pet.Rarity rarity,
            uint256 yieldBoost,
            uint256 dropBoost,
            uint256 level,
            bool isActive
        ) = petContract.pets(newPetId);
        assertEq(name, "Test Pet 2");
        assertEq(description, "Another test pet");
        assertEq(uint256(rarity), uint256(Pet.Rarity.Common));
        assertEq(yieldBoost, 500);
        assertEq(dropBoost, 500);
        assertEq(level, 5);
        assertTrue(isActive);
    }

    function testMintPet() public {
        vm.startPrank(user);
        // Reset and initialize seed before minting character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        uint256 userCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Update character level to meet requirements
        vm.startPrank(owner);
        Types.CharacterState memory state = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 10,
            class: 0
        });
        character.updateState(userCharId, state);
        vm.stopPrank();

        // Mint pet to character
        vm.startPrank(user);
        petContract.mintPet(userCharId, petId);

        // Verify pet assignment
        assertTrue(petContract.hasActivePet(userCharId));
        (uint256 yieldBoost, uint256 dropBoost) = petContract.getPetBenefits(userCharId);
        assertEq(yieldBoost, 500);
        assertEq(dropBoost, 500);
        vm.stopPrank();
    }

    function testMintPetInsufficientLevel() public {
        vm.startPrank(user);
        // Reset and initialize seed before minting character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        uint256 userCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);

        // Character level is 1 by default, which is below requirement
        vm.expectRevert("Insufficient level");
        petContract.mintPet(userCharId, petId);
        vm.stopPrank();
    }

    function testMintPetTwice() public {
        vm.startPrank(user);
        // Reset seed before minting character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        uint256 userCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Update character level to meet requirements
        vm.startPrank(owner);
        Types.CharacterState memory state = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 10,
            class: 0
        });
        character.updateState(userCharId, state);
        vm.stopPrank();

        // Mint first pet
        vm.startPrank(user);
        petContract.mintPet(userCharId, petId);

        // Try to mint second pet
        vm.expectRevert(Pet.AlreadyHasPet.selector);
        petContract.mintPet(userCharId, petId);
        vm.stopPrank();
    }

    function testUnassignPet() public {
        vm.startPrank(user);
        // Reset and initialize seed before minting character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        uint256 userCharId = character.mintCharacter(user, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Update character level to meet requirements
        vm.startPrank(owner);
        Types.CharacterState memory state = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 10,
            class: 0
        });
        character.updateState(userCharId, state);
        vm.stopPrank();

        // Mint and then unassign pet
        vm.startPrank(user);
        petContract.mintPet(userCharId, petId);
        petContract.unassignPet(userCharId);

        assertFalse(petContract.hasActivePet(userCharId));
        (uint256 yieldBoost, uint256 dropBoost) = petContract.getPetBenefits(userCharId);
        assertEq(yieldBoost, 0);
        assertEq(dropBoost, 0);
        vm.stopPrank();
    }

    function testDeactivatePet() public {
        vm.startPrank(owner);
        petContract.deactivatePet(petId);
        (,,,,,, bool isActive) = petContract.pets(petId);
        assertFalse(isActive);
        vm.stopPrank();
    }

    function testExcessiveYieldBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Pet.BoostTooHigh.selector);
        petContract.createPet(
            "Invalid Pet",
            "Pet with excessive yield boost",
            Pet.Rarity.Common,
            5001, // Over 50%
            500,
            5
        );
        vm.stopPrank();
    }

    function testExcessiveDropBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Pet.BoostTooHigh.selector);
        petContract.createPet(
            "Invalid Pet",
            "Pet with excessive drop boost",
            Pet.Rarity.Common,
            500,
            5001, // Over 50%
            5
        );
        vm.stopPrank();
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
