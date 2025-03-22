// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, Vm } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Equipment } from "../src/Equipment.sol";
import { TestHelper } from "./helpers/TestHelper.sol";

contract ItemDropTest is Test, TestHelper {
    using Strings for uint256;

    ItemDrop public itemDrop;
    Equipment public equipment;

    address public owner;
    address public user;

    event RandomWordsRequested(uint256 indexed requestId, address indexed player);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint256 amount);

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy contracts
        equipment = new Equipment();
        itemDrop = new ItemDrop();

        // Initialize contracts
        equipment.setItemDrop(address(itemDrop));
        equipment.setCharacterContract(address(itemDrop));
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
        itemDrop.initialize(address(equipment));

        // Add debug logs
        console.log("ItemDrop address:", address(itemDrop));
        console.log("Equipment address:", address(equipment));

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
        itemDrop.initializeSeed(bytes32(uint256(1))); // Initialize seed for user
        vm.recordLogs();
        uint256 requestId = itemDrop.requestRandomDrop(user, 5000); // 50% drop rate bonus
        Vm.Log[] memory entries = vm.getRecordedLogs();
        vm.stopPrank();

        assertTrue(requestId > 0, "Should have valid request ID");

        // Check for ItemDropped event
        bool itemDropped = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ItemDropped(address,uint256,uint256)")) {
                itemDropped = true;
                break;
            }
        }

        assertTrue(itemDropped, "Should have dropped an item");
    }

    function testDropItem() public {
        vm.startPrank(user);
        itemDrop.initializeSeed(bytes32(uint256(1))); // Initialize seed for user
        vm.recordLogs();
        itemDrop.requestRandomDrop(user, 5000);
        vm.stopPrank();

        // Check for ItemDropped event
        bool itemDropped = false;
        uint256 droppedItemId;
        uint256 droppedAmount;
        address droppedPlayer;

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("ItemDropped(address,uint256,uint256)")) {
                itemDropped = true;
                droppedPlayer = address(uint160(uint256(logs[i].topics[1])));
                droppedItemId = uint256(logs[i].topics[2]);
                droppedAmount = abi.decode(logs[i].data, (uint256));
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
}
