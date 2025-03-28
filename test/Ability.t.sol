// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract AbilityTest is Test, IERC721Receiver {
    Ability public abilityContract;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    uint256 public characterId;

    function setUp() public {
        // Deploy contracts in correct order
        random = new ProvableRandom();
        equipment = new Equipment(address(this));
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));
        abilityContract = new Ability(address(character));

        // Reset random seed before creating test character
        bytes32 context = bytes32(uint256(uint160(address(character))));
        random.resetSeed(owner, context);
        random.initializeSeed(owner, context);

        // Create test character for user
        vm.startPrank(user1);
        random.resetSeed(user1, context);
        random.initializeSeed(user1, context);
        characterId = character.mintCharacter(user1, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Set character level to 5
        character.updateState(
            characterId,
            Types.CharacterState({
                health: 100,
                consecutiveHits: 0,
                damageReceived: 0,
                roundsParticipated: 0,
                alignment: Types.Alignment.STRENGTH,
                level: 5,
                class: 0
            })
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
            500, // 5% AMM fee reduction
            300, // 3% crafting success boost
            200, // 2% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            5 // Level 5 required
        );

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        vm.stopPrank();

        assertTrue(abilityContract.hasActiveAbility(characterId), "Character should have the ability");
    }

    function testUseAbility() public {
        uint256 abilityId = abilityContract.createAbility(
            "Swift Trading",
            500, // 5% AMM fee reduction
            300, // 3% crafting success boost
            200, // 2% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            5 // Level 5 required
        );

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        abilityContract.useAbility(characterId);
        vm.stopPrank();

        assertTrue(abilityContract.hasActiveAbility(characterId), "Ability should be active");
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
            500, // 5% AMM fee reduction
            300, // 3% crafting success boost
            200, // 2% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            5 // Level 5 required
        );

        // Transfer ownership of ability contract to the user (character owner)
        abilityContract.transferOwnership(user1);

        vm.startPrank(user1);
        abilityContract.learnAbility(characterId, abilityId);
        abilityContract.useAbility(characterId);
        
        // Since the ability is active, deactivate it
        abilityContract.deactivateAbility(characterId);
        vm.stopPrank();

        assertFalse(abilityContract.hasActiveAbility(characterId), "Ability should be inactive");
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
