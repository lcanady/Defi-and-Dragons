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
import { ProvableRandom } from "../src/ProvableRandom.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract AttributeCalculatorMockTest is Test, IERC721Receiver, IERC1155Receiver {
    AttributeCalculator public calculator;
    Character public characterContract;
    Equipment public equipmentContract;
    MockAttributeProvider public mockProvider;
    ProvableRandom public random;

    address public owner;
    address public user1;
    address public user2;
    address public user3;
    uint256 public characterId;
    uint256 public characterId2;
    uint256 public characterId3;
    bytes32 public context;

    event AttributesCalculated(
        uint256 indexed characterId,
        uint256 strength,
        uint256 agility,
        uint256 magic,
        uint256 bonusMultiplier
    );

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
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);

        // Deploy contracts
        random = new ProvableRandom();
        characterContract = new Character(address(0), address(random));
        calculator = new AttributeCalculator(address(characterContract), address(0));
        mockProvider = new MockAttributeProvider(2000); // 20% bonus

        // Set context for all operations
        context = bytes32(uint256(uint160(address(characterContract))));

        // Reset random seed for owner
        random.resetSeed(address(this), context);
        random.initializeSeed(address(this), context);

        // Create test character for user1
        vm.startPrank(user1);
        random.resetSeed(user1, context);
        random.initializeSeed(user1, context);

        // Mock the random number generation
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 21; // Will result in 12 strength after scaling
        numbers[1] = 21; // Will result in 12 agility after scaling
        numbers[2] = 21; // Will result in 12 magic after scaling
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user1, context, 3),
            abi.encode(numbers)
        );
        characterId = characterContract.mintCharacter(user1, Types.Alignment.STRENGTH);
        vm.stopPrank();

        // Create test character for user2
        vm.startPrank(user2);
        random.resetSeed(user2, context);
        random.initializeSeed(user2, context);
        uint256[] memory numbers2 = new uint256[](3);
        numbers2[0] = 10;
        numbers2[1] = 15; // High agility
        numbers2[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user2, context, 3),
            abi.encode(numbers2)
        );
        characterId2 = characterContract.mintCharacter(user2, Types.Alignment.AGILITY);
        vm.stopPrank();

        // Create test character for user3
        vm.startPrank(user3);
        random.resetSeed(user3, context);
        random.initializeSeed(user3, context);
        uint256[] memory numbers3 = new uint256[](3);
        numbers3[0] = 10;
        numbers3[1] = 10;
        numbers3[2] = 15; // High magic
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user3, context, 3),
            abi.encode(numbers3)
        );
        characterId3 = characterContract.mintCharacter(user3, Types.Alignment.MAGIC);
        vm.stopPrank();

        // Deploy mock providers with default bonuses
        mockProvider = new MockAttributeProvider(2000); // 20% bonus

        // Deploy calculator with real contracts
        calculator = new AttributeCalculator(address(characterContract), address(equipmentContract));

        // Add mock providers to calculator
        vm.startPrank(address(this));
        calculator.addProvider(address(mockProvider));
        vm.stopPrank();

        // Set initial active states
        mockProvider.setActiveForCharacter(characterId, true);
    }

    function testAllBonusesActive() public {
        Types.Stats memory baseStats = Types.Stats({
            strength: 10,
            agility: 10,
            magic: 10
        });

        // Setup initial stats and character
        Types.Stats memory outputStats;
        uint256 expectedMultiplier;

        // Character with all bonuses
        // Base (100%) + Pet (20%) + Level (1%)
        expectedMultiplier = 12_100;

        calculateAndAssert(
            baseStats,
            expectedMultiplier,
            "All bonuses should be active"
        );
    }

    function testIndividualDeactivation() public {
        Types.Stats memory baseStats = Types.Stats({
            strength: 10,
            agility: 10,
            magic: 10
        });

        // Start with all bonuses active
        // Base (100%) + Pet (20%) + Level (1%)
        uint256 expectedMultiplier = 12_100;

        calculateAndAssert(
            baseStats,
            expectedMultiplier,
            "All bonuses should be active initially"
        );

        // Deactivate pet bonus and test again
        mockProvider.setActiveForCharacter(characterId, false);
        
        // Base (100%) + Level (1%)
        expectedMultiplier = 10_100;
        
        calculateAndAssert(
            baseStats,
            expectedMultiplier,
            "Pet bonus should be deactivated"
        );

        // Reactivate pet bonus
        mockProvider.setActiveForCharacter(characterId, true);
        
        // Base (100%) + Pet (20%) + Level (1%)
        expectedMultiplier = 12_100;
        
        calculateAndAssert(
            baseStats,
            expectedMultiplier,
            "Pet bonus should be reactivated"
        );
    }

    function testGlobalDeactivation() public {
        // Test global deactivation
        mockProvider.setGlobalActive(false);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        uint256 expectedMultiplier = 10_100; // Base(100%) + Level(1%)
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus with all providers deactivated");
    }

    function testCharacterSpecificBonuses() public {
        // Create two test characters
        uint256 character1 = characterId;
        uint256 character2 = characterId2;

        // Set different bonuses for different characters
        mockProvider.setCharacterBonus(character1, 3000); // 30%
        mockProvider.setCharacterBonus(character2, 1000); // 10%
        mockProvider.setActiveForCharacter(character1, true);
        mockProvider.setActiveForCharacter(character2, true);

        (, uint256 bonus1) = calculator.calculateTotalAttributes(character1);
        (, uint256 bonus2) = calculator.calculateTotalAttributes(character2);

        assertEq(bonus1, 13_100, "Incorrect bonus for character 1"); // Base(100%) + Bonus(30%) + Level(1%)
        assertEq(bonus2, 11_100, "Incorrect bonus for character 2"); // Base(100%) + Bonus(10%) + Level(1%)
    }

    function testBatchBonusManagement() public {
        uint256[] memory characters = new uint256[](3);
        characters[0] = characterId;
        characters[1] = characterId2;
        characters[2] = characterId3;

        uint256[] memory bonuses = new uint256[](3);
        bonuses[0] = 1000; // 10%
        bonuses[1] = 2000; // 20%
        bonuses[2] = 3000; // 30%

        // Set different bonuses for multiple characters
        mockProvider.batchSetCharacterBonuses(characters, bonuses);
        mockProvider.batchSetActiveForCharacters(characters, true);

        for (uint256 i = 0; i < characters.length; i++) {
            (, uint256 bonus) = calculator.calculateTotalAttributes(characters[i]);
            uint256 expectedBonus = 10_100 + bonuses[i]; // Base(100%) + Bonus(X%) + Level(1%)
            assertEq(bonus, expectedBonus, string.concat("Incorrect bonus for character ", Strings.toString(i)));
        }
    }

    function testProviderManagement() public {
        // Remove the provider
        vm.startPrank(address(this));
        calculator.removeProvider(address(mockProvider));
        vm.stopPrank();

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Should not include provider bonus
        uint256 expectedMultiplier = 10_100; // Base(100%) + Level(1%)
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus after removing provider");

        // Re-add the provider
        vm.startPrank(address(this));
        calculator.addProvider(address(mockProvider));
        vm.stopPrank();

        mockProvider.setActiveForCharacter(characterId, true);
        (, bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        expectedMultiplier = 12_100; // Base(100%) + Bonus(20%) + Level(1%)
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus after re-adding provider");
    }

    function testZeroBonusCase() public {
        // Set all bonuses to zero
        mockProvider.setDefaultBonus(0);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        uint256 expectedMultiplier = 10_100; // Base(100%) + Level(1%)
        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus with zero provider bonus");
    }

    function testBaseStats() public {
        Types.Stats memory baseStats = Types.Stats({
            strength: 10,
            agility: 7,
            magic: 15
        });

        // Total multiplier: Base (100%) + Pet (20%) + Level (1%)
        uint256 expectedMultiplier = 12_100;
        
        (Types.Stats memory calculatedStats, uint256 multiplier) = calculateWithMocks(baseStats);
        
        assertEq(multiplier, expectedMultiplier, "Incorrect total multiplier");
        
        // Expected stats with a multiplier of 12_100 (121%)
        uint256 expectedStrength = (baseStats.strength * expectedMultiplier) / 10_000;
        uint256 expectedAgility = (baseStats.agility * expectedMultiplier) / 10_000;
        uint256 expectedMagic = (baseStats.magic * expectedMultiplier) / 10_000;
        
        assertEq(calculatedStats.strength, expectedStrength, "Incorrect strength calculation");
        assertEq(calculatedStats.agility, expectedAgility, "Incorrect agility calculation");
        assertEq(calculatedStats.magic, expectedMagic, "Incorrect magic calculation");
    }

    function testDeactivatedBonuses() public {
        Types.Stats memory baseStats = Types.Stats({
            strength: 10,
            agility: 10,
            magic: 10
        });

        // Deactivate pet provider
        mockProvider.setActiveForCharacter(characterId, false);
        
        // Base (100%) + Level (1%)
        uint256 expectedMultiplier = 10_100;
        
        calculateAndAssert(
            baseStats,
            expectedMultiplier,
            "Correct multiplier with pet provider deactivated"
        );
    }

    // Helper function to calculate stats with mocked base stats
    function calculateWithMocks(Types.Stats memory baseStats) internal returns (Types.Stats memory, uint256) {
        // Setup character base stats
        vm.mockCall(
            address(characterContract),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(
                baseStats, 
                Types.EquipmentSlots(0, 0), 
                Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0)
            )
        );
        
        // Call the calculator
        (Types.Stats memory calculatedStats, uint256 multiplier) = calculator.calculateTotalAttributes(characterId);
        
        return (calculatedStats, multiplier);
    }
    
    // Helper function to calculate and assert results
    function calculateAndAssert(
        Types.Stats memory baseStats,
        uint256 expectedMultiplier,
        string memory message
    ) internal {
        (Types.Stats memory calculatedStats, uint256 multiplier) = calculateWithMocks(baseStats);
        assertEq(multiplier, expectedMultiplier, message);
    }
}
