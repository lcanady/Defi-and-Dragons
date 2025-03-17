// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, Vm } from "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ArcaneCrafting, CraftingCooldown, InsufficientResources, InvalidRecipe } from "../src/amm/ArcaneCrafting.sol";
import { Equipment } from "../src/Equipment.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import { ArcaneFactory } from "../src/amm/ArcaneFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock LP Token for testing
contract MockLPToken is ERC20 {
    constructor() ERC20("Mock LP Token", "MLPT") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

// Mock Resource Token for testing
contract MockResourceToken is ERC20 {
    constructor() ERC20("Mock Resource", "MRSC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

contract ArcaneCraftingTest is Test {
    using Strings for uint256;

    ArcaneCrafting public crafting;
    Equipment public equipment;
    ItemDrop public itemDrop;
    VRFCoordinatorV2Mock public vrfCoordinator;
    ArcaneFactory public factory;
    MockLPToken public lpToken;
    MockResourceToken public resourceToken;

    address public owner;
    address public user;
    address public characterContract;

    uint64 constant _SUBSCRIPTION_ID = 1;
    bytes32 constant _KEY_HASH = keccak256("test");
    uint32 constant _CALLBACK_GAS_LIMIT = 200_000;
    uint16 constant _REQUEST_CONFIRMATIONS = 3;
    uint16 constant _NUM_WORDS = 1;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        characterContract = makeAddr("characterContract");

        // Deploy mock tokens
        lpToken = new MockLPToken();
        resourceToken = new MockResourceToken();

        // Deploy mock VRF Coordinator
        vrfCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether, // base fee
            1e9 // gas price link
        );

        // Create VRF subscription
        uint64 subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(_SUBSCRIPTION_ID, 100 ether);

        // Deploy contracts
        factory = new ArcaneFactory();
        equipment = new Equipment();
        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            _SUBSCRIPTION_ID,
            _KEY_HASH,
            _CALLBACK_GAS_LIMIT,
            _REQUEST_CONFIRMATIONS,
            _NUM_WORDS
        );

        // Initialize ItemDrop
        itemDrop.initialize(address(equipment));

        // Add ItemDrop as consumer
        vrfCoordinator.addConsumer(_SUBSCRIPTION_ID, address(itemDrop));

        // Deploy crafting system
        crafting = new ArcaneCrafting(address(factory), address(equipment), address(itemDrop));

        // Setup permissions
        equipment.setCharacterContract(address(crafting));

        // Create test equipment
        for (uint256 i = 0; i < 5; i++) {
            equipment.createEquipment(
                string(abi.encodePacked("Test Item ", i.toString())),
                string(abi.encodePacked("A test item #", i.toString())),
                5, // strength bonus
                0, // agility bonus
                0 // magic bonus
            );
        }

        // Setup test user
        vm.startPrank(owner);
        lpToken.transfer(user, 1000 * 10 ** 18);
        resourceToken.transfer(user, 1000 * 10 ** 18);
        vm.stopPrank();
    }

    function testCreateRecipe() public {
        address[] memory resources = new address[](1);
        resources[0] = address(resourceToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10 ** 18;

        crafting.createRecipe(
            1, // recipeId
            1, // resultingItemId
            address(lpToken),
            50 * 10 ** 18, // lpTokenAmount
            resources,
            amounts,
            1 hours // cooldown
        );

        ArcaneCrafting.Recipe memory recipe = crafting.getRecipe(1);
        assertEq(recipe.recipeId, 1);
        assertEq(recipe.resultingItemId, 1);
        assertEq(recipe.lpToken, address(lpToken));
        assertEq(recipe.lpTokenAmount, 50 * 10 ** 18);
        assertEq(recipe.resources[0], address(resourceToken));
        assertEq(recipe.resourceAmounts[0], 100 * 10 ** 18);
        assertEq(recipe.cooldown, 1 hours);
        assertTrue(recipe.isActive);
    }

    function testCraftItem() public {
        // Create recipe
        address[] memory resources = new address[](1);
        resources[0] = address(resourceToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10 ** 18;

        crafting.createRecipe(
            1, // recipeId
            1, // resultingItemId
            address(lpToken),
            50 * 10 ** 18, // lpTokenAmount
            resources,
            amounts,
            1 hours // cooldown
        );

        // Approve tokens
        vm.startPrank(user);
        lpToken.approve(address(crafting), type(uint256).max);
        resourceToken.approve(address(crafting), type(uint256).max);

        // Craft item
        crafting.craftItem(1);

        // Verify results
        assertEq(equipment.balanceOf(user, 1), 1);
        assertEq(lpToken.balanceOf(user), 950 * 10 ** 18);
        assertEq(resourceToken.balanceOf(user), 900 * 10 ** 18);
        vm.stopPrank();
    }

    function testCraftItemWithCooldown() public {
        // Create recipe
        address[] memory resources = new address[](1);
        resources[0] = address(resourceToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10 ** 18;

        crafting.createRecipe(
            1, // recipeId
            1, // resultingItemId
            address(lpToken),
            50 * 10 ** 18, // lpTokenAmount
            resources,
            amounts,
            1 hours // cooldown
        );

        // Approve tokens
        vm.startPrank(user);
        lpToken.approve(address(crafting), type(uint256).max);
        resourceToken.approve(address(crafting), type(uint256).max);

        // First craft should succeed
        crafting.craftItem(1);

        // Second craft should fail due to cooldown
        vm.expectRevert(CraftingCooldown.selector);
        crafting.craftItem(1);

        // Wait for cooldown
        vm.warp(block.timestamp + 1 hours);

        // Third craft should succeed
        crafting.craftItem(1);
        vm.stopPrank();
    }

    function testInsufficientResources() public {
        // Create recipe
        address[] memory resources = new address[](1);
        resources[0] = address(resourceToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2000 * 10 ** 18; // More than user has

        crafting.createRecipe(
            1, // recipeId
            1, // resultingItemId
            address(lpToken),
            50 * 10 ** 18, // lpTokenAmount
            resources,
            amounts,
            1 hours // cooldown
        );

        // Approve tokens
        vm.startPrank(user);
        lpToken.approve(address(crafting), type(uint256).max);
        resourceToken.approve(address(crafting), type(uint256).max);

        // Try to craft with insufficient resources
        vm.expectRevert(InsufficientResources.selector);
        crafting.craftItem(1);
        vm.stopPrank();
    }

    function testAMMRequiredGear() public {
        crafting.setAMMRequiredGear(1, true);
        assertTrue(crafting.isAMMRequired(1));

        crafting.setAMMRequiredGear(1, false);
        assertFalse(crafting.isAMMRequired(1));
    }

    function testUpdateRecipeStatus() public {
        // Create recipe
        address[] memory resources = new address[](1);
        resources[0] = address(resourceToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10 ** 18;

        crafting.createRecipe(
            1, // recipeId
            1, // resultingItemId
            address(lpToken),
            50 * 10 ** 18, // lpTokenAmount
            resources,
            amounts,
            1 hours // cooldown
        );

        // Deactivate recipe
        crafting.updateRecipeStatus(1, false);
        ArcaneCrafting.Recipe memory recipe = crafting.getRecipe(1);
        assertFalse(recipe.isActive);

        // Try to craft with inactive recipe
        vm.startPrank(user);
        lpToken.approve(address(crafting), type(uint256).max);
        resourceToken.approve(address(crafting), type(uint256).max);

        vm.expectRevert(InvalidRecipe.selector);
        crafting.craftItem(1);
        vm.stopPrank();
    }
}
