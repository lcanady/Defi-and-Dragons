// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, Vm } from "lib/forge-std/src/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Pet } from "../src/pets/Pet.sol";
import { Mount } from "../src/pets/Mount.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { AttributeCalculator } from "../src/attributes/AttributeCalculator.sol";
import { Types } from "../src/interfaces/Types.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { ArcaneCrafting } from "../src/amm/ArcaneCrafting.sol";
import { TestHelper } from "./helpers/TestHelper.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract AttributeSystemTest is Test, TestHelper, IERC721Receiver, IERC1155Receiver {
    using Strings for uint256;

    // State variables
    Character public character;
    Equipment public equipment;
    Pet public pet;
    Mount public mount;
    Ability public ability;
    AttributeCalculator public calculator;
    ItemDrop public itemDrop;
    ArcaneCrafting public crafting;
    ProvableRandom public random;

    // Constants
    uint256 public constant BASE_POINTS = 10_000; // 100% in basis points

    // Events for testing
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);

    address public owner;
    address public user;
    uint256 public characterId;
    Types.Stats public baseStats;

    // Test equipment IDs
    uint256 public weaponId;
    uint256 public armorId;

    // Implement onERC721Received
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement IERC1155Receiver
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

    // Helper function to deploy core contracts
    function deployContracts() private {
        // Deploy core contracts
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));

        // Deploy providers
        pet = new Pet(address(character));
        mount = new Mount(address(character));
        ability = new Ability(address(character));

        // Deploy calculator
        calculator = new AttributeCalculator(address(character), address(equipment));

        // Set up provider permissions and add to calculator
        vm.startPrank(owner);
        pet.transferOwnership(owner);
        mount.transferOwnership(owner);
        ability.transferOwnership(owner);
        calculator.addProvider(address(pet));
        calculator.addProvider(address(mount));
        calculator.addProvider(address(ability));
        calculator.setMountContract(address(mount));
        vm.stopPrank();
    }

    // Helper function to deploy and setup ItemDrop system
    function setupItemDropSystem() private {
        itemDrop = new ItemDrop();
        itemDrop.initialize(address(equipment));
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
    }

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        deployContracts();
        setupItemDropSystem();

        // Create a character
        characterId = character.mintCharacter(user, Types.Alignment.STRENGTH);

        // Create test equipment
        weaponId = equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0 // magic bonus
        );

        armorId = equipment.createEquipment(
            "Test Armor",
            "A test armor",
            0, // strength bonus
            5, // agility bonus
            0 // magic bonus
        );
    }

    function testVRFWithModifiers() public {
        // Create test items first
        vm.startPrank(owner);
        for (uint256 i = 0; i < 5; i++) {
            equipment.createEquipment(
                string(abi.encodePacked("Test Item ", i.toString())),
                string(abi.encodePacked("A test item #", i.toString())),
                5, // strength bonus
                0, // agility bonus
                0 // magic bonus
            );
        }
        vm.stopPrank();

        uint256 abilityId = ability.createAbility(
            "VRF Master",
            0, // No AMM fee reduction
            0, // No crafting boost
            2000, // 20% VRF cost reduction
            0, // No cooldown reduction
            1 // Level 1 required
        );

        vm.startPrank(user);
        address walletAddress = address(character.characterWallets(characterId));
        ability.learnAbility(characterId, abilityId);

        // Initialize seed for the wallet address
        vm.startPrank(walletAddress);
        itemDrop.initializeSeed(bytes32(uint256(1))); // Using a constant seed for testing
        vm.stopPrank();

        vm.startPrank(user);
        // Start recording logs
        vm.recordLogs();

        // Request random drop
        uint256 requestId = itemDrop.requestRandomDrop(walletAddress, 0);
        assertTrue(requestId > 0, "Request ID should be greater than 0");

        // Check for ItemDropped event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool itemDropped = false;
        uint256 droppedItemId;
        uint256 droppedAmount;
        address droppedPlayer;

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ItemDropped(address,uint256,uint256)")) {
                itemDropped = true;
                droppedPlayer = address(uint160(uint256(entries[i].topics[1])));
                droppedItemId = uint256(entries[i].topics[2]);
                droppedAmount = abi.decode(entries[i].data, (uint256));
                break;
            }
        }

        assertTrue(itemDropped, "Should have dropped an item");
        assertEq(droppedPlayer, walletAddress, "Item dropped to wrong player");
        assertTrue(droppedItemId > 0 && droppedItemId <= 5, "Invalid item ID");
        assertEq(droppedAmount, 1, "Invalid amount");

        // Verify the player received the item
        uint256 balance = equipment.balanceOf(walletAddress, droppedItemId);
        assertEq(balance, 1, "Player should have received the item");

        vm.stopPrank();
    }
}
