// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ArcaneFactory } from "./ArcaneFactory.sol";
import { ArcanePair } from "./ArcanePair.sol";
import { Quest } from "../Quest.sol";
import { ItemDrop } from "../ItemDrop.sol";

error InsufficientLPTokens();
error BonusExceedsMaximum();

/// @title ArcaneQuestIntegration
/// @notice Integrates AMM functionality with the quest system
contract ArcaneQuestIntegration is Ownable, ReentrancyGuard {
    ArcaneFactory public immutable factory;
    Quest public immutable questContract;
    ItemDrop public immutable itemDrop;

    // Minimum LP token requirements for different quest tiers
    mapping(uint256 => uint256) public questTierLPRequirement;

    // Track which LP pairs are eligible for enhanced rewards
    mapping(address => bool) public eligibleLPPairs;

    // Enhanced drop rates for LP providers (multiplier in basis points, 10000 = 100%)
    mapping(address => uint256) public lpDropRateBonus;

    event QuestTierLPRequirementSet(uint256 indexed tier, uint256 requirement);
    event LPPairEligibilitySet(address indexed lpPair, bool eligible);
    event LPDropRateBonusSet(address indexed lpPair, uint256 bonus);
    event EnhancedRewardClaimed(address indexed user, uint256 indexed questId, uint256 bonus);

    constructor(address _factory, address _questContract, address _itemDrop) Ownable(msg.sender) {
        factory = ArcaneFactory(_factory);
        questContract = Quest(_questContract);
        itemDrop = ItemDrop(_itemDrop);
    }

    /// @notice Set LP token requirement for a quest tier
    /// @param _tier Quest tier
    /// @param _requirement Required LP token amount
    function setQuestTierLPRequirement(uint256 _tier, uint256 _requirement) external onlyOwner {
        questTierLPRequirement[_tier] = _requirement;
        emit QuestTierLPRequirementSet(_tier, _requirement);
    }

    /// @notice Set eligibility of LP pair for enhanced rewards
    /// @param _lpPair LP pair address
    /// @param _eligible Whether the pair is eligible
    function setLPPairEligibility(address _lpPair, bool _eligible) external onlyOwner {
        eligibleLPPairs[_lpPair] = _eligible;
        emit LPPairEligibilitySet(_lpPair, _eligible);
    }

    /// @notice Set drop rate bonus for LP providers
    /// @param _lpPair LP pair address
    /// @param _bonus Bonus in basis points
    function setLPDropRateBonus(address _lpPair, uint256 _bonus) external onlyOwner {
        if (_bonus > 10_000) revert BonusExceedsMaximum();
        lpDropRateBonus[_lpPair] = _bonus;
        emit LPDropRateBonusSet(_lpPair, _bonus);
    }

    /// @notice Check if a user meets LP requirements for a quest tier
    /// @param _user User address
    /// @param _tier Quest tier
    function meetsLPRequirement(address _user, uint256 _tier) public view returns (bool) {
        uint256 requirement = questTierLPRequirement[_tier];
        if (requirement == 0) return true;

        uint256 pairCount = factory.allPairsLength();
        for (uint256 i = 0; i < pairCount; i++) {
            address pair = factory.allPairs(i);
            if (!eligibleLPPairs[pair]) continue;

            ArcanePair lpToken = ArcanePair(pair);
            if (lpToken.balanceOf(_user) >= requirement) {
                return true;
            }
        }
        return false;
    }

    /// @notice Calculate drop rate bonus for a user
    /// @param _user User address
    function calculateDropRateBonus(address _user) public view returns (uint256) {
        uint256 maxBonus = 0;
        uint256 pairCount = factory.allPairsLength();

        for (uint256 i = 0; i < pairCount; i++) {
            address pair = factory.allPairs(i);
            if (!eligibleLPPairs[pair]) continue;

            ArcanePair lpToken = ArcanePair(pair);
            if (lpToken.balanceOf(_user) > 0) {
                uint256 bonus = lpDropRateBonus[pair];
                if (bonus > maxBonus) {
                    maxBonus = bonus;
                }
            }
        }

        return maxBonus;
    }

    /// @notice Start a quest with LP token requirements
    /// @param _characterId Character ID
    /// @param _questId Quest ID
    function startQuest(uint256 _characterId, uint256 _questId) external nonReentrant {
        if (!meetsLPRequirement(msg.sender, 1)) revert InsufficientLPTokens();
        questContract.startQuest(_characterId, _questId);
    }

    /// @notice Complete a quest with enhanced rewards for LP providers
    /// @param _characterId Character ID
    /// @param _questId Quest ID
    function completeQuest(uint256 _characterId, uint256 _questId) external nonReentrant {
        // Complete the base quest
        questContract.completeQuest(_characterId, _questId);

        // Calculate and apply bonus drop rates
        uint256 dropBonus = calculateDropRateBonus(msg.sender);
        if (dropBonus > 0) {
            // Request additional random drop with enhanced rates
            itemDrop.requestRandomDrop(msg.sender, dropBonus);
            emit EnhancedRewardClaimed(msg.sender, _questId, dropBonus);
        }
    }

    /// @notice Check if a user is eligible for enhanced rewards
    /// @param _user User address
    function isEligibleForEnhancedRewards(address _user) external view returns (bool) {
        return calculateDropRateBonus(_user) > 0;
    }
}
