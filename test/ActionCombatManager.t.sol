// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ActionCombatManager.sol";
import "./mocks/MockCombatQuestValidator.sol";

contract ActionCombatManagerTest is Test {
    ActionCombatManager public manager;
    MockCombatQuestValidator public validator;
    
    address public admin = address(0x1);
    address public platformValidator = address(0x2);
    address public combatDesigner = address(0x3);
    address public user = address(0x4);
    
    bytes32 public constant PLATFORM_VALIDATOR_ROLE = keccak256("PLATFORM_VALIDATOR_ROLE");
    bytes32 public constant COMBAT_DESIGNER_ROLE = keccak256("COMBAT_DESIGNER_ROLE");
    
    bytes32 public partyId = keccak256("testParty");
    uint256 public questId = 1;
    
    function setUp() public {
        validator = new MockCombatQuestValidator();
        
        vm.startPrank(admin);
        manager = new ActionCombatManager(address(validator));
        
        // Grant roles
        manager.grantRole(PLATFORM_VALIDATOR_ROLE, platformValidator);
        manager.grantRole(COMBAT_DESIGNER_ROLE, combatDesigner);
        vm.stopPrank();

        // Set the combat requirement for the quest for all tests
        validator.setCombatRequirement(questId, 100);
    }
    
    function testActionEffectConfiguration() public {
        vm.startPrank(combatDesigner);
        
        // Configure trade action
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            3600,    // cooldownPeriod (1 hour)
            5,       // maxUses
            true     // enabled
        );
        
        // Verify configuration
        (uint256 baseDamage, uint256 cooldownPeriod, uint256 maxUses, bool enabled) = manager.actionEffects(manager.TRADE_ACTION());
        assertEq(baseDamage, 100, "Base damage not set correctly");
        assertEq(cooldownPeriod, 3600, "Cooldown period not set correctly");
        assertEq(maxUses, 5, "Max uses not set correctly");
        assertTrue(enabled, "Action not enabled");
        
        vm.stopPrank();
    }
    
    function testUnauthorizedActionConfiguration() public {
        vm.startPrank(user);
        
        // Test will pass if this call reverts for any reason
        bool success = false;
        try manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,
            3600,
            5,
            true
        ) {
            success = true;
        } catch {
            // Expected to fail
        }
        
        // Test passes if the call failed (i.e., reverted)
        assertFalse(success, "Unauthorized call should have reverted");
        
        vm.stopPrank();
    }
    
    function testProcessAction() public {
        // Set up action configuration
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            0,       // No cooldown for testing
            5,       // maxUses
            true     // enabled
        );
        vm.stopPrank();
        
        // Process action as platform validator
        vm.startPrank(platformValidator);
        uint256 actionValue = 1 ether; // 1 ETH trade value
        uint256 damageDealt = manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            actionValue
        );
        vm.stopPrank();
        
        // Verify damage calculation
        uint256 expectedDamage = 100 + (actionValue / 1e18); // baseDamage + tradeValue
        assertEq(damageDealt, expectedDamage, "Damage calculation incorrect");
        
        // Verify enemy was recorded as defeated
        assertTrue(validator.enemyDefeatedCalled(), "Enemy defeated not called");
        assertEq(validator.lastPartyId(), partyId, "Party ID incorrect");
        assertEq(validator.lastQuestId(), questId, "Quest ID incorrect");
        assertEq(validator.lastEnemyType(), 100, "Enemy type incorrect");
        
        // Verify action usage tracking
        (uint256 lastUsed, uint256 usageCount, uint256 remainingUses, uint256 cooldownEnds) = 
            manager.getActionTracking(partyId, questId, manager.TRADE_ACTION());
        
        assertEq(usageCount, 1, "Usage count not incremented");
        assertEq(remainingUses, 4, "Remaining uses incorrect");
        assertEq(lastUsed, block.timestamp, "Last used timestamp incorrect");
        assertEq(cooldownEnds, block.timestamp, "Cooldown end time incorrect"); // No cooldown set
    }
    
    function testActionCooldown() public {
        // Set up action configuration with a non-zero cooldown period
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            3600,    // cooldownPeriod (1 hour)
            5,       // maxUses
            true     // enabled
        );
        vm.stopPrank();
        
        // First, we need to set the initial timestamp to something non-zero
        // to avoid cooldown calculation issues
        uint256 initialTime = 1000000;
        vm.warp(initialTime);
        
        // Process action first time
        vm.startPrank(platformValidator);
        manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        );
        
        // Try to use the same action again immediately (should be on cooldown)
        bool success = false;
        try manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        ) {
            success = true;
        } catch Error(string memory reason) {
            // Check if the revert reason is what we expect
            assertEq(reason, "Action on cooldown", "Wrong revert reason");
        }
        
        // Call should fail due to cooldown
        assertFalse(success, "Action should be on cooldown");
        
        // Fast forward past cooldown
        vm.warp(initialTime + 3601);
        
        // Should now succeed
        uint256 damageDealt = manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        );
        
        // Verify it worked
        assertTrue(damageDealt > 0, "Action should succeed after cooldown");
        
        vm.stopPrank();
    }
    
    function testMaxUsesLimit() public {
        // Set up action with only 2 max uses and no cooldown
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            0,       // no cooldown for testing
            2,       // maxUses (only 2)
            true     // enabled
        );
        vm.stopPrank();
        
        vm.startPrank(platformValidator);
        
        // Use action twice
        manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        );
        
        manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        );
        
        // Third attempt should fail with the specific error
        bool success = false;
        try manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        ) {
            success = true;
        } catch Error(string memory reason) {
            assertEq(reason, "Max action uses exceeded", "Wrong revert reason");
        }
        
        assertFalse(success, "Should have failed due to max uses limit");
        
        vm.stopPrank();
    }
    
    function testDisabledAction() public {
        // Set up disabled action
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            3600,    // cooldownPeriod
            5,       // maxUses
            false    // disabled
        );
        vm.stopPrank();
        
        // Attempt to use disabled action
        vm.startPrank(platformValidator);
        
        bool success = false;
        try manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        ) {
            success = true;
        } catch Error(string memory reason) {
            assertEq(reason, "Action type not enabled", "Wrong revert reason");
        }
        
        assertFalse(success, "Should have failed due to disabled action");
        
        vm.stopPrank();
    }
    
    function testUnauthorizedActionProcessing() public {
        // Set up action configuration
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,
            3600,
            5,
            true
        );
        vm.stopPrank();
        
        // Attempt to process as non-validator
        vm.startPrank(user);
        
        bool success = false;
        try manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        ) {
            success = true;
        } catch {
            // Expected to fail - any error is fine since it's an access control error
        }
        
        assertFalse(success, "Unauthorized call should have reverted");
        
        vm.stopPrank();
    }
    
    function testDifferentActionTypes() public {
        // Set up different action types
        vm.startPrank(combatDesigner);
        
        // Configure trade action
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,     // baseDamage
            0,       // no cooldown for testing
            5,       // maxUses
            true     // enabled
        );
        
        // Configure NFT sale action
        manager.configureActionEffect(
            manager.NFT_SALE_ACTION(),
            200,     // higher base damage
            0,       // no cooldown for testing
            5,       // maxUses
            true     // enabled
        );
        
        // Configure liquidity action
        manager.configureActionEffect(
            manager.LIQUIDITY_ACTION(),
            150,     // medium base damage
            0,       // no cooldown for testing
            5,       // maxUses
            true     // enabled
        );
        
        vm.stopPrank();
        
        // Process different actions and verify damage calculations
        vm.startPrank(platformValidator);
        
        // Trade action (base + value/1e18)
        uint256 tradeValue = 2 ether;
        uint256 tradeDamage = manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            tradeValue
        );
        assertEq(tradeDamage, 102, "Trade damage calculation incorrect");
        
        // Reset validator for tracking calls
        validator.reset();
        
        // NFT sale action (base + value/1e17) - 10x multiplier
        uint256 nftValue = 1 ether;
        uint256 nftDamage = manager.processAction(
            user,
            partyId,
            questId,
            manager.NFT_SALE_ACTION(),
            nftValue
        );
        assertEq(nftDamage, 210, "NFT damage calculation incorrect");
        
        // Reset validator for tracking calls
        validator.reset();
        
        // Liquidity action (base + value/1e18 * 2) - 2x multiplier
        uint256 liquidityValue = 1 ether;
        uint256 liquidityDamage = manager.processAction(
            user,
            partyId,
            questId,
            manager.LIQUIDITY_ACTION(),
            liquidityValue
        );
        assertEq(liquidityDamage, 152, "Liquidity damage calculation incorrect");
        
        vm.stopPrank();
    }
    
    function testActionTrackingView() public {
        // Set up action configuration
        vm.startPrank(combatDesigner);
        manager.configureActionEffect(
            manager.TRADE_ACTION(),
            100,
            3600,
            5,
            true
        );
        vm.stopPrank();
        
        // Initially tracking should show zero usage but will calculate cooldownEnds based on lastUsed (0) + cooldownPeriod
        (uint256 lastUsed, uint256 usageCount, uint256 remainingUses, uint256 cooldownEnds) = 
            manager.getActionTracking(partyId, questId, manager.TRADE_ACTION());
        
        assertEq(lastUsed, 0, "Initial last used should be zero");
        assertEq(usageCount, 0, "Initial usage count should be zero");
        assertEq(remainingUses, 5, "Initial remaining uses should be 5");
        // In the getActionTracking function, cooldownEnds is calculated as tracking.lastUsed + effect.cooldownPeriod
        // Since lastUsed is 0 and cooldownPeriod is 3600, cooldownEnds will be 3600
        assertEq(cooldownEnds, 3600, "Initial cooldown ends should be cooldownPeriod since lastUsed is 0");
        
        // Set a specific block timestamp for predictable testing
        uint256 testTime = 1000000;
        vm.warp(testTime);
        
        // Process an action
        vm.startPrank(platformValidator);
        manager.processAction(
            user,
            partyId,
            questId,
            manager.TRADE_ACTION(),
            1 ether
        );
        vm.stopPrank();
        
        // Verify tracking is updated
        (lastUsed, usageCount, remainingUses, cooldownEnds) = 
            manager.getActionTracking(partyId, questId, manager.TRADE_ACTION());
        
        assertEq(lastUsed, testTime, "Last used not updated");
        assertEq(usageCount, 1, "Usage count not updated");
        assertEq(remainingUses, 4, "Remaining uses not updated");
        assertEq(cooldownEnds, testTime + 3600, "Cooldown end time not updated");
    }
} 