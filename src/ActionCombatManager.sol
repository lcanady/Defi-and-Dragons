// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./CombatQuestValidator.sol";

contract ActionCombatManager is AccessControl {
    bytes32 public constant PLATFORM_VALIDATOR_ROLE = keccak256("PLATFORM_VALIDATOR_ROLE");
    bytes32 public constant COMBAT_DESIGNER_ROLE = keccak256("COMBAT_DESIGNER_ROLE");

    CombatQuestValidator public immutable combatValidator;

    // Action types
    uint256 public constant TRADE_ACTION = 1;
    uint256 public constant NFT_SALE_ACTION = 2;
    uint256 public constant NFT_PURCHASE_ACTION = 3;
    uint256 public constant LIQUIDITY_ACTION = 4;
    uint256 public constant STAKE_ACTION = 5;

    // Combat effect configuration
    struct ActionEffect {
        uint256 baseDamage; // Base damage for this action type
        uint256 cooldownPeriod; // Minimum time between actions
        uint256 maxUses; // Max times this action can be used in combat
        bool enabled; // Whether this action type is enabled
    }

    // Action tracking
    struct ActionTracking {
        uint256 lastUsed; // Last timestamp action was used
        uint256 usageCount; // Number of times action has been used
    }

    // Mappings
    mapping(uint256 => ActionEffect) public actionEffects; // actionType => effect
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => ActionTracking))) public actionUsage;
    // partyId => questId => actionType => tracking

    event ActionProcessed(
        bytes32 indexed partyId, uint256 indexed questId, uint256 actionType, uint256 damage, address indexed actor
    );

    event ActionEffectConfigured(
        uint256 indexed actionType, uint256 baseDamage, uint256 cooldownPeriod, uint256 maxUses, bool enabled
    );

    constructor(address _combatValidator) {
        combatValidator = CombatQuestValidator(_combatValidator);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Combat Designer Functions
    function configureActionEffect(
        uint256 actionType,
        uint256 baseDamage,
        uint256 cooldownPeriod,
        uint256 maxUses,
        bool enabled
    ) external onlyRole(COMBAT_DESIGNER_ROLE) {
        actionEffects[actionType] =
            ActionEffect({ baseDamage: baseDamage, cooldownPeriod: cooldownPeriod, maxUses: maxUses, enabled: enabled });

        emit ActionEffectConfigured(actionType, baseDamage, cooldownPeriod, maxUses, enabled);
    }

    // Platform Action Processing
    function processAction(address actor, bytes32 partyId, uint256 questId, uint256 actionType, uint256 actionValue)
        external
        onlyRole(PLATFORM_VALIDATOR_ROLE)
        returns (uint256 damageDealt)
    {
        ActionEffect memory effect = actionEffects[actionType];
        require(effect.enabled, "Action type not enabled");

        ActionTracking storage tracking = actionUsage[partyId][questId][actionType];

        // Validate cooldown
        require(block.timestamp >= tracking.lastUsed + effect.cooldownPeriod, "Action on cooldown");

        // Validate usage count
        require(tracking.usageCount < effect.maxUses, "Max action uses exceeded");

        // Calculate damage based on action value and base damage
        // actionValue could be trade amount, NFT price, etc.
        damageDealt = calculateDamage(effect.baseDamage, actionValue, actionType);

        // Update tracking
        tracking.lastUsed = block.timestamp;
        tracking.usageCount++;

        // Record enemy damage through combat validator
        // Assuming enemy type is stored in combat session
        combatValidator.recordEnemyDefeated(partyId, questId, getEnemyType(partyId, questId));

        emit ActionProcessed(partyId, questId, actionType, damageDealt, actor);

        return damageDealt;
    }

    // Helper function to calculate damage based on action value
    function calculateDamage(uint256 baseDamage, uint256 actionValue, uint256 actionType)
        internal
        pure
        returns (uint256)
    {
        // Different scaling for different action types
        if (actionType == TRADE_ACTION) {
            // Scale with trade size
            return baseDamage + (actionValue / 1e18); // Assuming 18 decimals
        } else if (actionType == NFT_SALE_ACTION || actionType == NFT_PURCHASE_ACTION) {
            // Scale with NFT price
            return baseDamage + (actionValue / 1e17); // Higher scaling for NFT actions
        } else if (actionType == LIQUIDITY_ACTION) {
            // Scale with liquidity amount
            return baseDamage + (actionValue / 1e18) * 2; // Double scaling for liquidity
        } else if (actionType == STAKE_ACTION) {
            // Scale with stake amount
            return baseDamage + (actionValue / 1e18) * 3; // Triple scaling for staking
        }

        return baseDamage; // Default to base damage for unknown actions
    }

    // Helper function to get enemy type from combat session
    function getEnemyType(bytes32 /*partyId*/, uint256 questId) internal view returns (uint256) {
        // Get enemy type from combat validator's quest requirements
        (,, uint256 targetEnemyType,,,) = combatValidator.combatRequirements(questId);
        return targetEnemyType;
    }

    // View Functions
    function getActionTracking(bytes32 partyId, uint256 questId, uint256 actionType)
        external
        view
        returns (uint256 lastUsed, uint256 usageCount, uint256 remainingUses, uint256 cooldownEnds)
    {
        ActionEffect memory effect = actionEffects[actionType];
        ActionTracking memory tracking = actionUsage[partyId][questId][actionType];

        return (
            tracking.lastUsed,
            tracking.usageCount,
            effect.maxUses - tracking.usageCount,
            tracking.lastUsed + effect.cooldownPeriod
        );
    }
}
