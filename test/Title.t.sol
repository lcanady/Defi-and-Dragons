// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { Title } from "../src/titles/Title.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract TitleTest is Test, IERC721Receiver {
    Title public titleContract;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;
    address owner = address(this);
    uint256 public characterId;

    function setUp() public {
        random = new ProvableRandom();
        equipment = new Equipment(address(random));
        character = new Character(address(equipment), address(random));
        titleContract = new Title(address(character));

        characterId = character.mintCharacter(owner, Types.Alignment.STRENGTH);
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

        vm.startPrank(owner);
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

        vm.startPrank(owner);
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

        vm.startPrank(owner);
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

        vm.startPrank(owner);
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();
    }

    function testFailUnauthorizedAssignment() public {
        uint256 titleId = titleContract.createTitle("Champion", 500, 300, 200);

        vm.startPrank(makeAddr("user2"));
        titleContract.assignTitle(characterId, titleId);
        vm.stopPrank();
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
