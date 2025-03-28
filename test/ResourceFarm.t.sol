// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ResourceFarm} from "../src/ResourceFarm.sol";
import {IronOreToken} from "../src/tokens/IronOreToken.sol";
import {LumberToken} from "../src/tokens/LumberToken.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ProvableRandom} from "../src/ProvableRandom.sol";
import {GemstoneToken} from "../src/tokens/GemstoneToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMintableERC20} from "../src/interfaces/IMintableERC20.sol";

// Malicious ERC20 that attempts reentrancy during transfers
contract MaliciousERC20 is ERC20 {
    ResourceFarm private immutable farm;
    uint256 private pid;
    uint256 private attackCount;
    bool private isWithdrawMode;
    bool private reentrancyEnabled;
    
    constructor(string memory name, string memory symbol, ResourceFarm _farm) ERC20(name, symbol) {
        farm = _farm;
        reentrancyEnabled = true;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function setPid(uint256 _pid) external {
        pid = _pid;
    }

    function setWithdrawMode(bool _isWithdrawMode) external {
        isWithdrawMode = _isWithdrawMode;
        attackCount = 0; // Reset attack count when switching modes
    }

    function setReentrancyEnabled(bool enabled) external {
        reentrancyEnabled = enabled;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Only attempt reentrancy if enabled and we haven't tried to reenter yet
        if (reentrancyEnabled && attackCount == 0) {
            if (isWithdrawMode) {
                // In withdraw mode, only attempt reentrancy during withdrawals (farm -> user)
                if (from == address(farm)) {
                    attackCount++;
                    console.log("Attempting reentrancy during withdrawal");
                    farm.withdraw(pid, amount);
                }
            } else {
                // In deposit mode, only attempt reentrancy during deposits (user -> farm)
                if (to == address(farm)) {
                    attackCount++;
                    console.log("Attempting reentrancy during deposit");
                    farm.deposit(pid, amount);
                }
            }
        }
    }
}

contract ResourceFarmTest is Test {
    ResourceFarm public farm;
    IronOreToken public ironOre;
    LumberToken public lumber;
    MockERC20 public lpToken1;
    MockERC20 public lpToken2;
    GemstoneToken public gemstone;
    ProvableRandom public randomSource;

    uint256 public constant INITIAL_REWARD_PER_BLOCK = 1 ether;
    uint256 public constant START_BLOCK_OFFSET = 10;

    address public owner;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        owner = address(this);
        vm.label(owner, "Owner/Deployer");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        // Deploy Reward Tokens
        ironOre = new IronOreToken("Iron Ore", "IRON");
        lumber = new LumberToken("Lumber", "LMBR");
        gemstone = new GemstoneToken("Gemstone", "GEM");

        // Deploy Random Source
        randomSource = new ProvableRandom();

        // Deploy Mock LP Tokens
        lpToken1 = new MockERC20("LP Token 1", "LP1", 18);
        lpToken2 = new MockERC20("LP Token 2", "LP2", 18);

        // Mint LP tokens to users
        lpToken1.mint(alice, 1000 ether);
        lpToken1.mint(bob, 1000 ether);
        lpToken2.mint(alice, 500 ether);
        lpToken2.mint(bob, 500 ether);

        // Deploy ResourceFarm
        uint256 startBlock = block.number + START_BLOCK_OFFSET;
        farm = new ResourceFarm(INITIAL_REWARD_PER_BLOCK, startBlock, address(randomSource));

        // Transfer minter roles for reward tokens to the farm contract
        ironOre.grantRole(ironOre.MINTER_ROLE(), address(farm));
        lumber.grantRole(lumber.MINTER_ROLE(), address(farm));
        gemstone.grantRole(gemstone.MINTER_ROLE(), address(farm));
        ironOre.renounceRole(ironOre.MINTER_ROLE(), owner);
        lumber.renounceRole(lumber.MINTER_ROLE(), owner);
        gemstone.renounceRole(gemstone.MINTER_ROLE(), owner);

        // Add initial pools (e.g., equal allocation points)
        // Pool 0: Stake LP1, get IRON, chance of GEM
        // 10% chance (1000 / 10000) to get 1 GEM (1 * 1e18)
        farm.add(100, lpToken1, IMintableERC20(address(ironOre)), IMintableERC20(address(gemstone)), 1000, 1 ether, false);
        // Pool 1: Stake LP2, get LMBR, no rare drop
        farm.add(100, lpToken2, IMintableERC20(address(lumber)), IMintableERC20(address(0)), 0, 0, false);
        // Total alloc points = 200
    }

    // --- Test Pool Management ---

    function test_addPool() public {
        assertEq(farm.poolLength(), 2);
        MockERC20 lpToken3 = new MockERC20("LP3", "LP3", 18);
        farm.add(200, lpToken3, IMintableERC20(address(ironOre)), IMintableERC20(address(gemstone)), 500, 0.5 ether, true);
        assertEq(farm.poolLength(), 3);
        assertEq(farm.totalAllocPoint(), 400);
        (
            IERC20 lpToken,
            IMintableERC20 rewardToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            uint256 totalStaked,
            IMintableERC20 rareRewardToken,
            uint16 rareDropChanceBps,
            uint256 rareDropAmount
        ) = farm.poolInfo(2);
        assertEq(address(lpToken), address(lpToken3));
        assertEq(address(rareRewardToken), address(gemstone));
        assertEq(rareDropChanceBps, 500);
        assertEq(rareDropAmount, 0.5 ether);
    }

    function test_setPoolAllocPoint() public {
        // Get pool info and check allocation points
        (
            ,
            ,
            uint256 allocPoint,
            ,
            ,
            ,
            ,
            ,
        ) = farm.poolInfo(0);
        assertEq(allocPoint, 100);
        assertEq(farm.totalAllocPoint(), 200);

        farm.set(0, 300, true);

        // Get updated pool info
        (
            ,
            ,
            allocPoint,
            ,
            ,
            ,
            ,
            ,
        ) = farm.poolInfo(0);
        assertEq(allocPoint, 300);
        assertEq(farm.totalAllocPoint(), 400);
    }

    function test_updateEmissionRate() public {
        assertEq(farm.rewardPerBlock(), INITIAL_REWARD_PER_BLOCK);
        uint256 newRate = 2 ether;
        farm.updateEmissionRate(newRate);
        assertEq(farm.rewardPerBlock(), newRate);
    }

    function test_fail_addPool_notOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.add(100, lpToken1, IMintableERC20(address(0)), IMintableERC20(address(0)), 0, 0, false);
    }

    function test_fail_setPool_notOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.set(0, 200, false);
    }

    function test_fail_updateEmissionRate_notOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.updateEmissionRate(2 ether);
    }

    // --- Test Staking and Rewards ---

    function test_depositAndWithdraw() public {
        uint256 depositAmount = 100 ether;

        // Mint LP tokens to Alice
        lpToken1.mint(alice, depositAmount);
        
        // Alice deposits to pool 0 (Iron Ore + chance of Gemstone)
        vm.startPrank(alice);
        lpToken1.approve(address(farm), depositAmount);
        farm.deposit(0, depositAmount);
        vm.stopPrank();

        // Skip blocks past start block to ensure rewards accrue
        vm.roll(farm.startBlock() + 20); // Ensure we're well past the start block

        // Check user info and pool state after deposit
        (uint256 aliceAmount, uint256 rewardDebt, bool seedInitialized) = farm.userInfo(0, alice);
        assertEq(aliceAmount, depositAmount);
        assertEq(lpToken1.balanceOf(address(farm)), depositAmount);
        assertTrue(seedInitialized);
        
        // Get pool info and check total staked
        (
            IERC20 lpToken,
            IMintableERC20 rewardToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            uint256 totalStaked,
            IMintableERC20 rareRewardToken,
            uint16 rareDropChanceBps,
            uint256 rareDropAmount
        ) = farm.poolInfo(0);
        assertEq(totalStaked, depositAmount);

        // Record initial balance
        uint256 initialIronBalance = ironOre.balanceOf(alice);

        // Alice withdraws half
        uint256 withdrawAmount = depositAmount / 2;
        vm.startPrank(alice);
        farm.withdraw(0, withdrawAmount);
        vm.stopPrank();

        // Check updated user info and pool state
        (aliceAmount, rewardDebt, seedInitialized) = farm.userInfo(0, alice);
        assertEq(aliceAmount, depositAmount - withdrawAmount);
        assertEq(lpToken1.balanceOf(address(farm)), depositAmount - withdrawAmount);
        assertTrue(seedInitialized);
        
        // Get updated pool info
        (
            lpToken,
            rewardToken,
            allocPoint,
            lastRewardBlock,
            accRewardPerShare,
            totalStaked,
            rareRewardToken,
            rareDropChanceBps,
            rareDropAmount
        ) = farm.poolInfo(0);
        assertEq(totalStaked, depositAmount - withdrawAmount);
        assertGt(ironOre.balanceOf(alice), initialIronBalance);
    }

    function test_harvest() public {
        uint256 depositAmount = 100 ether;

        // Alice deposits to pool 1 (Lumber)
        vm.startPrank(alice);
        lpToken2.approve(address(farm), depositAmount);
        farm.deposit(1, depositAmount);
        vm.stopPrank();

        // Skip blocks past start block
        vm.roll(farm.startBlock() + 5);

        // Check pending rewards
        uint256 pending = farm.pendingReward(1, alice);
        console.log("Pending LMBR for Alice:", pending);
        assertGt(pending, 0);

        uint256 initialLumber = lumber.balanceOf(alice);

        // Alice harvests
        vm.prank(alice);
        farm.harvest(1);

        uint256 harvestedLumber = lumber.balanceOf(alice) - initialLumber;
        console.log("Harvested LMBR:", harvestedLumber);
        assertTrue(harvestedLumber > 0);
        assertTrue(harvestedLumber <= pending && harvestedLumber >= pending - 1);

        // Pending should be 0 (or close to it) immediately after harvest
        uint256 pendingAfter = farm.pendingReward(1, alice);
        console.log("Pending LMBR after harvest:", pendingAfter);
        assertTrue(pendingAfter <= 1);
    }

    function test_rewardsDistributionTwoStakers() public {
        uint256 aliceDeposit = 100 ether;
        uint256 bobDeposit = 300 ether; // Bob deposits 3x more

        // Alice deposits to pool 0
        vm.startPrank(alice);
        lpToken1.approve(address(farm), aliceDeposit);
        farm.deposit(0, aliceDeposit);
        vm.stopPrank();

        // Bob deposits to pool 0
        vm.startPrank(bob);
        lpToken1.approve(address(farm), bobDeposit);
        farm.deposit(0, bobDeposit);
        vm.stopPrank();

        // Get pool info and check total staked
        (
            ,
            ,
            ,
            ,
            ,
            uint256 totalStaked,
            ,
            ,
            
        ) = farm.poolInfo(0);
        assertEq(totalStaked, aliceDeposit + bobDeposit);

        // Skip blocks past start block
        vm.roll(farm.startBlock() + 10);

        // Harvest rewards
        uint256 initialIronAlice = ironOre.balanceOf(alice);
        uint256 initialIronBob = ironOre.balanceOf(bob);

        vm.prank(alice);
        farm.harvest(0);
        vm.prank(bob);
        farm.harvest(0);

        uint256 harvestedIronAlice = ironOre.balanceOf(alice) - initialIronAlice;
        uint256 harvestedIronBob = ironOre.balanceOf(bob) - initialIronBob;

        console.log("Harvested IRON Alice:", harvestedIronAlice);
        console.log("Harvested IRON Bob:", harvestedIronBob);

        // Bob should have roughly 3x the rewards of Alice (proportional to stake)
        // Allow for slight rounding differences (e.g., 1 wei tolerance)
        uint256 expectedBobReward = harvestedIronAlice * 3;
        assertTrue(harvestedIronBob >= expectedBobReward - 1 && harvestedIronBob <= expectedBobReward + 1, "Bob reward ratio mismatch");
    }

    function test_emergencyWithdraw() public {
        uint256 depositAmount = 100 ether;
        
        // Mint LP tokens to Alice
        lpToken1.mint(alice, depositAmount);
        
        // Alice deposits to pool 0
        vm.startPrank(alice);
        lpToken1.approve(address(farm), depositAmount);
        farm.deposit(0, depositAmount);
        vm.stopPrank();
        
        // Record initial balances
        uint256 initialLPBalance = lpToken1.balanceOf(alice);
        uint256 initialIronBalance = ironOre.balanceOf(alice);
        
        // Skip blocks to accrue rewards
        vm.warp(block.timestamp + 100);
        vm.roll(block.number + 10);
        
        // Emergency withdraw
        vm.prank(alice);
        farm.emergencyWithdraw(0, depositAmount);
        
        // Check LP tokens returned
        assertEq(lpToken1.balanceOf(alice), initialLPBalance + depositAmount);
        
        // Check user info is reset
        (uint256 amount, uint256 rewardDebt, bool seedInitialized) = farm.userInfo(0, alice);
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
        assertTrue(seedInitialized); // Seed initialization status should not change
        
        // Check no rewards were given
        assertEq(ironOre.balanceOf(alice), initialIronBalance);
        
        // Check pool total staked is updated
        (
            ,
            ,
            ,
            ,
            ,
            uint256 totalStaked,
            ,
            ,
            
        ) = farm.poolInfo(0);
        assertEq(totalStaked, 0);
    }

    function test_deposit_reentrancy() public {
        uint256 depositAmount = 100 ether;
        
        // Deploy malicious token
        MaliciousERC20 maliciousToken = new MaliciousERC20("Malicious", "MAL", farm);
        
        // Add new pool with malicious token
        farm.add(100, maliciousToken, IMintableERC20(address(ironOre)), IMintableERC20(address(0)), 0, 0, false);
        uint256 maliciousPid = farm.poolLength() - 1;
        maliciousToken.setPid(maliciousPid);
        
        // Mint tokens to attacker
        maliciousToken.mint(alice, depositAmount);
        
        // Attempt reentrancy attack during deposit
        vm.startPrank(alice);
        maliciousToken.approve(address(farm), depositAmount);
        vm.expectRevert("ReentrancyGuard: reentrant call");
        farm.deposit(maliciousPid, depositAmount);
        vm.stopPrank();
    }

    function test_withdraw_reentrancy() public {
        uint256 depositAmount = 100 ether;
        
        // Deploy malicious token
        MaliciousERC20 maliciousToken = new MaliciousERC20("Malicious", "MAL", farm);
        
        // Add new pool with malicious token
        farm.add(100, maliciousToken, IMintableERC20(address(ironOre)), IMintableERC20(address(0)), 0, 0, false);
        uint256 maliciousPid = farm.poolLength() - 1;
        maliciousToken.setPid(maliciousPid);
        
        // Mint tokens to attacker
        maliciousToken.mint(alice, depositAmount);
        
        // First make a successful deposit with reentrancy disabled
        vm.startPrank(alice);
        maliciousToken.approve(address(farm), depositAmount);
        maliciousToken.setReentrancyEnabled(false); // Disable reentrancy for deposit
        farm.deposit(maliciousPid, depositAmount);
        
        // Now attempt withdrawal with reentrancy enabled
        maliciousToken.setWithdrawMode(true);
        maliciousToken.setReentrancyEnabled(true); // Enable reentrancy for withdrawal
        vm.expectRevert("ReentrancyGuard: reentrant call");
        farm.withdraw(maliciousPid, depositAmount);
        vm.stopPrank();
    }

    // Test harvest specifically for rare drops - success case (forced)
    function test_harvest_RareDrop_Success() public {
        uint256 depositAmount = 100 ether;
        uint256 pid = 0;
        
        // Mint LP tokens to Alice
        lpToken1.mint(alice, depositAmount);
        
        // Alice deposits to pool 0 (Iron Ore + chance of Gemstone)
        vm.startPrank(alice);
        lpToken1.approve(address(farm), depositAmount);
        farm.deposit(pid, depositAmount);
        vm.stopPrank();
        
        // Skip blocks to accrue rewards
        vm.roll(farm.startBlock() + 20); // Ensure we're well past the start block
        
        // Get pool info for rare drop chance and amount
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint16 rareDropChanceBps,
            uint256 rareDropAmount
        ) = farm.poolInfo(pid);
        
        // Mock the random source to force a rare drop
        bytes32 context = keccak256(abi.encodePacked(alice, uint256(pid)));
        uint256[] memory randomNumbers = new uint256[](1);
        randomNumbers[0] = rareDropChanceBps - 1; // Number less than chance threshold
        vm.mockCall(
            address(randomSource),
            abi.encodeWithSignature("generateNumbers(address,bytes32,uint256)", alice, context, 1),
            abi.encode(randomNumbers)
        );
        
        // Record initial balances
        uint256 initialIronBalance = ironOre.balanceOf(alice);
        uint256 initialGemBalance = gemstone.balanceOf(alice);
        
        // Harvest with forced rare drop
        vm.prank(alice);
        farm.harvest(pid);
        
        // Check rewards
        assertGt(ironOre.balanceOf(alice), initialIronBalance, "Should get base rewards");
        assertEq(gemstone.balanceOf(alice), initialGemBalance + rareDropAmount, "Should get rare drop");
    }

    function test_harvest_RareDrop_Failure() public {
        uint256 depositAmount = 100 ether;
        uint256 pid = 0;
        
        // Mint LP tokens to Alice
        lpToken1.mint(alice, depositAmount);
        
        // Alice deposits to pool 0 (Iron Ore + chance of Gemstone)
        vm.startPrank(alice);
        lpToken1.approve(address(farm), depositAmount);
        farm.deposit(pid, depositAmount);
        vm.stopPrank();
        
        // Skip blocks to accrue rewards
        vm.roll(farm.startBlock() + 20); // Ensure we're well past the start block
        
        // Get pool info for rare drop chance and amount
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint16 rareDropChanceBps,
            uint256 rareDropAmount
        ) = farm.poolInfo(pid);
        
        // Mock the random source to force no rare drop
        bytes32 context = keccak256(abi.encodePacked(alice, uint256(pid)));
        uint256[] memory randomNumbers = new uint256[](1);
        randomNumbers[0] = rareDropChanceBps + 1; // Number greater than chance threshold
        vm.mockCall(
            address(randomSource),
            abi.encodeWithSignature("generateNumbers(address,bytes32,uint256)", alice, context, 1),
            abi.encode(randomNumbers)
        );
        
        // Record initial balances
        uint256 initialIronBalance = ironOre.balanceOf(alice);
        uint256 initialGemBalance = gemstone.balanceOf(alice);
        
        // Harvest with forced no rare drop
        vm.prank(alice);
        farm.harvest(pid);
        
        // Check rewards
        assertGt(ironOre.balanceOf(alice), initialIronBalance, "Should get base rewards");
        assertEq(gemstone.balanceOf(alice), initialGemBalance, "Should NOT get rare drop");
    }

    function _simulateRareDrop(uint256 pid, address user, uint256 targetBlock) internal {
        // Get user info
        (uint256 amount, uint256 rewardDebt, bool seedInitialized) = farm.userInfo(pid, user);
        require(seedInitialized, "Seed not initialized");

        // Get pool info
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint16 rareDropChanceBps,
            uint256 rareDropAmount
        ) = farm.poolInfo(pid);

        // Simulate random number generation
        uint256 blockAdjust = 0;
        bytes32 prevBlockHash;
        while (true) {
            prevBlockHash = blockhash(targetBlock - 1 + blockAdjust);
            if (prevBlockHash == bytes32(0) && targetBlock - 1 + blockAdjust != block.number) {
                // Block hash not available, try next block
                blockAdjust++;
                continue;
            }
            break;
        }

        if (prevBlockHash == bytes32(0)) {
            // Use current block's hash if target block hash not available
            prevBlockHash = blockhash(block.number - 1);
        }

        // Simulate random number generation
        uint256 forcedRandom = uint256(keccak256(abi.encodePacked(prevBlockHash, user, pid)));

        // Check if rare drop should occur
        if (forcedRandom % 10000 < rareDropChanceBps) {
            // Rare drop should occur
            console.log("Rare drop should occur for user", user);
            console.log("Drop amount:", rareDropAmount);
        }
    }

    function test_rareDropChance() public {
        uint256 depositAmount = 100 ether;

        // Alice deposits to pool 0 (which has rare drop chance)
        vm.startPrank(alice);
        lpToken1.approve(address(farm), depositAmount);
        farm.deposit(0, depositAmount);
        vm.stopPrank();

        // Skip blocks past start block
        vm.roll(farm.startBlock() + 5);

        // Simulate rare drop chance
        _simulateRareDrop(0, alice, block.number);
    }

}

// Helper contract for reentrancy tests
contract ReentrancyAttacker {
    ResourceFarm private farm;
    IERC20 private lpToken;
    uint256 private attackCount;
    uint256 private pid;
    uint256 private amount;
    
    constructor(ResourceFarm _farm, IERC20 _lpToken) {
        farm = _farm;
        lpToken = _lpToken;
    }
    
    function attackDeposit(uint256 _pid, uint256 _amount) external {
        pid = _pid;
        amount = _amount;
        lpToken.approve(address(farm), _amount);
        farm.deposit(_pid, _amount);
    }
    
    function attackWithdraw(uint256 _pid, uint256 _amount) external {
        pid = _pid;
        amount = _amount;
        lpToken.approve(address(farm), _amount);
        farm.deposit(_pid, _amount);
        farm.withdraw(_pid, _amount);
    }
    
    // This will be called during the token transfer
    receive() external payable {
        if (attackCount == 0) {
            attackCount++;
            // Try to reenter during the token transfer
            farm.deposit(pid, amount);
        }
    }
    
    // This will be called during the token transfer if receive() is not matched
    fallback() external payable {
        if (attackCount == 0) {
            attackCount++;
            // Try to reenter during the token transfer
            farm.withdraw(pid, amount);
        }
    }
}

// Mock ERC20 that calls receive() on transfer to enable reentrancy attempts
contract MockERC20WithCallback is MockERC20 {
    constructor() MockERC20("Mock Token", "MOCK", 18) {}
    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        super.transfer(to, amount);
        
        // Call receive() on the recipient to enable reentrancy attempt
        (bool success,) = to.call{value: 0}("");
        require(success, "Transfer callback failed");
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        super.transferFrom(from, to, amount);
        
        // Call receive() on the recipient to enable reentrancy attempt
        (bool success,) = to.call{value: 0}("");
        require(success, "Transfer callback failed");
        
        return true;
    }
} 