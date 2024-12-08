// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Equipment } from "../src/Equipment.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import { TestHelper } from "./helpers/TestHelper.sol";

contract ItemDropTest is TestHelper {
    ItemDrop public itemDrop;
    Equipment public equipment;
    VRFCoordinatorV2Mock public vrfCoordinator;

    address public owner;
    address public player;

    bytes32 private constant _KEY_HASH = keccak256("test");
    uint64 private constant _SUBSCRIPTION_ID = 1;
    uint96 private constant _FUND_AMOUNT = 1 ether;

    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint256 amount);

    function setUp() public {
        owner = address(this);
        player = makeAddr("player");

        // Deploy VRF Coordinator Mock
        vrfCoordinator = new VRFCoordinatorV2Mock(
            100_000, // baseFee
            100_000 // gasPriceLink
        );

        // Create and fund subscription
        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(_SUBSCRIPTION_ID, _FUND_AMOUNT);

        // Deploy contracts
        equipment = new Equipment();
        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            _SUBSCRIPTION_ID,
            _KEY_HASH,
            200_000, // callbackGasLimit
            3, // requestConfirmations
            1 // numWords
        );

        // Initialize ItemDrop
        itemDrop.initialize(address(equipment));

        // Add consumer to VRF subscription
        vrfCoordinator.addConsumer(_SUBSCRIPTION_ID, address(itemDrop));

        // Set up Equipment contract
        equipment.setCharacterContract(address(itemDrop));

        // Create test equipment
        for (uint256 i = 1; i <= 5; i++) {
            equipment.createEquipment(i, "Test Item", "A test item", 5, 0, 0);
        }
    }

    function _requestAndFulfillDrop(uint256 bonus, uint256 randomWord) internal returns (uint256 totalBalance) {
        vm.startPrank(owner);

        // Request random drop and get request ID
        vm.recordLogs();
        itemDrop.requestRandomDrop(player, bonus);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Find the requestId from the emitted event
        (uint256 requestId, bool found) = findRequestIdFromLogs(entries);
        require(found, "RequestId not found in events");

        // Fulfill random words
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord;
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(itemDrop), randomWords);

        vm.stopPrank();

        // Check if player received any item (1-5)
        for (uint256 i = 1; i <= 5; i++) {
            totalBalance += equipment.balanceOf(player, i);
        }
    }

    function testRequestAndFulfillDrop() public {
        // Use 25 to ensure rand % 100 = 25 < 50 (base rate) and (rand % 5) + 1 = 1
        uint256 totalBalance = _requestAndFulfillDrop(0, 25);
        assertGt(totalBalance, 0, "Player should have received at least one item");
    }

    function testDropWithBonus() public {
        // Use 75 to ensure rand % 100 = 75 < 100 (50 base + 50 bonus) and (rand % 5) + 1 = 1
        uint256 totalBalance = _requestAndFulfillDrop(50, 75);
        assertGt(totalBalance, 0, "Player should have received at least one item");
    }

    function testFailDropWithHighRoll() public {
        // Use 99 to ensure rand % 100 = 99 > 50 (base rate) for no bonus
        vm.expectRevert("No item dropped");
        _requestAndFulfillDrop(0, 99);
    }

    function testUpdateCallbackGasLimit() public {
        itemDrop.setCallbackGasLimit(300_000);
        assertEq(itemDrop.callbackGasLimit(), 300_000);
    }

    function testUpdateRequestConfirmations() public {
        itemDrop.setRequestConfirmations(5);
        assertEq(itemDrop.requestConfirmations(), 5);
    }

    function testUpdateNumWords() public {
        itemDrop.setNumWords(2);
        assertEq(itemDrop.numWords(), 2);
    }
}
