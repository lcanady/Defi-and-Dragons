// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Mount } from "../src/pets/Mount.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract MountTest is Test, IERC721Receiver {
    Mount public mountContract;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    uint256 public characterId;
    uint256 public mountId;

    function setUp() public {
        // Deploy contracts
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));
        mountContract = new Mount(address(character));

        // Create a character for testing
        vm.startPrank(owner);
        characterId = character.mintCharacter(
            owner,
            Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        // Create test mount
        mountId = mountContract.createMount(
            "Griffin",
            "A majestic flying mount",
            Mount.MountType.AIR,
            1000, // 10% speed boost
            1000, // 10% stamina boost
            1000, // 10% yield boost
            1000, // 10% drop rate boost
            1000, // 10% quest fee reduction
            12 hours, // 12 hours travel reduction
            1000, // 10% staking boost
            1000, // 10% LP lock reduction
            5 // Level 5 required
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

    function testCreateMount() public {
        uint256 newMountId = mountContract.createMount(
            "Dragon",
            "A powerful dragon mount",
            Mount.MountType.AIR,
            1000, // 10% speed boost
            1000, // 10% stamina boost
            1000, // 10% yield boost
            1000, // 10% drop rate boost
            1000, // 10% quest fee reduction
            12 hours, // 12 hours travel reduction
            1000, // 10% staking boost
            1000, // 10% LP lock reduction
            10 // Level 10 required
        );

        (
            string memory name,
            string memory description,
            Mount.MountType mountType,
            uint256 speedBoost,
            uint256 staminaBoost,
            uint256 yieldBoost,
            uint256 dropRateBoost,
            uint256 requiredLevel,
            bool isActive,
            uint256 questFeeReduction,
            uint256 travelTimeReduction,
            uint256 stakingBoostBps,
            uint256 lpLockReductionBps
        ) = mountContract.mounts(newMountId);

        assertEq(name, "Dragon", "Incorrect mount name");
        assertEq(description, "A powerful dragon mount", "Incorrect mount description");
        assertEq(uint256(mountType), uint256(Mount.MountType.AIR), "Incorrect mount type");
        assertEq(speedBoost, 1000, "Incorrect speed boost");
        assertEq(staminaBoost, 1000, "Incorrect stamina boost");
        assertEq(yieldBoost, 1000, "Incorrect yield boost");
        assertEq(dropRateBoost, 1000, "Incorrect drop rate boost");
        assertEq(questFeeReduction, 1000, "Incorrect quest fee reduction");
        assertEq(travelTimeReduction, 12 hours, "Incorrect travel reduction");
        assertEq(stakingBoostBps, 1000, "Incorrect staking boost");
        assertEq(lpLockReductionBps, 1000, "Incorrect LP lock reduction");
        assertEq(requiredLevel, 10, "Incorrect required level");
        assertTrue(isActive, "Mount should be active");
    }

    function testMintMount() public {
        vm.startPrank(owner);
        mountContract.mintMount(characterId, mountId);
        vm.stopPrank();

        assertTrue(mountContract.hasActiveMount(characterId), "Should have active mount");
        (uint256 questFeeReduction, uint256 travelTimeReduction, uint256 stakingBoostBps, uint256 lpLockReductionBps) =
            mountContract.getMountBenefits(characterId);
        assertEq(questFeeReduction, 1000, "Incorrect quest fee reduction");
        assertEq(travelTimeReduction, 12 hours, "Incorrect travel reduction");
        assertEq(stakingBoostBps, 1000, "Incorrect staking boost");
        assertEq(lpLockReductionBps, 1000, "Incorrect LP lock reduction");

        // Verify mount ownership
        address characterWallet = address(character.characterWallets(characterId));
        assertEq(mountContract.ownerOf(mountId), characterWallet, "Mount should be owned by character wallet");
        assertEq(mountContract.characterToMount(characterId), mountId, "Mount should be assigned to character");
    }

    function testUnassignMount() public {
        vm.startPrank(owner);
        mountContract.mintMount(characterId, mountId);

        // Verify mount is assigned before unassigning
        assertTrue(mountContract.hasActiveMount(characterId), "Should have active mount before unassigning");
        assertEq(mountContract.characterToMount(characterId), mountId, "Mount should be assigned to character");

        mountContract.unassignMount(characterId);

        assertFalse(mountContract.hasActiveMount(characterId), "Should not have active mount");
        (uint256 questFeeReduction, uint256 travelTimeReduction, uint256 stakingBoostBps, uint256 lpLockReductionBps) =
            mountContract.getMountBenefits(characterId);
        assertEq(questFeeReduction, 0, "Should have no quest fee reduction");
        assertEq(travelTimeReduction, 0, "Should have no travel reduction");
        assertEq(stakingBoostBps, 0, "Should have no staking boost");
        assertEq(lpLockReductionBps, 0, "Should have no LP lock reduction");
        vm.stopPrank();
    }

    function testMintMountInsufficientLevel() public {
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

        vm.startPrank(owner);
        vm.expectRevert(Mount.InsufficientLevel.selector);
        mountContract.mintMount(characterId, mountId); // Should fail, level too low
        vm.stopPrank();
    }

    function testMintMountTwice() public {
        vm.startPrank(owner);
        mountContract.mintMount(characterId, mountId);
        vm.expectRevert(Mount.AlreadyHasMount.selector);
        mountContract.mintMount(characterId, mountId); // Should fail, already has mount
        vm.stopPrank();
    }

    function testDeactivateMount() public {
        vm.startPrank(owner);
        mountContract.mintMount(characterId, mountId);
        mountContract.deactivateMount(mountId);
        vm.stopPrank();

        assertFalse(mountContract.hasActiveMount(characterId), "Mount should be inactive");

        (uint256 speedBoost, uint256 staminaBoost, uint256 yieldBoost, uint256 dropRateBoost) =
            mountContract.getMountBenefits(characterId);

        assertEq(speedBoost, 0, "Should have no speed boost");
        assertEq(staminaBoost, 0, "Should have no stamina boost");
        assertEq(yieldBoost, 0, "Should have no yield boost");
        assertEq(dropRateBoost, 0, "Should have no drop rate boost");
    }

    function testExcessiveSpeedBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Mount.BoostTooHigh.selector);
        mountContract.createMount(
            "Invalid Mount",
            "Too powerful",
            Mount.MountType.AIR,
            5001, // 50.01% speed boost (exceeds max)
            1000,
            1000,
            1000,
            1000,
            12 hours,
            1000,
            1000,
            10
        );
        vm.stopPrank();
    }

    function testExcessiveStaminaBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Mount.BoostTooHigh.selector);
        mountContract.createMount(
            "Invalid Mount",
            "Too powerful",
            Mount.MountType.AIR,
            1000,
            5001, // 50.01% stamina boost (exceeds max)
            1000,
            1000,
            1000,
            12 hours,
            1000,
            1000,
            10
        );
        vm.stopPrank();
    }

    function testExcessiveYieldBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Mount.BoostTooHigh.selector);
        mountContract.createMount(
            "Invalid Mount",
            "Too powerful",
            Mount.MountType.AIR,
            1000,
            1000,
            5001, // 50.01% yield boost (exceeds max)
            1000,
            1000,
            12 hours,
            1000,
            1000,
            10
        );
        vm.stopPrank();
    }

    function testExcessiveDropRateBoost() public {
        vm.startPrank(owner);
        vm.expectRevert(Mount.BoostTooHigh.selector);
        mountContract.createMount(
            "Invalid Mount",
            "Too powerful",
            Mount.MountType.AIR,
            1000,
            1000,
            1000,
            5001, // 50.01% drop rate boost (exceeds max)
            1000,
            12 hours,
            1000,
            1000,
            10
        );
        vm.stopPrank();
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
