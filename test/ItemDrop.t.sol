// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, Vm } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Equipment } from "../src/Equipment.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import { TestHelper } from "./helpers/TestHelper.sol";

contract ItemDropTest is Test, TestHelper {
    using Strings for uint256;

    ItemDrop public itemDrop;
    Equipment public equipment;
    VRFCoordinatorV2Mock public vrfCoordinator;

    address public owner;
    address public user;

    uint64 constant _SUBSCRIPTION_ID = 1;
    bytes32 constant _KEY_HASH = keccak256("test");
    uint32 constant _CALLBACK_GAS_LIMIT = 2_000_000;
    uint16 constant _REQUEST_CONFIRMATIONS = 3;
    uint32 constant _NUM_WORDS = 1;

    event RandomWordsRequested(uint256 indexed requestId, address indexed player);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint256 amount);

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy mock VRF Coordinator
        vrfCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether, // base fee
            1e9 // gas price link
        );

        // Create VRF subscription
        uint64 subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(
            subId, // Use the actual subId instead of _SUBSCRIPTION_ID
            100 ether
        );

        // Deploy contracts
        equipment = new Equipment();
        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            subId, // Use the actual subId instead of _SUBSCRIPTION_ID
            _KEY_HASH,
            _CALLBACK_GAS_LIMIT,
            _REQUEST_CONFIRMATIONS,
            _NUM_WORDS
        );

        // Add ItemDrop as consumer
        vrfCoordinator.addConsumer(subId, address(itemDrop)); // Use the actual subId

        // Initialize contracts
        equipment.setItemDrop(address(itemDrop));
        equipment.setCharacterContract(address(itemDrop));
        itemDrop.initialize(address(equipment));

        // Add debug logs
        console.log("ItemDrop address:", address(itemDrop));
        console.log("Equipment address:", address(equipment));
        console.log("Equipment contract in ItemDrop:", address(itemDrop.equipment()));

        // Create test items
        for (uint256 i = 1; i <= 5; i++) {
            equipment.createEquipment(
                string(abi.encodePacked("Test Item ", i.toString())),
                string(abi.encodePacked("A test item #", i.toString())),
                5, // strength bonus
                0, // agility bonus
                0 // magic bonus
            );
        }

        // Grant approval for ItemDrop to mint equipment
        vm.startPrank(owner);
        equipment.setApprovalForAll(address(itemDrop), true);
        vm.stopPrank();
    }

    function testRequestRandomDrop() public {
        vm.startPrank(user);
        vm.recordLogs();
        itemDrop.requestRandomDrop(user, 5000); // 50% drop rate bonus
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (uint256 requestId, bool found) = findRequestIdFromLogs(entries);
        vm.stopPrank();

        assertTrue(found, "Should have found request ID");
        assertTrue(requestId > 0, "Should have valid request ID");
    }

    function testRandomWordsFulfilled() public {
        vm.startPrank(user);
        vm.recordLogs();
        itemDrop.requestRandomDrop(user, 5000);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (uint256 requestId, bool found) = findRequestIdFromLogs(entries);
        vm.stopPrank();

        require(found, "Request ID not found");

        // Add debug logs
        console.log("Request ID:", requestId);
        console.log("User:", user);
        console.log("ItemDrop address:", address(itemDrop));
        console.log("Equipment address:", address(equipment));

        // Simulate VRF response with a random number that will trigger a drop
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12_345;
        vm.recordLogs();
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(itemDrop), randomWords);

        // Check if the request was fulfilled
        (address player, uint256 dropRateBonus, bool fulfilled) = itemDrop.dropRequests(requestId);
        console.log("Request fulfilled:", fulfilled);
        console.log("Player:", player);
        console.log("Drop rate bonus:", dropRateBonus);

        // Check if an item was dropped
        entries = vm.getRecordedLogs();
        bool itemDropped = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ItemDropped(address,uint256,uint256)")) {
                itemDropped = true;
                break;
            }
        }
        console.log("Item dropped:", itemDropped);

        assertTrue(fulfilled, "Request should be fulfilled");
        assertTrue(itemDropped, "Should have dropped an item");
    }

    function testDropItem() public {
        vm.startPrank(user);
        vm.recordLogs();
        itemDrop.requestRandomDrop(user, 5000);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (uint256 requestId, bool found) = findRequestIdFromLogs(entries);
        vm.stopPrank();

        require(found, "Request ID not found");

        // Add debug logs
        console.log("Request ID:", requestId);
        console.log("User:", user);
        console.log("ItemDrop address:", address(itemDrop));
        console.log("Equipment address:", address(equipment));

        // Use a random number that will trigger a drop (based on 50% base + 50% bonus = 100% drop rate)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12_345;
        vm.recordLogs();
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(itemDrop), randomWords);

        // Check for ItemDropped event
        entries = vm.getRecordedLogs();
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

        // Add debug logs
        console.log("Item dropped:", itemDropped);
        if (itemDropped) {
            console.log("Dropped player:", droppedPlayer);
            console.log("Dropped item ID:", droppedItemId);
            console.log("Dropped amount:", droppedAmount);
        }

        assertTrue(itemDropped, "Should have dropped an item");
        assertEq(droppedPlayer, user, "Item dropped to wrong player");
        assertTrue(droppedItemId > 0 && droppedItemId <= 5, "Invalid item ID");
        assertEq(droppedAmount, 1, "Invalid amount");

        // Verify the player received the item
        uint256 balance = equipment.balanceOf(user, droppedItemId);
        console.log("Player balance:", balance);
        assertEq(balance, 1, "Player should have received the item");
    }

    function testDropRateBonus() public {
        vm.startPrank(user);
        vm.recordLogs();
        itemDrop.requestRandomDrop(user, 5000); // 50% bonus
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (uint256 requestId, bool found) = findRequestIdFromLogs(entries);
        vm.stopPrank();

        require(found, "Request ID not found");

        // Check if drop rate bonus was stored correctly
        (, uint256 dropRateBonus,) = itemDrop.dropRequests(requestId);
        assertEq(dropRateBonus, 5000, "Incorrect drop rate bonus stored");
    }
}
