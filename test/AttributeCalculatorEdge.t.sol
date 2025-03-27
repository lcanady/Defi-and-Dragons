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

contract AttributeCalculatorEdgeTest is Test, IERC721Receiver, IERC1155Receiver {
    AttributeCalculator public calculator;
    Character public character;
    Equipment public equipment;
    MockAttributeProvider public mockProvider;
    ProvableRandom public random;

    address public owner;
    uint256 public characterId;
    uint256 public characterId2;
    uint256 public characterId3;
    uint256 public characterId4;
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    bytes32 public context;

    event AttributesCalculated(
        uint256 indexed characterId,
        uint256 strength,
        uint256 agility,
        uint256 magic,
        uint256 bonusMultiplier
    );
    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);

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
        user4 = address(0x4);

        // Deploy contracts
        random = new ProvableRandom();
        equipment = new Equipment(address(this));
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));
        calculator = new AttributeCalculator(address(character), address(equipment));
        mockProvider = new MockAttributeProvider(2000); // 20% bonus

        // Set context for all operations
        context = bytes32(uint256(uint160(address(character))));

        // Reset random seed for owner
        random.resetSeed(owner, context);
        random.initializeSeed(owner, context);

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
        characterId = character.mintCharacter(user1, Types.Alignment.STRENGTH);
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
        characterId2 = character.mintCharacter(user2, Types.Alignment.AGILITY);
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
        characterId3 = character.mintCharacter(user3, Types.Alignment.MAGIC);
        vm.stopPrank();

        // Create test character for user4
        vm.startPrank(user4);
        random.resetSeed(user4, context);
        random.initializeSeed(user4, context);
        uint256[] memory numbers4 = new uint256[](3);
        numbers4[0] = 15; // High strength
        numbers4[1] = 10;
        numbers4[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user4, context, 3),
            abi.encode(numbers4)
        );
        characterId4 = character.mintCharacter(user4, Types.Alignment.STRENGTH);
        vm.stopPrank();
    }

    function testErrorCases() public {
        // Test invalid provider (zero address)
        vm.expectRevert(AttributeCalculator.InvalidProvider.selector);
        calculator.addProvider(address(0));

        // Test adding a provider works
        calculator.addProvider(address(mockProvider));
        assertTrue(calculator.providers(address(mockProvider)), "Provider should be added");
        
        // Test adding the same provider again - should succeed silently (not revert)
        calculator.addProvider(address(mockProvider));
        assertTrue(calculator.providers(address(mockProvider)), "Provider should still exist");
        
        // Remove the provider and verify it's removed
        calculator.removeProvider(address(mockProvider));
        assertFalse(calculator.providers(address(mockProvider)), "Provider should be removed");
        
        // Test removing the same provider again - should succeed silently (not revert)
        calculator.removeProvider(address(mockProvider));
        assertFalse(calculator.providers(address(mockProvider)), "Provider should still be removed");
        
        // Test removing a non-existent provider - should also succeed silently
        address nonExistentProvider = address(0x123);
        calculator.removeProvider(nonExistentProvider);
        assertFalse(calculator.providers(nonExistentProvider), "Provider should not exist");
    }

    function testAlignmentBonusEdgeCases() public {
        // Test equal stats case (no alignment bonus)
        address user5 = address(0x5);
        vm.startPrank(user5);
        random.resetSeed(user5, context);
        random.initializeSeed(user5, context);

        // Mock random numbers for equal stats
        uint256[] memory numbers5 = new uint256[](3);
        numbers5[0] = 10;
        numbers5[1] = 10;
        numbers5[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user5, context, 3),
            abi.encode(numbers5)
        );
        uint256 equalStatsChar = character.mintCharacter(user5, Types.Alignment.STRENGTH);
        vm.stopPrank();

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(equalStatsChar);

        // Should only have base(100%) + level(1%) without alignment bonus
        assertEq(bonusMultiplier, 10_100, "Should not get alignment bonus with equal stats");

        // Test mismatched alignment and stats
        address user6 = address(0x6);
        vm.startPrank(user6);
        random.resetSeed(user6, context);
        random.initializeSeed(user6, context);

        // Mock random numbers for mismatched stats
        uint256[] memory numbers6 = new uint256[](3);
        numbers6[0] = 10;
        numbers6[1] = 15; // Higher agility but STRENGTH alignment
        numbers6[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user6, context, 3),
            abi.encode(numbers6)
        );
        uint256 mismatchedChar = character.mintCharacter(user6, Types.Alignment.STRENGTH);
        vm.stopPrank();

        (, bonusMultiplier) = calculator.calculateTotalAttributes(mismatchedChar);

        // Should not get alignment bonus when highest stat doesn't match alignment
        assertEq(bonusMultiplier, 10_100, "Should not get alignment bonus with mismatched stats");
    }

    function testMaxLevelBonus() public {
        // Setup character at level 100
        (Types.Stats memory baseStats,,) = character.getCharacter(characterId);
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(
                Types.Stats({ strength: 15, agility: 8, magic: 6 }),
                Types.EquipmentSlots(0, 0),
                Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 100, 0)
            )
        );
        
        // Calculate bonus with level 100 character
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Restore the original character state
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(baseStats, Types.EquipmentSlots(0, 0), Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0))
        );
        
        // Base(100%) + Alignment(5%) + Level(100 * 1%)
        assertEq(bonusMultiplier, 20_500, "Incorrect bonus with level 100 character");
    }

    function testProviderManagementEdgeCases() public {
        // Test adding same provider multiple times
        calculator.addProvider(address(mockProvider));
        calculator.addProvider(address(mockProvider));

        // Should only count bonus once
        mockProvider.setActiveForCharacter(characterId, true);
        
        // Setup stat mocks so alignment bonus applies consistently
        (Types.Stats memory baseStats,,) = character.getCharacter(characterId);
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(
                Types.Stats({ strength: 15, agility: 8, magic: 6 }),
                Types.EquipmentSlots(0, 0),
                Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0)
            )
        );
        
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Base(100%) + Provider(20%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 12_600, "Provider bonus should only be counted once");

        // Test removing non-existent provider
        calculator.removeProvider(address(0x123));
        
        // Re-apply the mock since it was cleared during the previous call
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(
                Types.Stats({ strength: 15, agility: 8, magic: 6 }),
                Types.EquipmentSlots(0, 0),
                Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0)
            )
        );
        
        (, bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Should maintain same bonus
        assertEq(bonusMultiplier, 12_600, "Removing non-existent provider should not affect bonus");
    }

    function testActiveProvidersLimit() public {
        // Setup with the right stat values to get alignment bonus
        (Types.Stats memory baseStats,,) = character.getCharacter(characterId);
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(Types.Stats({
                strength: 15,
                agility: 8,
                magic: 6
            }), Types.EquipmentSlots(0, 0), Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0))
        );
        
        // Add maximum number of providers (100)
        for (uint256 i = 0; i < 100; i++) {
            MockAttributeProvider provider = new MockAttributeProvider(100); // 1% bonus
            calculator.addProvider(address(provider));
            provider.setActiveForCharacter(characterId, true);
        }

        // Calculate bonus with maximum providers
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Restore the mock
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(baseStats, Types.EquipmentSlots(0, 0), Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0))
        );
        
        // Base(100%) + Providers(100 * 1%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 20_600, "Incorrect bonus with 100 providers");
    }

    function testMaximumProviders() public {
        // Setup with the right stat values to get alignment bonus
        (Types.Stats memory baseStats,,) = character.getCharacter(characterId);
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(Types.Stats({
                strength: 15,
                agility: 8,
                magic: 6
            }), Types.EquipmentSlots(0, 0), Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0))
        );
        
        // Add maximum number of providers
        for (uint256 i = 0; i < 10; i++) {
            MockAttributeProvider provider = new MockAttributeProvider(1000); // 10% bonus
            calculator.addProvider(address(provider));
            provider.setActiveForCharacter(characterId, true);
        }

        // Calculate bonus with maximum providers
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Restore the mock
        vm.mockCall(
            address(character),
            abi.encodeWithSelector(Character.getCharacter.selector, characterId),
            abi.encode(baseStats, Types.EquipmentSlots(0, 0), Types.CharacterState(100, 0, 0, 0, Types.Alignment.STRENGTH, 1, 0))
        );
        
        // Base(100%) + Providers(10 * 10%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 20_600, "Incorrect bonus with maximum providers");
    }

    function testEventEmission() public {
        // Test AttributesCalculated event
        vm.expectEmit(true, true, true, true);
        emit AttributesCalculated(
            characterId,
            15, // strength
            15, // agility
            15, // magic
            10_100 // base(100%) + level(1%)
        );
        calculator.calculateTotalAttributes(characterId);

        // Test ProviderAdded event
        vm.expectEmit(true, true, true, true);
        emit ProviderAdded(address(mockProvider));
        calculator.addProvider(address(mockProvider));

        // Test ProviderRemoved event
        vm.expectEmit(true, true, true, true);
        emit ProviderRemoved(address(mockProvider));
        calculator.removeProvider(address(mockProvider));
    }

    function testComplexStatInteractions() public {
        // Mock random numbers that will result in desired stats after scaling
        // To get a final stat of X, we need to mock (X - MIN_STAT) + (MAX_STAT - MIN_STAT + 1)
        // For example, to get 18 after scaling, we mock 13 + 14 = 27
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 27; // Will result in 18 strength after scaling
        numbers[1] = 24; // Will result in 15 agility after scaling
        numbers[2] = 21; // Will result in 12 magic after scaling
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), owner, context, 3),
            abi.encode(numbers)
        );

        // Create a character with STRENGTH alignment since strength is highest
        uint256 testCharacterId = character.mintCharacter(address(this), Types.Alignment.STRENGTH);

        // Get raw stats
        Types.Stats memory rawStats = calculator.getRawStats(testCharacterId);

        // Check raw stats
        assertEq(rawStats.strength, 18, "Incorrect base strength");
        assertEq(rawStats.agility, 15, "Incorrect base agility");
        assertEq(rawStats.magic, 12, "Incorrect base magic");

        // Get total stats with multiplier
        (Types.Stats memory totalStats, uint256 multiplier) = calculator.calculateTotalAttributes(testCharacterId);

        // Verify multiplier includes alignment bonus
        assertEq(multiplier, 10_600, "Incorrect multiplier"); // 10000 + 500 (alignment) + 100 (level)

        // Verify final stats
        assertEq(totalStats.strength, (18 * multiplier) / 10_000, "Incorrect final strength");
        assertEq(totalStats.agility, (15 * multiplier) / 10_000, "Incorrect final agility");
        assertEq(totalStats.magic, (12 * multiplier) / 10_000, "Incorrect final magic");
    }

    function testMockRandomNumbers() public {
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 10;
        numbers[2] = 10;

        // Mock the random number generation
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user1, context, 3),
            abi.encode(numbers)
        );
    }

    function testProviderManagement() public {
        // Test adding a provider
        calculator.addProvider(address(mockProvider));
        assertTrue(calculator.providers(address(mockProvider)), "Provider should be added");

        // Test removing a provider
        calculator.removeProvider(address(mockProvider));
        assertFalse(calculator.providers(address(mockProvider)), "Provider should be removed");
    }
}
