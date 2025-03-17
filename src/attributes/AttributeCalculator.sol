// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Types.sol";
import "../interfaces/IAttributeProvider.sol";
import "../Character.sol";
import "../Equipment.sol";
import "../pets/Mount.sol";

/// @title AttributeCalculator
/// @notice Calculates combined attribute calculations and platform-wide bonuses
contract AttributeCalculator is Ownable {
    // Contract references
    Character public immutable characterContract;
    Equipment public immutable equipmentContract;
    Mount public mountContract;

    // Bonus providers
    mapping(address => bool) public providers;
    address[] private providerList;

    // Bonus multipliers (in basis points, 10000 = 100%)
    uint256 public constant BASE_POINTS = 10000;
    
    // Events
    event AttributesCalculated(
        uint256 indexed characterId,
        uint256 totalStrength,
        uint256 totalAgility,
        uint256 totalMagic,
        uint256 bonusMultiplier
    );
    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);

    // Errors
    error InvalidCharacter();
    error InvalidBonus();
    error InvalidStatType();
    error InvalidProvider();

    constructor(
        address _characterContract,
        address _equipmentContract
    ) {
        characterContract = Character(_characterContract);
        equipmentContract = Equipment(_equipmentContract);
    }

    /// @notice Set the mount contract address
    /// @param _mountContract The address of the mount contract
    function setMountContract(address _mountContract) external onlyOwner {
        if (_mountContract == address(0)) revert InvalidProvider();
        mountContract = Mount(_mountContract);
    }

    /// @notice Add a bonus provider
    /// @param provider The address of the provider contract
    function addProvider(address provider) external onlyOwner {
        if (provider == address(0)) revert InvalidProvider();
        if (!providers[provider]) {
            providers[provider] = true;
            providerList.push(provider);
            emit ProviderAdded(provider);
        }
    }

    /// @notice Remove a bonus provider
    /// @param provider The address of the provider contract
    function removeProvider(address provider) external onlyOwner {
        if (providers[provider]) {
            providers[provider] = false;
            // Remove from providerList
            for (uint256 i = 0; i < providerList.length; i++) {
                if (providerList[i] == provider) {
                    providerList[i] = providerList[providerList.length - 1];
                    providerList.pop();
                    break;
                }
            }
            emit ProviderRemoved(provider);
        }
    }

    /// @notice Calculate total attributes for a character including all bonuses
    /// @param characterId The ID of the character
    /// @return totalStats Combined stats with multiplier applied
    /// @return bonusMultiplier The total bonus multiplier (in basis points)
    function calculateTotalAttributes(uint256 characterId)
        public
        returns (Types.Stats memory totalStats, uint256 bonusMultiplier)
    {
        // Get character data
        (Types.Stats memory baseStats,,) = characterContract.getCharacter(characterId);

        // Get equipment bonuses
        Types.Stats memory equipmentBonuses = getEquipmentBonuses(characterId);

        // Calculate raw total (base + equipment)
        Types.Stats memory rawStats = Types.Stats({
            strength: baseStats.strength + equipmentBonuses.strength,
            agility: baseStats.agility + equipmentBonuses.agility,
            magic: baseStats.magic + equipmentBonuses.magic
        });

        // Calculate bonus multiplier based on base stats only
        bonusMultiplier = calculateTotalBonusMultiplier(characterId, baseStats);

        // Apply multiplier to raw stats
        totalStats = Types.Stats({
            strength: (rawStats.strength * bonusMultiplier) / BASE_POINTS,
            agility: (rawStats.agility * bonusMultiplier) / BASE_POINTS,
            magic: (rawStats.magic * bonusMultiplier) / BASE_POINTS
        });

        emit AttributesCalculated(
            characterId,
            totalStats.strength,
            totalStats.agility,
            totalStats.magic,
            bonusMultiplier
        );

        return (totalStats, bonusMultiplier);
    }

    /// @notice Get raw stats for a character without applying multiplier
    /// @param characterId The ID of the character
    /// @return rawStats Combined raw stats (base + equipment) before multiplier
    function getRawStats(uint256 characterId) public view returns (Types.Stats memory rawStats) {
        // Get character data
        (Types.Stats memory baseStats,,) = characterContract.getCharacter(characterId);

        // Get equipment bonuses
        Types.Stats memory equipmentBonuses = getEquipmentBonuses(characterId);

        // Calculate raw total (base + equipment)
        rawStats = Types.Stats({
            strength: baseStats.strength + equipmentBonuses.strength,
            agility: baseStats.agility + equipmentBonuses.agility,
            magic: baseStats.magic + equipmentBonuses.magic
        });

        return rawStats;
    }

    /// @notice Get the bonus for a specific stat type
    /// @param characterId The ID of the character
    /// @param statType 0 for strength, 1 for agility, 2 for magic
    /// @return The calculated bonus for the specified stat
    function getStatBonus(uint256 characterId, uint256 statType) public returns (uint256) {
        if (statType > 2) revert InvalidStatType();
        
        (Types.Stats memory totalStats,) = calculateTotalAttributes(characterId);
        
        if (statType == 0) return totalStats.strength;
        else if (statType == 1) return totalStats.agility;
        else return totalStats.magic;
    }

    /// @notice Get base stats for a character without any bonuses
    /// @param characterId The ID of the character
    /// @return stats The base stats
    function getBaseStats(uint256 characterId) public view returns (Types.Stats memory stats) {
        (stats,,) = characterContract.getCharacter(characterId);
        return stats;
    }

    /// @notice Get equipment bonuses for a character
    /// @param characterId The ID of the character
    /// @return bonuses The equipment stat bonuses
    function getEquipmentBonuses(uint256 characterId) public view returns (Types.Stats memory bonuses) {
        (, Types.EquipmentSlots memory equipment,) = characterContract.getCharacter(characterId);
        
        bonuses = Types.Stats({
            strength: 0,
            agility: 0,
            magic: 0
        });

        // Add weapon bonuses if equipped and active
        if (equipment.weaponId != 0) {
            (Types.EquipmentStats memory weaponStats, bool weaponExists) = equipmentContract.getEquipmentStats(equipment.weaponId);
            if (weaponExists && weaponStats.isActive) {
                bonuses.strength += weaponStats.strengthBonus;
                bonuses.agility += weaponStats.agilityBonus;
                bonuses.magic += weaponStats.magicBonus;
            }
        }

        // Add armor bonuses if equipped and active
        if (equipment.armorId != 0) {
            (Types.EquipmentStats memory armorStats, bool armorExists) = equipmentContract.getEquipmentStats(equipment.armorId);
            if (armorExists && armorStats.isActive) {
                bonuses.strength += armorStats.strengthBonus;
                bonuses.agility += armorStats.agilityBonus;
                bonuses.magic += armorStats.magicBonus;
            }
        }

        return bonuses;
    }

    /// @notice Calculate the total bonus multiplier for a character
    /// @param characterId The ID of the character
    /// @param baseStats The base stats before any bonuses
    /// @return The total bonus multiplier in basis points
    function calculateTotalBonusMultiplier(uint256 characterId, Types.Stats memory baseStats) public view returns (uint256) {
        uint256 totalBonus = BASE_POINTS;  // Start with 100%

        // Get character state for alignment and level bonuses
        (,, Types.CharacterState memory state) = characterContract.getCharacter(characterId);

        // Add bonuses from all active providers
        address[] memory activeProviders = getActiveProviders();
        for (uint256 i = 0; i < activeProviders.length; i++) {
            IAttributeProvider provider = IAttributeProvider(activeProviders[i]);
            if (provider.isActive(characterId)) {
                totalBonus += provider.getBonus(characterId);
            }
        }

        // Add alignment bonus based on base stats
        // Only apply alignment bonus if the stat is strictly greater than others
        if (state.alignment == Types.Alignment.STRENGTH && 
            baseStats.strength > baseStats.agility && 
            baseStats.strength > baseStats.magic) {
            totalBonus += 500; // 5% bonus
        } else if (state.alignment == Types.Alignment.AGILITY && 
            baseStats.agility > baseStats.strength && 
            baseStats.agility > baseStats.magic) {
            totalBonus += 500;
        } else if (state.alignment == Types.Alignment.MAGIC && 
            baseStats.magic > baseStats.strength && 
            baseStats.magic > baseStats.agility) {
            totalBonus += 500;
        }

        // Add level bonus (1% per level)
        totalBonus += state.level * 100;

        return totalBonus;
    }

    /// @notice Get all active bonus providers
    /// @return Array of active provider addresses
    function getActiveProviders() public view returns (address[] memory) {
        uint256 activeCount = 0;
        
        // Count active providers
        for (uint256 i = 0; i < providerList.length; i++) {
            if (providers[providerList[i]]) {
                activeCount++;
            }
        }

        // Create array of active providers
        address[] memory activeProviders = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < providerList.length; i++) {
            if (providers[providerList[i]]) {
                activeProviders[index] = providerList[i];
                index++;
            }
        }

        return activeProviders;
    }

    /// @notice Get the quest fee reduction for a character
    /// @param characterId The ID of the character
    /// @return The quest fee reduction in basis points
    function getQuestFeeReduction(uint256 characterId) external view returns (uint256) {
        if (address(mountContract) == address(0)) return 0;
        if (!mountContract.hasActiveMount(characterId)) return 0;
        (uint256 questFeeReduction,,,) = mountContract.getMountBenefits(characterId);
        return questFeeReduction;
    }
}
