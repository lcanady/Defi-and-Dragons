// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICharacter.sol";
import "../interfaces/Types.sol";
import "../interfaces/IAttributeProvider.sol";
import "../Character.sol";

/// @title Ability
/// @notice Manages hero abilities that affect game mechanics
contract Ability is ERC721, Ownable, IAttributeProvider {
    struct AbilityData {
        string name;
        uint256 ammFeeReductionBps; // AMM fee reduction in basis points
        uint256 craftingSuccessBoostBps; // Crafting success rate boost in basis points
        uint256 vrfCostReductionBps; // VRF cost reduction in basis points
        uint256 cooldownReduction; // Cooldown reduction in seconds
        bool active;
        uint256 requiredLevel; // Minimum level required to use ability
    }

    struct HeroAbility {
        uint256 abilityId;
        uint256 lastUsed;
        bool active;
    }

    // Storage
    mapping(uint256 => AbilityData) public abilities;
    mapping(uint256 => HeroAbility) public heroAbilities; // characterId => HeroAbility
    uint256 private _nextAbilityId;

    // Character contract reference
    ICharacter public immutable characterContract;

    // Events
    event AbilityCreated(uint256 indexed abilityId, string name);
    event AbilityLearned(uint256 indexed characterId, uint256 indexed abilityId);
    event AbilityUsed(uint256 indexed characterId, uint256 indexed abilityId);
    event AbilityActivated(uint256 indexed abilityId);
    event AbilityDeactivated(uint256 indexed abilityId);

    // Errors
    error AbilityNotActive();
    error InsufficientLevel();
    error AbilityCooldown();
    error NoActiveAbility();
    error NotCharacterOwner();

    constructor(address _characterContract) ERC721("Hero Ability", "ABILITY") {
        characterContract = ICharacter(_characterContract);
    }

    /// @notice Create a new ability type
    function createAbility(
        string memory name,
        uint256 ammFeeReductionBps,
        uint256 craftingSuccessBoostBps,
        uint256 vrfCostReductionBps,
        uint256 cooldownReduction,
        uint256 requiredLevel
    ) external onlyOwner returns (uint256) {
        require(ammFeeReductionBps <= 5000, "Fee reduction too high"); // Max 50%
        require(craftingSuccessBoostBps <= 5000, "Crafting boost too high"); // Max 50%
        require(vrfCostReductionBps <= 5000, "VRF reduction too high"); // Max 50%
        require(cooldownReduction <= 1 days, "Cooldown reduction too high"); // Max 1 day

        uint256 abilityId = _nextAbilityId++;
        abilities[abilityId] = AbilityData({
            name: name,
            ammFeeReductionBps: ammFeeReductionBps,
            craftingSuccessBoostBps: craftingSuccessBoostBps,
            vrfCostReductionBps: vrfCostReductionBps,
            cooldownReduction: cooldownReduction,
            active: true,
            requiredLevel: requiredLevel
        });

        emit AbilityCreated(abilityId, name);
        return abilityId;
    }

    /// @notice Learn an ability for a character
    function learnAbility(uint256 characterId, uint256 abilityId) external {
        if (!abilities[abilityId].active) revert AbilityNotActive();
        if (characterContract.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();

        // Check character level requirement
        (,, Types.CharacterState memory state) = characterContract.getCharacter(characterId);
        if (state.level < abilities[abilityId].requiredLevel) revert InsufficientLevel();

        heroAbilities[characterId] = HeroAbility({ abilityId: abilityId, lastUsed: 0, active: true });

        emit AbilityLearned(characterId, abilityId);
    }

    /// @notice Use a character's ability
    function useAbility(uint256 characterId) external returns (bool) {
        HeroAbility storage heroAbility = heroAbilities[characterId];
        if (!heroAbility.active) revert NoActiveAbility();

        AbilityData storage ability = abilities[heroAbility.abilityId];
        if (!ability.active) revert AbilityNotActive();

        // Check cooldown (1 hour minus any cooldown reduction)
        uint256 cooldownPeriod = 1 hours - ability.cooldownReduction;
        if (heroAbility.lastUsed > 0 && block.timestamp < heroAbility.lastUsed + cooldownPeriod) {
            revert AbilityCooldown();
        }

        heroAbility.lastUsed = block.timestamp;
        emit AbilityUsed(characterId, heroAbility.abilityId);
        return true;
    }

    /// @notice Check if a character has an active ability
    function hasActiveAbility(uint256 characterId) public view returns (bool) {
        return heroAbilities[characterId].active && abilities[heroAbilities[characterId].abilityId].active;
    }

    /// @notice Get ability benefits for a character
    function getAbilityBenefits(uint256 characterId)
        public
        view
        returns (uint256 ammFeeReduction, uint256 craftingBoost, uint256 vrfReduction, uint256 cdReduction)
    {
        HeroAbility memory heroAbility = heroAbilities[characterId];
        if (!heroAbility.active) return (0, 0, 0, 0);

        AbilityData memory ability = abilities[heroAbility.abilityId];
        if (!ability.active) return (0, 0, 0, 0);

        return (
            ability.ammFeeReductionBps,
            ability.craftingSuccessBoostBps,
            ability.vrfCostReductionBps,
            ability.cooldownReduction
        );
    }

    /// @notice Deactivate an ability type
    function deactivateAbility(uint256 abilityId) external onlyOwner {
        abilities[abilityId].active = false;
        emit AbilityDeactivated(abilityId);
    }

    /// @notice Activate an ability type
    function activateAbility(uint256 abilityId) external onlyOwner {
        abilities[abilityId].active = true;
        emit AbilityActivated(abilityId);
    }

    /// @inheritdoc IAttributeProvider
    function getBonus(uint256 characterId) external view override returns (uint256) {
        if (!hasActiveAbility(characterId)) return 0;
        (, uint256 craftingBoost,,) = getAbilityBenefits(characterId);
        return craftingBoost;
    }

    /// @inheritdoc IAttributeProvider
    function isActive(uint256 characterId) external view override returns (bool) {
        return hasActiveAbility(characterId);
    }
}
