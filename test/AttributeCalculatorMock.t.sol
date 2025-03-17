// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "lib/forge-std/src/Test.sol";
import { AttributeCalculator } from "../src/attributes/AttributeCalculator.sol";
import { MockAttributeProvider } from "./mocks/MockAttributeProvider.sol";
import { Types } from "../src/interfaces/Types.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract AttributeCalculatorMockTest is Test, IERC721Receiver, IERC1155Receiver {
    AttributeCalculator public calculator;
    MockAttributeProvider public mockPet;
    MockAttributeProvider public mockMount;
    MockAttributeProvider public mockAbility;
    Character public characterContract;
    Equipment public equipmentContract;

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
        // Deploy core contracts first
        equipmentContract = new Equipment();
        characterContract = new Character(address(equipmentContract));
        equipmentContract.setCharacterContract(address(characterContract));

        // Create test character with base stats
        vm.startPrank(address(this));
        characterId = characterContract.mintCharacter(
            address(this), Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        // Deploy mock providers with default bonuses
        mockPet = new MockAttributeProvider(2000); // 20% bonus
        mockMount = new MockAttributeProvider(1500); // 15% bonus
        mockAbility = new MockAttributeProvider(2000); // 20% bonus

        // Deploy calculator with real contracts
        calculator = new AttributeCalculator(address(characterContract), address(equipmentContract));

        // Add mock providers to calculator
        vm.startPrank(address(this));
        calculator.addProvider(address(mockPet));
        calculator.addProvider(address(mockMount));
        calculator.addProvider(address(mockAbility));
        vm.stopPrank();

        // Set initial active states
        mockPet.setActiveForCharacter(characterId, true);
        mockMount.setActiveForCharacter(characterId, true);
        mockAbility.setActiveForCharacter(characterId, true);
    }

    function testAllBonusesActive() public {
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Expected bonuses:
        // Base: 10000 (100%)
        // Pet: 2000 (20%)
        // Mount: 1500 (15%)
        // Ability: 2000 (20%)
        // Alignment: 500 (5% for strength alignment)
        // Level: 100 (1% for level 1)
        uint256 expectedMultiplier = 16_100; // 10000 + 2000 + 1500 + 2000 + 500 + 100
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect total bonus with all sources active");
    }

    function testIndividualDeactivation() public {
        // Test deactivating each provider individually
        mockPet.setActiveForCharacter(characterId, false);
        (, uint256 bonusNoPet) = calculator.calculateTotalAttributes(characterId);
        assertEq(bonusNoPet, 14_100, "Incorrect bonus with pet deactivated"); // 16100 - 2000

        mockPet.setActiveForCharacter(characterId, true);
        mockMount.setActiveForCharacter(characterId, false);
        (, uint256 bonusNoMount) = calculator.calculateTotalAttributes(characterId);
        assertEq(bonusNoMount, 14_600, "Incorrect bonus with mount deactivated"); // 16100 - 1500

        mockMount.setActiveForCharacter(characterId, true);
        mockAbility.setActiveForCharacter(characterId, false);
        (, uint256 bonusNoAbility) = calculator.calculateTotalAttributes(characterId);
        assertEq(bonusNoAbility, 14_100, "Incorrect bonus with ability deactivated"); // 16100 - 2000
    }

    function testGlobalDeactivation() public {
        // Test global deactivation
        mockPet.setGlobalActive(false);
        mockMount.setGlobalActive(false);
        mockAbility.setGlobalActive(false);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Only base(100%) + alignment(5%) + level(1%) should remain
        uint256 expectedMultiplier = 10_600; // 10000 + 500 + 100
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus with global deactivation");
    }

    function testCharacterSpecificBonuses() public {
        uint256 character1 = characterId;

        // Create second test character
        vm.startPrank(address(this));
        uint256 character2 = characterContract.mintCharacter(
            address(this), Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        // Set different bonuses for different characters
        mockPet.setCharacterBonus(character1, 3000); // 30%
        mockPet.setCharacterBonus(character2, 1000); // 10%
        mockPet.setActiveForCharacter(character1, true);
        mockPet.setActiveForCharacter(character2, true);
        mockMount.setActiveForCharacter(character2, true);
        mockAbility.setActiveForCharacter(character2, true);

        (, uint256 bonus1) = calculator.calculateTotalAttributes(character1);
        (, uint256 bonus2) = calculator.calculateTotalAttributes(character2);

        // Character 1: BASE(100%) + PET(30%) + MOUNT(15%) + ABILITY(20%) + ALIGNMENT(5%) + LEVEL(1%)
        assertEq(bonus1, 17_100, "Incorrect bonus for character 1"); // 10000 + 3000 + 1500 + 2000 + 500 + 100

        // Character 2: BASE(100%) + PET(10%) + MOUNT(15%) + ABILITY(20%) + ALIGNMENT(5%) + LEVEL(1%)
        assertEq(bonus2, 15_100, "Incorrect bonus for character 2"); // 10000 + 1000 + 1500 + 2000 + 500 + 100
    }

    function testBatchOperations() public {
        // Create multiple test characters
        uint256[] memory characters = new uint256[](3);
        characters[0] = characterId;

        vm.startPrank(address(this));
        characters[1] = characterContract.mintCharacter(
            address(this), Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH
        );
        characters[2] = characterContract.mintCharacter(
            address(this), Types.Stats({ strength: 10, agility: 8, magic: 6 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        uint256[] memory bonuses = new uint256[](3);
        bonuses[0] = 1000; // 10%
        bonuses[1] = 2000; // 20%
        bonuses[2] = 3000; // 30%

        // Set different bonuses for multiple characters
        mockPet.batchSetCharacterBonuses(characters, bonuses);
        mockPet.batchSetActiveForCharacters(characters, true);
        mockMount.batchSetActiveForCharacters(characters, true);
        mockAbility.batchSetActiveForCharacters(characters, true);

        for (uint256 i = 0; i < characters.length; i++) {
            (, uint256 bonus) = calculator.calculateTotalAttributes(characters[i]);
            // BASE(100%) + MOUNT(15%) + ABILITY(20%) + ALIGNMENT(5%) + LEVEL(1%) + PET(varies)
            uint256 expected = 14_100 + bonuses[i]; // 10000 + 1500 + 2000 + 500 + 100 + pet bonus
            assertEq(bonus, expected, string.concat("Incorrect bonus for character ", vm.toString(i + 1)));
        }
    }

    function testProviderManagement() public {
        // Remove a provider
        vm.startPrank(address(this));
        calculator.removeProvider(address(mockPet));
        vm.stopPrank();

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Should not include pet bonus
        uint256 expectedMultiplier = 14_100; // 10000 + 1500 + 2000 + 500 + 100
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus after removing provider");

        // Re-add the provider
        vm.startPrank(address(this));
        calculator.addProvider(address(mockPet));
        vm.stopPrank();

        (, bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        expectedMultiplier = 16_100; // 10000 + 2000 + 1500 + 2000 + 500 + 100
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus after re-adding provider");
    }

    function testZeroBonusCase() public {
        // Set all bonuses to zero
        mockPet.setDefaultBonus(0);
        mockMount.setDefaultBonus(0);
        mockAbility.setDefaultBonus(0);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Should only have base + alignment + level
        assertEq(bonusMultiplier, 10_600, "Should only have base multiplier + alignment + level");
    }

    function testBaseStats() public {
        (Types.Stats memory totalStats,) = calculator.calculateTotalAttributes(characterId);

        // Base stats should be multiplied by total bonus multiplier (16100 = 161%)
        // Perform multiplication before division to maintain precision
        uint256 expectedStrength = (10 * uint256(16_100)) / uint256(10_000);
        uint256 expectedAgility = (8 * uint256(16_100)) / uint256(10_000);
        uint256 expectedMagic = (6 * uint256(16_100)) / uint256(10_000);

        assertEq(totalStats.strength, expectedStrength, "Incorrect strength calculation");
        assertEq(totalStats.agility, expectedAgility, "Incorrect agility calculation");
        assertEq(totalStats.magic, expectedMagic, "Incorrect magic calculation");
    }
}
