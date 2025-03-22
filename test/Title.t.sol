// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Title } from "../src/titles/Title.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";

contract TitleTest is Test {
    Title public titleContract;
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
        titleContract = new Title(address(character));

        // Create a character for testing
        characterId = character.mintCharacter(
            user1, Types.Stats({ strength: 10, agility: 10, magic: 10 }), Types.Alignment.STRENGTH
        );
    }

    function testCreateTitle() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200); // 5%, 3%, 2% boosts

        (string memory name, uint256 yieldBoost, uint256 feeReduction, uint256 dropRate, bool active) =
            titleContract.titles(titleId);

        assertEq(name, "Champion", "Incorrect title name");
        assertEq(yieldBoost, 500, "Incorrect yield boost");
        assertEq(feeReduction, 300, "Incorrect fee reduction");
        assertEq(dropRate, 200, "Incorrect drop rate");
        assertTrue(active, "Title should be active");
    }

    function testAssignTitle() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);

        vm.startPrank(user1);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();

        assertTrue(titleContract.hasActiveTitle(characterId), "Title should be active");

        (uint256 yieldBoost, uint256 feeReduction, uint256 dropRate) = titleContract.getTitleBenefits(characterId);
        assertEq(yieldBoost, 500, "Incorrect yield boost");
        assertEq(feeReduction, 300, "Incorrect fee reduction");
        assertEq(dropRate, 200, "Incorrect drop rate");
    }

    function testRevokeTitle() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);

        vm.startPrank(user1);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();

        titleContract.revokeTitle(characterId);

        assertFalse(titleContract.hasActiveTitle(characterId), "Title should be inactive");

        (uint256 yieldBoost, uint256 feeReduction, uint256 dropRate) = titleContract.getTitleBenefits(characterId);
        assertEq(yieldBoost, 0, "Should have no yield boost");
        assertEq(feeReduction, 0, "Should have no fee reduction");
        assertEq(dropRate, 0, "Should have no drop rate boost");
    }

    function testDeactivateTitle() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);

        vm.startPrank(user1);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();

        titleContract.deactivateTitle(titleId);

        assertFalse(titleContract.hasActiveTitle(characterId), "Title should be inactive");

        (uint256 yieldBoost, uint256 feeReduction, uint256 dropRate) = titleContract.getTitleBenefits(characterId);
        assertEq(yieldBoost, 0, "Should have no yield boost");
        assertEq(feeReduction, 0, "Should have no fee reduction");
        assertEq(dropRate, 0, "Should have no drop rate boost");
    }

    function testFailAssignInactiveTitle() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);
        titleContract.deactivateTitle(titleId);

        vm.startPrank(user1);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();
    }

    function testFailUnauthorizedAssignment() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);

        vm.startPrank(user2);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();
    }
}
