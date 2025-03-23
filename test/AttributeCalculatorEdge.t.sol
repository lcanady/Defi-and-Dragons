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

    event AttributesCalculated(
        uint256 indexed characterId,
        uint256 totalStrength,
        uint256 totalAgility,
        uint256 totalMagic,
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
        vm.clearMockedCalls();

        // Deploy core contracts
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));

        // Deploy calculator
        calculator = new AttributeCalculator(address(character), address(equipment));

        // Deploy mock provider
        mockProvider = new MockAttributeProvider(2000); // 20% bonus

        // Initialize seed for test contract
        bytes32 ownerSeed = keccak256(abi.encodePacked(block.timestamp, owner, uint256(0)));
        vm.startPrank(owner);
        random.initializeSeed(ownerSeed);
        vm.stopPrank();

        // Create characters with unique seeds
        address user1 = address(0x1);
        address user2 = address(0x2);
        address user3 = address(0x3);
        address user4 = address(0x4);

        // Mint character for user1
        vm.startPrank(user1);
        bytes32 seed1 = keccak256(abi.encodePacked(block.timestamp, user1, uint256(1)));
        random.initializeSeed(seed1);
        uint256[] memory numbers1 = new uint256[](3);
        numbers1[0] = 15; // High strength
        numbers1[1] = 12; // Medium agility
        numbers1[2] = 10; // Low magic
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(numbers1)
        );
        characterId = character.mintCharacter(user1, Types.Alignment.STRENGTH);
        // Set character stats explicitly to ensure alignment bonus
        vm.stopPrank();

        vm.startPrank(owner);
        character.updateStats(characterId, Types.Stats({
            strength: 15,
            agility: 12,
            magic: 10
        }));
        vm.stopPrank();

        // Mint character for user2
        vm.startPrank(user2);
        bytes32 seed2 = keccak256(abi.encodePacked(block.timestamp, user2, uint256(2)));
        random.initializeSeed(seed2);
        uint256[] memory numbers2 = new uint256[](3);
        numbers2[0] = 10;
        numbers2[1] = 15; // High agility
        numbers2[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(numbers2)
        );
        uint256 equalStatsChar = character.mintCharacter(user2, Types.Alignment.MAGIC);
        vm.stopPrank();

        // Mint character for user3
        vm.startPrank(user3);
        bytes32 seed3 = keccak256(abi.encodePacked(block.timestamp, user3, uint256(3)));
        random.initializeSeed(seed3);
        uint256[] memory numbers3 = new uint256[](3);
        numbers3[0] = 10;
        numbers3[1] = 10;
        numbers3[2] = 15; // High magic
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(numbers3)
        );
        uint256 mismatchedChar = character.mintCharacter(user3, Types.Alignment.MAGIC);
        vm.stopPrank();

        // Mint character for user4
        vm.startPrank(user4);
        bytes32 seed4 = keccak256(abi.encodePacked(block.timestamp, user4, uint256(4)));
        random.initializeSeed(seed4);
        uint256[] memory numbers4 = new uint256[](3);
        numbers4[0] = 15; // High strength
        numbers4[1] = 10;
        numbers4[2] = 10;
        vm.mockCall(
            address(random),
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(numbers4)
        );
        uint256 testCharacterId = character.mintCharacter(user4, Types.Alignment.MAGIC);
        vm.stopPrank();
    }

    function testErrorCases() public {
        // Test invalid provider (zero address)
        vm.expectRevert(AttributeCalculator.InvalidProvider.selector);
        calculator.addProvider(address(0));

        // Test invalid stat type
        vm.expectRevert(AttributeCalculator.InvalidStatType.selector);
        calculator.getStatBonus(characterId, 3);
    }

    function testAlignmentBonusEdgeCases() public {
        // Test equal stats case (no alignment bonus)
        address user5 = address(0x5);
        vm.startPrank(user5);
        bytes32 seed5 = keccak256(abi.encodePacked(block.timestamp, user5, uint256(5)));
        random.initializeSeed(seed5);
        uint256 equalStatsChar = character.mintCharacter(
            user5, Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(equalStatsChar);

        // Should only have base(100%) + level(1%) without alignment bonus
        assertEq(bonusMultiplier, 10_100, "Should not get alignment bonus with equal stats");

        // Test mismatched alignment and stats
        address user6 = address(0x6);
        vm.startPrank(user6);
        bytes32 seed6 = keccak256(abi.encodePacked(block.timestamp, user6, uint256(6)));
        random.initializeSeed(seed6);
        uint256 mismatchedChar = character.mintCharacter(
            user6, Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        (, bonusMultiplier) = calculator.calculateTotalAttributes(mismatchedChar);

        // Should not get alignment bonus when highest stat doesn't match alignment
        assertEq(bonusMultiplier, 10_100, "Should not get alignment bonus with mismatched stats");
    }

    function testProviderManagementEdgeCases() public {
        // Test adding same provider multiple times
        calculator.addProvider(address(mockProvider));
        calculator.addProvider(address(mockProvider));

        // Should only count bonus once
        mockProvider.setActiveForCharacter(characterId, true);
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Base(100%) + Provider(20%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 12_600, "Provider bonus should only be counted once");

        // Test removing non-existent provider
        calculator.removeProvider(address(0x123));
        (, bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Should maintain same bonus
        assertEq(bonusMultiplier, 12_600, "Removing non-existent provider should not affect bonus");
    }

    function testMaxLevelBonus() public {
        // Test very high level character
        Types.CharacterState memory highLevelState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 100
        });
        character.updateState(characterId, highLevelState);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Base(100%) + Level(100%) + Alignment(5%)
        assertEq(bonusMultiplier, 20_500, "Incorrect bonus for level 100 character");
    }

    function testEventEmission() public {
        // Test AttributesCalculated event
        vm.expectEmit(true, true, true, true);
        emit AttributesCalculated(
            characterId,
            15, // strength
            12, // agility
            10, // magic
            10_600 // base(100%) + alignment(5%) + level(1%)
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
            abi.encodeWithSelector(ProvableRandom.generateNumbers.selector, 3),
            abi.encode(numbers)
        );

        // Create a character with STRENGTH alignment since strength is highest
        uint256 testCharacterId = character.mintCharacter(
            address(this), Types.Alignment.STRENGTH
        );

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

    function testActiveProvidersLimit() public {
        // Test adding maximum number of providers
        address[] memory testProviders = new address[](100);
        for (uint160 i = 1; i <= 100; i++) {
            MockAttributeProvider mock = new MockAttributeProvider(100); // 1% bonus each
            testProviders[i - 1] = address(mock);
            calculator.addProvider(address(mock));
        }

        // Verify all providers are active
        address[] memory activeProviders = calculator.getActiveProviders();
        assertEq(activeProviders.length, 100, "Should have maximum providers active");

        // Verify total bonus calculation works with max providers
        for (uint160 i = 0; i < testProviders.length; i++) {
            MockAttributeProvider(testProviders[i]).setActiveForCharacter(characterId, true);
        }

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Base(100%) + Providers(100 * 1%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 20_600, "Incorrect bonus with maximum providers");
    }
}
