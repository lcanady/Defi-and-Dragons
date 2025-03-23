// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { AbilityIntegration } from "../src/abilities/AbilityIntegration.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { ArcaneCrafting } from "../src/amm/ArcaneCrafting.sol";
import { ArcaneFactory } from "../src/amm/ArcaneFactory.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract AbilityIntegrationTest is Test, IERC721Receiver {
    AbilityIntegration public integration;
    Ability public ability;
    ArcaneCrafting public crafting;
    ArcaneFactory public factory;
    ItemDrop public itemDrop;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;

    address public owner;
    address public user;
    uint256 public characterId;
    uint256 public abilityId;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy core contracts
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));

        // Deploy contracts
        factory = new ArcaneFactory();
        itemDrop = new ItemDrop();
        ability = new Ability(address(character));
        crafting = new ArcaneCrafting(address(factory), address(equipment), address(itemDrop));

        // Initialize contracts
        itemDrop.initialize(address(equipment));

        // Deploy integration contract
        integration = new AbilityIntegration(address(ability), address(crafting), address(factory), address(itemDrop));

        // Create test character
        characterId = character.mintCharacter(
            user,
            Types.Alignment.STRENGTH
        );

        // Set character level to 5
        vm.startPrank(owner);
        character.updateState(characterId, Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 5
        }));
        vm.stopPrank();

        // Create test ability
        abilityId = ability.createAbility(
            "Master Trader",
            2000, // 20% AMM fee reduction
            1500, // 15% crafting success boost
            1000, // 10% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            5 // Level 5 required
        );

        // Have the user learn the ability
        vm.startPrank(user);
        ability.learnAbility(characterId, abilityId);
        vm.stopPrank();
    }

    function testGetAMMFeeReduction() public {
        uint256 reduction = integration.calculateAMMFeeReduction(characterId);
        assertEq(reduction, 2000, "Incorrect AMM fee reduction");
    }

    function testGetCraftingBoost() public {
        uint256 boost = integration.calculateCraftingBoost(characterId);
        assertEq(boost, 1500, "Incorrect crafting boost");
    }

    function testGetVRFFeeReduction() public {
        uint256 reduction = integration.calculateVRFReduction(characterId);
        assertEq(reduction, 1000, "Incorrect VRF reduction");
    }

    function testGetCombinedBoosts() public {
        (uint256 boost, uint256 feeReduction) = integration.applyCraftingBenefits(characterId);
        assertEq(boost, 1500, "Incorrect crafting boost");
        assertEq(feeReduction, 2000, "Incorrect fee reduction");
    }

    function testGetAMMFeeReductionWithoutAbility() public {
        uint256 reduction = integration.calculateAMMFeeReduction(0);
        assertEq(reduction, 2000, "Incorrect AMM fee reduction");
    }

    function testGetVRFFeeReductionWithoutAbility() public {
        uint256 reduction = integration.calculateVRFReduction(0);
        assertEq(reduction, 1000, "Incorrect VRF reduction");
    }

    function testCalculateAMMFeeReduction() public {
        uint256 reduction = integration.calculateAMMFeeReduction(characterId);
        assertEq(reduction, 2000, "Incorrect AMM fee reduction");
    }

    function testCalculateCraftingBoost() public {
        uint256 boost = integration.calculateCraftingBoost(characterId);
        assertEq(boost, 1500, "Incorrect crafting boost");
    }

    function testCalculateVRFReduction() public {
        uint256 reduction = integration.calculateVRFReduction(characterId);
        assertEq(reduction, 1000, "Incorrect VRF reduction");
    }

    function testApplyCraftingBenefits() public {
        (uint256 boost, uint256 feeReduction) = integration.applyCraftingBenefits(characterId);
        assertEq(boost, 1500, "Incorrect crafting boost");
        assertEq(feeReduction, 2000, "Incorrect fee reduction");
    }

    function testApplyAMMBenefits() public {
        uint256 reduction = integration.applyAMMBenefits(characterId);
        assertEq(reduction, 2000, "Incorrect AMM fee reduction");
    }

    function testApplyVRFBenefits() public {
        uint256 reduction = integration.applyVRFBenefits(characterId);
        assertEq(reduction, 1000, "Incorrect VRF reduction");
    }

    function testCanUseAbility() public {
        assertTrue(integration.canUseAbility(characterId), "Should be able to use ability");

        // Deactivate ability
        ability.deactivateAbility(abilityId);
        assertFalse(integration.canUseAbility(characterId), "Should not be able to use deactivated ability");
    }

    function testMaxBenefits() public {
        // Try to create ability with benefits exceeding maximums
        vm.expectRevert("Fee reduction too high");
        ability.createAbility(
            "Overpowered",
            6000, // 60% AMM fee reduction (exceeds max)
            1500,
            1000,
            1 hours,
            5
        );

        vm.expectRevert("Crafting boost too high");
        ability.createAbility(
            "Overpowered",
            2000,
            6000, // 60% crafting boost (exceeds max)
            1000,
            1 hours,
            5
        );

        vm.expectRevert("VRF reduction too high");
        ability.createAbility(
            "Overpowered",
            2000,
            1500,
            6000, // 60% VRF reduction (exceeds max)
            1 hours,
            5
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
