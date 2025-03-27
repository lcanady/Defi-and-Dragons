// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Equipment } from "../src/Equipment.sol";
import { Types } from "../src/interfaces/Types.sol";
import { Character } from "../src/Character.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract EquipmentTest is Test, IERC721Receiver, IERC1155Receiver {
    Equipment public equipment;
    Character public character;
    ProvableRandom public random;
    address public owner;
    uint256 public characterId;

    // Implement ERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement ERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

    function setUp() public {
        owner = address(this);

        // Deploy contracts in correct order
        random = new ProvableRandom();
        equipment = new Equipment(owner); // Use owner as temporary character contract
        character = new Character(address(equipment), address(random));

        // Update character contract in equipment
        equipment.setCharacterContract(address(character));

        // Create test character
        vm.startPrank(owner);
        characterId = character.mintCharacter(owner, Types.Alignment.STRENGTH);
        vm.stopPrank();
    }

    function testCreateEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
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
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
        );

        equipment.mint(owner, weaponId, 1, "");
        assertEq(equipment.balanceOf(owner, weaponId), 1, "Owner should have 1 weapon");
    }

    function testDeactivateEquipment() public {
        uint256 weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
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
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
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
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
        );

        equipment.deactivateEquipment(weaponId);
        equipment.mint(owner, weaponId, 1, "");
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
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
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
            0, // magic bonus
            Types.Alignment.STRENGTH, // stat affinity
            1 // amount
        );

        equipment.activateEquipment(weaponId);
    }
}
