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
import { Equipment } from "../src/Equipment.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Character } from "../src/Character.sol";
import { Types } from "../src/interfaces/Types.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";
import { Party } from "../src/Party.sol";

contract AMMTest is Test, IERC721Receiver {
    ArcaneFactory public factory;
    ArcaneRouter public router;
    ArcaneStaking public staking;
    ArcaneQuestIntegration public questIntegration;
    GameToken public gameToken;
    GameToken public stableToken;
    Quest public questContract;
    ItemDrop public itemDrop;
    Character public character;
    Equipment public equipment;
    ProvableRandom public random;
    Party public party;

    address public owner = address(this);
    address public user1 = makeAddr("user1");
    address public user2 = address(2);
    uint256 public characterId;
    Quest.QuestObjective[] public objectives;

    function setUp() public {
        // Deploy tokens
        gameToken = new GameToken();
        stableToken = new GameToken(); // Using GameToken as a mock stable token

        // Deploy AMM contracts
        factory = new ArcaneFactory();
        router = new ArcaneRouter(address(factory));
        staking = new ArcaneStaking(IERC20(address(gameToken)), 100e18); // 100 tokens per block

        // Deploy core game contracts
        random = new ProvableRandom();
        character = new Character(address(0), address(random));
        equipment = new Equipment(address(character));
        character = new Character(address(equipment), address(random));
        party = new Party(address(character));
        questContract = new Quest(address(character), address(party));

        // Create a character for testing
        vm.startPrank(owner);
        characterId = character.mintCharacter(owner, Types.Alignment.STRENGTH);

        // Deploy Quest contract as owner
        vm.startPrank(owner);
        questContract.initialize(address(gameToken));
        vm.stopPrank();

        // Deploy quest integration
        itemDrop = new ItemDrop(address(random));
        itemDrop.initialize(address(equipment));
        questIntegration = new ArcaneQuestIntegration(address(factory), address(questContract), address(itemDrop));

        // Set up permissions
        vm.startPrank(owner);
        gameToken.setQuestContract(address(questContract), true);
        gameToken.setMarketplaceContract(address(router), true);
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
        questContract.grantRole(questContract.QUEST_MANAGER_ROLE(), address(questIntegration));
        questContract.grantRole(questContract.DEFAULT_ADMIN_ROLE(), address(questIntegration));
        gameToken.grantRole(gameToken.MINTER_ROLE(), address(questContract));
        gameToken.grantRole(gameToken.MINTER_ROLE(), address(questIntegration));

        // Set up quest integration
        questIntegration.setQuestTierLPRequirement(1, 10e18); // Tier 1 requires 10 LP tokens
        vm.stopPrank();

        // Mint initial tokens
        gameToken.mint(user1, 1000e18);
        gameToken.mint(user2, 1000e18);
        stableToken.mint(user1, 1000e18);
        stableToken.mint(user2, 1000e18);

        // Initialize quest objectives
        objectives.push(
            Quest.QuestObjective({ targetValue: 5, currentValue: 0, objectiveType: questContract.COMBAT_COMPLETED() })
        );
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
        // Add approvals
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
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
        // Add approvals for initial liquidity
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 100e18, 100e18, user1);
        vm.stopPrank();

        // Perform swap
        vm.startPrank(user2);
        uint256 amountIn = 10e18;
        // Add approval for swap
        gameToken.approve(address(router), amountIn);
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
        // Add approvals
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
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

    function testMultiUserStaking() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        // User 1 adds liquidity
        vm.startPrank(user1);
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);

        // Get LP token and approve staking
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        // User 2 adds liquidity
        vm.startPrank(user2);
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user2);
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        // Add staking pool
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

    function testEmergencyWithdraw() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        vm.startPrank(user1);
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);

        // Get LP token and approve staking
        address pair = factory.getPair(address(gameToken), address(stableToken));
        ArcanePair(pair).approve(address(staking), type(uint256).max);
        vm.stopPrank();

        // Add staking pool
        vm.startPrank(owner);
        staking.addPool(100, IERC20(pair), 1 days);
        vm.stopPrank();

        // Stake LP tokens
        vm.startPrank(user1);
        uint256 lpBalance = ArcanePair(pair).balanceOf(user1);
        staking.deposit(0, lpBalance);

        // Emergency withdraw
        staking.emergencyWithdraw(0);
        vm.stopPrank();

        assertEq(ArcanePair(pair).balanceOf(user1), lpBalance, "LP tokens not returned");
        (uint256 amount,,) = staking.userInfo(0, user1);
        assertEq(amount, 0, "Staked amount not reset");
    }

    function testLPRequirementTiers() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        // Setup LP requirement for different tiers
        vm.startPrank(owner);
        questIntegration.setQuestTierLPRequirement(1, 50e18);
        questIntegration.setQuestTierLPRequirement(2, 100e18);

        // Set pair eligibility
        address pair = factory.getPair(address(gameToken), address(stableToken));
        questIntegration.setLPPairEligibility(pair, true);
        vm.stopPrank();

        vm.startPrank(user1);
        gameToken.approve(address(router), 75e18);
        stableToken.approve(address(router), 75e18);
        router.addLiquidity(address(gameToken), address(stableToken), 75e18, 75e18, 0, 0, user1);
        vm.stopPrank();

        // Check tier requirements
        assertTrue(questIntegration.meetsLPRequirement(user1, 1), "Should meet tier 1 requirement");
        assertFalse(questIntegration.meetsLPRequirement(user1, 2), "Should not meet tier 2 requirement");
    }

    function testEnhancedDropRates() public {
        // Create pair and add liquidity
        factory.createPair(address(gameToken), address(stableToken));

        // Setup LP pair and drop rate bonus
        vm.startPrank(owner);
        address pair = factory.getPair(address(gameToken), address(stableToken));
        questIntegration.setLPPairEligibility(pair, true);
        questIntegration.setLPDropRateBonus(pair, 5000); // 50% bonus
        vm.stopPrank();

        vm.startPrank(user1);
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);
        vm.stopPrank();

        // Check drop rate bonus
        uint256 bonus = questIntegration.calculateDropRateBonus(user1);
        assertEq(bonus, 5000, "Incorrect drop rate bonus");
        assertTrue(questIntegration.isEligibleForEnhancedRewards(user1), "Should be eligible for enhanced rewards");
    }

    function testQuestIntegration() public {
        // Create pair and set up LP requirements
        vm.startPrank(owner);
        address pair = factory.createPair(address(gameToken), address(stableToken));
        questIntegration.setLPPairEligibility(pair, true);
        questIntegration.setLPDropRateBonus(pair, 5000);
        questIntegration.setQuestTierLPRequirement(1, 10e18);

        // Create quest as owner
        uint256 questId = questContract.createQuest(
            1, // requiredLevel
            1, // requiredStrength
            1, // requiredAgility
            1, // requiredMagic
            100e18, // rewardAmount
            0, // cooldown
            false, // supportsParty
            0, // maxPartySize
            0, // partyBonusPercent
            false, // isRaid
            0, // maxParties
            Quest.QuestType.COMBAT, // questType
            objectives // objectives array
        );

        // Transfer character to user1
        character.transferFrom(owner, user1, characterId);
        vm.stopPrank();

        // Add liquidity to make user1 eligible
        vm.startPrank(user1);
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);

        // Start and complete quest through questIntegration
        questIntegration.startQuest(characterId, questId);
        questIntegration.completeQuest(characterId, questId);

        // Verify enhanced rewards
        assertTrue(questIntegration.isEligibleForEnhancedRewards(user1));
        vm.stopPrank();
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
        // Add approvals
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
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
        // Add approvals
        gameToken.approve(address(router), 100e18);
        stableToken.approve(address(router), 100e18);
        router.addLiquidity(address(gameToken), address(stableToken), 100e18, 100e18, 0, 0, user1);
        vm.stopPrank();

        // Try to swap with high minimum output requirement
        vm.startPrank(user2);
        // Add approval for swap
        gameToken.approve(address(router), 10e18);
        address[] memory path = new address[](2);
        path[0] = address(gameToken);
        path[1] = address(stableToken);

        bytes memory errorMsg = abi.encodeWithSignature("InsufficientOutputAmount()");
        vm.expectRevert(errorMsg);
        router.swapExactTokensForTokens(10e18, 11e18, path, user2); // Expecting more output than possible
        vm.stopPrank();
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
