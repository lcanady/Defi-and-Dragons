// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ability.sol";
import "../amm/ArcaneCrafting.sol";
import "../amm/ArcaneFactory.sol";
import "../ItemDrop.sol";

/// @title AbilityIntegration
/// @notice Integrates hero abilities with AMM and crafting systems
contract AbilityIntegration is Ownable {
    Ability public immutable abilityContract;
    ArcaneCrafting public immutable craftingContract;
    ArcaneFactory public immutable factory;
    ItemDrop public immutable itemDrop;

    // Constants
    uint256 public constant MAX_FEE_REDUCTION = 5000; // 50% in basis points
    uint256 public constant MAX_CRAFTING_BOOST = 5000; // 50% in basis points
    uint256 public constant MAX_VRF_REDUCTION = 5000; // 50% in basis points

    // Events
    event AbilityBenefitsApplied(
        uint256 indexed characterId,
        uint256 indexed abilityId,
        uint256 ammFeeReduction,
        uint256 craftingBoost,
        uint256 vrfReduction
    );

    constructor(
        address _abilityContract,
        address _craftingContract,
        address _factory,
        address _itemDrop
    ) {
        _transferOwnership(msg.sender);
        abilityContract = Ability(_abilityContract);
        craftingContract = ArcaneCrafting(_craftingContract);
        factory = ArcaneFactory(_factory);
        itemDrop = ItemDrop(_itemDrop);
    }

    /// @notice Calculate AMM fee reduction for a character
    /// @param characterId ID of the character
    /// @return Reduced fee in basis points
    function calculateAMMFeeReduction(uint256 characterId) external view returns (uint256) {
        (uint256 feeReduction, , , ) = abilityContract.getAbilityBenefits(characterId);
        return feeReduction;
    }

    /// @notice Calculate crafting success boost for a character
    /// @param characterId ID of the character
    /// @return Success boost in basis points
    function calculateCraftingBoost(uint256 characterId) external view returns (uint256) {
        (, uint256 craftingBoost, , ) = abilityContract.getAbilityBenefits(characterId);
        return craftingBoost;
    }

    /// @notice Calculate VRF cost reduction for a character
    /// @param characterId ID of the character
    /// @return Cost reduction in basis points
    function calculateVRFReduction(uint256 characterId) external view returns (uint256) {
        (, , uint256 vrfReduction, ) = abilityContract.getAbilityBenefits(characterId);
        return vrfReduction;
    }

    /// @notice Apply ability benefits to a crafting attempt
    /// @param characterId ID of the character
    /// @param _recipeId ID of the recipe being crafted
    /// @return (success boost, fee reduction)
    function applyCraftingBenefits(uint256 characterId, uint256 _recipeId) external view returns (uint256, uint256) {
        (, uint256 craftingBoost, , ) = abilityContract.getAbilityBenefits(characterId);
        (uint256 feeReduction, , , ) = abilityContract.getAbilityBenefits(characterId);
        
        return (craftingBoost, feeReduction);
    }

    /// @notice Apply ability benefits to an AMM interaction
    /// @param characterId ID of the character
    /// @return Fee reduction in basis points
    function applyAMMBenefits(uint256 characterId) external view returns (uint256) {
        (uint256 feeReduction, , , ) = abilityContract.getAbilityBenefits(characterId);
        return feeReduction;
    }

    /// @notice Apply ability benefits to a VRF request
    /// @param characterId ID of the character
    /// @return Cost reduction in basis points
    function applyVRFBenefits(uint256 characterId) external view returns (uint256) {
        (, , uint256 vrfReduction, ) = abilityContract.getAbilityBenefits(characterId);
        return vrfReduction;
    }

    /// @notice Check if a character's ability is active and can be used
    /// @param characterId ID of the character
    /// @return bool Whether the ability is active and usable
    function canUseAbility(uint256 characterId) external view returns (bool) {
        return abilityContract.hasActiveAbility(characterId);
    }
} 