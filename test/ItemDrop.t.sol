// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Equipment } from "../src/Equipment.sol";
import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract ItemDropTest is Test {
    ItemDrop public itemDrop;
    Equipment public equipment;
    VRFCoordinatorV2Mock public vrfCoordinator;
    
    address public owner;
    address public player;
    
    bytes32 private constant KEY_HASH = keccak256("test");
    uint64 private constant SUBSCRIPTION_ID = 1;
    uint96 private constant FUND_AMOUNT = 1 ether;
    
    event DropRequested(uint256 indexed requestId, address indexed player, uint256 dropTableId);
    event DropFulfilled(uint256 indexed requestId, address indexed player, uint256 equipmentId);
    
    function setUp() public {
        owner = makeAddr("owner");
        player = makeAddr("player");
        
        vm.startPrank(owner);
        
        // Deploy VRF Coordinator Mock
        vrfCoordinator = new VRFCoordinatorV2Mock(100000, 100000);
        
        // Create and fund subscription
        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(SUBSCRIPTION_ID, FUND_AMOUNT);
        
        // Deploy contracts
        equipment = new Equipment();
        
        // Create equipment first
        equipment.createEquipment(1, "Common Sword", "A basic sword", 5, 0, 0);
        equipment.createEquipment(2, "Rare Sword", "A powerful sword", 10, 0, 0);
        
        // Deploy ItemDrop contract
        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            address(equipment),
            KEY_HASH,
            SUBSCRIPTION_ID
        );
        
        // Add consumer to VRF subscription
        vrfCoordinator.addConsumer(SUBSCRIPTION_ID, address(itemDrop));

        // Set up ownership and permissions
        equipment.setCharacterContract(address(itemDrop));
        equipment.transferOwnership(address(itemDrop));
        
        vm.stopPrank();
    }
    
    function testCreateDropTable() public {
        vm.startPrank(owner);
        
        // Create drop table entries
        ItemDrop.DropEntry[] memory entries = new ItemDrop.DropEntry[](2);
        entries[0] = ItemDrop.DropEntry({equipmentId: 1, weight: 800}); // 80% chance
        entries[1] = ItemDrop.DropEntry({equipmentId: 2, weight: 200}); // 20% chance
        
        // Create drop table
        itemDrop.createDropTable(1, "Basic Sword Drop", entries);
        
        vm.stopPrank();
        
        // Verify drop table
        (string memory name, uint16 totalWeight, bool active, ItemDrop.DropEntry[] memory storedEntries) = itemDrop.getDropTable(1);
        assertEq(name, "Basic Sword Drop");
        assertEq(totalWeight, 1000);
        assertTrue(active);
        assertEq(storedEntries.length, 2);
        assertEq(storedEntries[0].equipmentId, 1);
        assertEq(storedEntries[0].weight, 800);
        assertEq(storedEntries[1].equipmentId, 2);
        assertEq(storedEntries[1].weight, 200);
    }
    
    function testRequestAndFulfillDrop() public {
        vm.startPrank(owner);
        
        // Create drop table entries
        ItemDrop.DropEntry[] memory entries = new ItemDrop.DropEntry[](2);
        entries[0] = ItemDrop.DropEntry({equipmentId: 1, weight: 800});
        entries[1] = ItemDrop.DropEntry({equipmentId: 2, weight: 200});
        
        itemDrop.createDropTable(1, "Basic Sword Drop", entries);
        
        vm.stopPrank();
        
        // Request drop as player
        vm.startPrank(player);
        uint256 requestId = itemDrop.requestDrop(1);
        vm.stopPrank();
        
        // Simulate VRF response
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123; // This will be used to determine the drop
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(itemDrop), randomWords);
        
        // Verify player received an item (either common or rare sword)
        bool hasCommonSword = equipment.balanceOf(player, 1) > 0;
        bool hasRareSword = equipment.balanceOf(player, 2) > 0;
        assertTrue(hasCommonSword || hasRareSword, "Player should receive either sword");
        assertTrue(!(hasCommonSword && hasRareSword), "Player should not receive both swords");
    }
    
    function testFailCreateDropTableWithInvalidWeights() public {
        ItemDrop.DropEntry[] memory entries = new ItemDrop.DropEntry[](1);
        entries[0] = ItemDrop.DropEntry({equipmentId: 1, weight: 1001}); // Weight > 1000
        
        vm.prank(owner);
        itemDrop.createDropTable(1, "Invalid Drop", entries);
    }
    
    function testFailRequestDropFromInactiveTable() public {
        vm.prank(player);
        itemDrop.requestDrop(999); // Non-existent drop table
    }
} 