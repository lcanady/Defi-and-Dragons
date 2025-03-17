// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ArcaneFactory } from "../src/amm/ArcaneFactory.sol";
import { ArcanePair } from "../src/amm/ArcanePair.sol";
import { ArcaneRouter } from "../src/amm/ArcaneRouter.sol";
import { ArcaneStaking } from "../src/amm/ArcaneStaking.sol";
import { ArcaneQuestIntegration } from "../src/amm/ArcaneQuestIntegration.sol";
import { GameToken } from "../src/GameToken.sol";
import { Quest } from "../src/Quest.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Character } from "../src/Character.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import { Types } from "../src/interfaces/Types.sol";

contract AMMTest is Test {
    ArcaneFactory public factory;
    ArcaneRouter public router;
    ArcaneStaking public staking;
    ArcaneQuestIntegration public questIntegration;
    GameToken public gameToken;
    GameToken public stableToken;
    Quest public questContract;
    ItemDrop public itemDrop;
    Character public character;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    uint256 public characterId;

    function setUp() public {
        // Deploy tokens
        gameToken = new GameToken();
        stableToken = new GameToken(); // Using GameToken as a mock stable token

        // Deploy AMM contracts
        factory = new ArcaneFactory();
        router = new ArcaneRouter(address(factory));
        staking = new ArcaneStaking(IERC20(address(gameToken)), 100e18); // 100 tokens per block

        // Deploy game contracts
        character = new Character(address(0)); // Mock equipment address
        questContract = new Quest(address(character));
        questContract.initialize(address(gameToken));

        // Deploy ItemDrop with mock VRF settings
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(100_000, 100_000);
        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(1, 1 ether);

        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            1, // subscriptionId
            keccak256("test"), // keyHash
            200_000, // callbackGasLimit
            3, // requestConfirmations
            1 // numWords
        );

        // Deploy integration contract
        questIntegration = new ArcaneQuestIntegration(address(factory), address(questContract), address(itemDrop));

        // Setup initial token balances
        gameToken.mint(user1, 1000e18);
        gameToken.mint(user2, 1000e18);
        stableToken.mint(user1, 1000e18);
        stableToken.mint(user2, 1000e18);

        // Approve tokens
        vm.startPrank(user1);
        gameToken.approve(address(router), type(uint256).max);
        stableToken.approve(address(router), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        gameToken.approve(address(router), type(uint256).max);
        stableToken.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // Create a character for testing
        vm.startPrank(owner);
        characterId = character.mintCharacter(
            user1, Types.Stats({ strength: 10, agility: 10, magic: 10 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        // Setup quest contract
        gameToken.setQuestContract(address(questContract), true);
    }

    function testCreatePair() public {
        address pair = factory.createPair(address(gameToken), address(stableToken));
        assertTrue(pair != address(0));
        assertEq(factory.allPairsLength(), 1);
    }

    function testAddLiquidity() public {
        // Create pair
        factory.createPair(address(gameToken), address(stableToken));

        // Add liquidity
        vm.startPrank(user1);
        (uint256 amountA, uint256 amountB, uint256 liquidity) =
            router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        vm.stopPrank();

        // Assert the returned amounts
        assertEq(amountA, 100e18, "Incorrect token A amount");
        assertEq(amountB, 100e18, "Incorrect token B amount");
        assertGt(liquidity, 0, "No liquidity minted");

        address pair = factory.getPair(address(gameToken), address(stableToken));
        assertEq(ArcanePair(pair).balanceOf(user1), liquidity, "Incorrect liquidity balance");
    }

    function testSwap() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        vm.stopPrank();

        // Perform swap
        vm.startPrank(user2);
        uint256 amountIn = 10e18;
        address[] memory path = new address[](2);
        path[0] = address(gameToken);
        path[1] = address(stableToken);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0, // Accept any amount of stableToken
            path,
            user2
        );
        vm.stopPrank();

        // Assert the swap amounts
        assertEq(amounts[0], amountIn, "Incorrect input amount");
        assertGt(amounts[1], 0, "No tokens received");
    }

    function testStaking() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);

        // Get LP token and approve staking
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(staking), type(uint256).max);

        // Add pool for LP token
        vm.stopPrank();
        vm.startPrank(owner);
        staking.addPool(100, IERC20(pair), 1 days);
        vm.stopPrank();

        // Stake LP tokens
        vm.startPrank(user1);
        uint256 lpBalance = ArcanePair(pair).balanceOf(user1);
        staking.deposit(0, lpBalance);
        vm.stopPrank();

        // Mine some blocks and check rewards
        vm.roll(block.number + 10);
        assertGt(staking.pendingReward(0, user1), 0);
    }

    function testQuestIntegration() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        vm.stopPrank();

        // Create quest
        vm.startPrank(owner);
        uint256 questId = questContract.createQuest(1, 10, 10, 10, 10e18, 1 days);
        vm.stopPrank();

        // Start quest
        vm.startPrank(user1);
        questContract.startQuest(characterId, questId);
        questContract.completeQuest(characterId, questId);
        vm.stopPrank();

        assertGt(gameToken.balanceOf(user1), 0);
    }

    // Additional Factory Tests
    function testInvalidPairCreation() public {
        vm.expectRevert("IDENTICAL_ADDRESSES");
        factory.createPair(address(gameToken), address(gameToken));

        vm.expectRevert("ZERO_ADDRESS");
        factory.createPair(address(0), address(gameToken));
    }

    function testDuplicatePairCreation() public {
        factory.createPair(address(gameToken), address(stableToken));
        vm.expectRevert("PAIR_EXISTS");
        factory.createPair(address(gameToken), address(stableToken));
    }

    function testPairSorting() public {
        // Create pair with tokens in one order
        address pair1 = factory.createPair(address(gameToken), address(stableToken));
        
        // Try to create pair with tokens in reverse order - should revert
        vm.expectRevert("PAIR_EXISTS");
        factory.createPair(address(stableToken), address(gameToken));
        
        // Verify the pair exists and is the same
        address existingPair = factory.getPair(address(stableToken), address(gameToken));
        assertEq(existingPair, pair1, "Pairs should be identical regardless of token order");
    }

    // Additional Router Tests
    function testRemoveLiquidity() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));
        vm.startPrank(user1);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = 
            router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);
        
        // Approve LP tokens to router
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(router), liquidity);

        // Remove liquidity
        (uint256 returnedA, uint256 returnedB) = 
            router.removeLiquidity(address(gameToken), address(stableToken), liquidity, 0, 0, user1);
        vm.stopPrank();

        // Account for potential rounding errors with a small tolerance
        uint256 tolerance = 1e15; // 0.001%
        assertApproxEqAbs(returnedA, amountA, tolerance, "Incorrect token A return");
        assertApproxEqAbs(returnedB, amountB, tolerance, "Incorrect token B return");
    }

    function testSlippageProtection() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));
        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);
        vm.stopPrank();

        // Try to swap with high minimum output requirement
        vm.startPrank(user2);
        address[] memory path = new address[](2);
        path[0] = address(gameToken);
        path[1] = address(stableToken);

        bytes memory errorMsg = abi.encodeWithSignature("InsufficientOutputAmount()");
        vm.expectRevert(errorMsg);
        router.swapExactTokensForTokens(10e18, 11e18, path, user2); // Expecting more output than possible
        vm.stopPrank();
    }

    // Additional Staking Tests
    function testEmergencyWithdraw() public {
        // Setup staking pool and deposit
        factory.createPair(address(gameToken), address(stableToken));
        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.addPool(100, IERC20(pair), 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 lpBalance = ArcanePair(pair).balanceOf(user1);
        staking.deposit(0, lpBalance);

        // Emergency withdraw
        staking.emergencyWithdraw(0);
        vm.stopPrank();

        assertEq(ArcanePair(pair).balanceOf(user1), lpBalance, "LP tokens not returned");
        (uint256 amount, uint256 rewardDebt, uint256 lastStakeTime) = staking.userInfo(0, user1);
        assertEq(amount, 0, "Staked amount not reset");
    }

    function testMultiUserStaking() public {
        // Setup staking pool
        factory.createPair(address(gameToken), address(stableToken));
        
        // User1 adds liquidity and stakes
        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        // User2 adds liquidity and stakes
        vm.startPrank(user2);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user2);
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.addPool(100, IERC20(pair), 1 days);
        vm.stopPrank();

        // Both users stake equal amounts
        vm.startPrank(user1);
        uint256 user1LP = ArcanePair(pair).balanceOf(user1);
        staking.deposit(0, user1LP);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 user2LP = ArcanePair(pair).balanceOf(user2);
        staking.deposit(0, user2LP);
        vm.stopPrank();

        // Mine blocks and check rewards
        vm.roll(block.number + 10);
        
        // Account for potential rounding errors with a small tolerance
        uint256 user1Reward = staking.pendingReward(0, user1);
        uint256 user2Reward = staking.pendingReward(0, user2);
        uint256 tolerance = 1e15; // 0.001%
        
        assertGt(user1Reward, 0, "User1 should have rewards");
        assertGt(user2Reward, 0, "User2 should have rewards");
        assertApproxEqAbs(user1Reward, user2Reward, tolerance, "Users should have equal rewards for equal stakes");
    }

    // Additional Quest Integration Tests
    function testLPRequirementTiers() public {
        // Setup LP requirement for different tiers
        vm.startPrank(owner);
        questIntegration.setQuestTierLPRequirement(1, 50e18);
        questIntegration.setQuestTierLPRequirement(2, 100e18);

        // Set pair eligibility
        address pair = factory.createPair(address(gameToken), address(stableToken));
        questIntegration.setLPPairEligibility(pair, true);
        vm.stopPrank();

        // Add liquidity
        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 75e18, 75e18, 0, 0, user1);
        vm.stopPrank();

        // Check tier requirements
        assertTrue(questIntegration.meetsLPRequirement(user1, 1), "Should meet tier 1 requirement");
        assertFalse(questIntegration.meetsLPRequirement(user1, 2), "Should not meet tier 2 requirement");
    }

    function testEnhancedDropRates() public {
        // Setup LP pair and drop rate bonus
        address pair = factory.createPair(address(gameToken), address(stableToken));
        
        vm.startPrank(owner);
        questIntegration.setLPPairEligibility(pair, true);
        questIntegration.setLPDropRateBonus(pair, 5000); // 50% bonus
        vm.stopPrank();

        // Add liquidity
        vm.startPrank(user1);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        vm.stopPrank();

        // Check drop rate bonus
        uint256 bonus = questIntegration.calculateDropRateBonus(user1);
        assertEq(bonus, 5000, "Incorrect drop rate bonus");
        assertTrue(questIntegration.isEligibleForEnhancedRewards(user1), "Should be eligible for enhanced rewards");
    }
}
