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

contract AttributeCalculatorEdgeTest is Test, IERC721Receiver, IERC1155Receiver {
    AttributeCalculator public calculator;
    Character public character;
    Equipment public equipment;
    MockAttributeProvider public mockProvider;

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement ERC1155Receiver
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    function setUp() public {
        owner = address(this);
        
        // Deploy core contracts
        equipment = new Equipment();
        character = new Character(address(equipment));
        equipment.setCharacterContract(address(character));
        
        // Deploy calculator
        calculator = new AttributeCalculator(
            address(character),
            address(equipment)
        );

        // Deploy mock provider
        mockProvider = new MockAttributeProvider(2000); // 20% bonus

        // Create test character
        characterId = character.mintCharacter(
            owner,
            Types.Stats({
                strength: 10,
                agility: 8,
                magic: 6
            }),
            Types.Alignment.STRENGTH
        );
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
        vm.startPrank(owner);
        uint256 equalStatsChar = character.mintCharacter(
            owner,
            Types.Stats({
                strength: 10,
                agility: 10,
                magic: 10
            }),
            Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(equalStatsChar);
        
        // Should only have base(100%) + level(1%) without alignment bonus
        assertEq(bonusMultiplier, 10100, "Should not get alignment bonus with equal stats");

        // Test mismatched alignment and stats
        vm.startPrank(owner);
        uint256 mismatchedChar = character.mintCharacter(
            owner,
            Types.Stats({
                strength: 6,
                agility: 10,
                magic: 8
            }),
            Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        (, bonusMultiplier) = calculator.calculateTotalAttributes(mismatchedChar);
        
        // Should not get alignment bonus when highest stat doesn't match alignment
        assertEq(bonusMultiplier, 10100, "Should not get alignment bonus with mismatched stats");
    }

    function testProviderManagementEdgeCases() public {
        // Test adding same provider multiple times
        calculator.addProvider(address(mockProvider));
        calculator.addProvider(address(mockProvider));

        // Should only count bonus once
        mockProvider.setActiveForCharacter(characterId, true);
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Base(100%) + Provider(20%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 12600, "Provider bonus should only be counted once");

        // Test removing non-existent provider
        calculator.removeProvider(address(0x123));
        (, bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Should maintain same bonus
        assertEq(bonusMultiplier, 12600, "Removing non-existent provider should not affect bonus");
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
        assertEq(bonusMultiplier, 20500, "Incorrect bonus for level 100 character");
    }

    function testEventEmission() public {
        // Test AttributesCalculated event
        vm.expectEmit(true, true, true, true);
        emit AttributesCalculated(
            characterId,
            10, // base strength
            8,  // base agility
            6,  // base magic
            10600 // base(100%) + alignment(5%) + level(1%)
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
        // Create a character with specific stats
        uint256 testCharacterId = character.mintCharacter(
            address(this),
            Types.Stats({
                strength: 15,
                agility: 12,
                magic: 10
            }),
            Types.Alignment.STRENGTH
        );

        // Get raw stats
        Types.Stats memory rawStats = calculator.getRawStats(testCharacterId);
        
        // Check raw stats
        assertEq(rawStats.strength, 15, "Incorrect base strength");
        assertEq(rawStats.agility, 12, "Incorrect base agility");
        assertEq(rawStats.magic, 10, "Incorrect base magic");

        // Get total stats with multiplier
        (Types.Stats memory totalStats, uint256 multiplier) = calculator.calculateTotalAttributes(testCharacterId);

        // Verify multiplier includes alignment bonus
        assertEq(multiplier, 10600, "Incorrect multiplier"); // 10000 + 500 (alignment) + 100 (level)

        // Verify final stats
        assertEq(totalStats.strength, (15 * multiplier) / 10000, "Incorrect final strength");
        assertEq(totalStats.agility, (12 * multiplier) / 10000, "Incorrect final agility");
        assertEq(totalStats.magic, (10 * multiplier) / 10000, "Incorrect final magic");
    }

    function testActiveProvidersLimit() public {
        // Test adding maximum number of providers
        address[] memory testProviders = new address[](100);
        for(uint160 i = 1; i <= 100; i++) {
            MockAttributeProvider mock = new MockAttributeProvider(100); // 1% bonus each
            testProviders[i-1] = address(mock);
            calculator.addProvider(address(mock));
        }

        // Verify all providers are active
        address[] memory activeProviders = calculator.getActiveProviders();
        assertEq(activeProviders.length, 100, "Should have maximum providers active");

        // Verify total bonus calculation works with max providers
        for(uint160 i = 0; i < testProviders.length; i++) {
            MockAttributeProvider(testProviders[i]).setActiveForCharacter(characterId, true);
        }

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        
        // Base(100%) + Providers(100 * 1%) + Alignment(5%) + Level(1%)
        assertEq(bonusMultiplier, 20600, "Incorrect bonus with maximum providers");
    }
}
