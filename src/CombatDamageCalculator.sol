// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IEquipment.sol";

/// @title CombatDamageCalculator
/// @notice Handles damage calculations for combat, including weapon stat affinity
contract CombatDamageCalculator is Ownable {
    ICharacter public immutable characterContract;
    IEquipment public immutable equipmentContract;

    // Constants for damage calculations
    uint256 public constant BASE_DAMAGE = 10;
    uint256 public constant AFFINITY_BONUS_MULTIPLIER = 150; // 1.5x multiplier for stat affinity
    uint256 public constant SCALING_DENOMINATOR = 100;

    constructor(address _characterContract, address _equipmentContract) Ownable() {
        characterContract = ICharacter(_characterContract);
        equipmentContract = IEquipment(_equipmentContract);
    }

    /// @notice Calculate damage based on character stats and weapon affinity
    /// @param characterId The ID of the attacking character
    /// @param targetId The ID of the target character
    /// @return The calculated damage amount
    function calculateDamage(uint256 characterId, uint256 targetId) external view returns (uint256) {
        // Get character stats and equipment
        (Types.Stats memory stats, Types.EquipmentSlots memory equipment,) = characterContract.getCharacter(characterId);

        // Base damage starts at BASE_DAMAGE
        uint256 damage = BASE_DAMAGE;

        // If character has a weapon equipped, factor in stat affinity
        if (equipment.weaponId != 0) {
            (Types.EquipmentStats memory weaponStats, bool exists) =
                equipmentContract.getEquipmentStats(equipment.weaponId);

            if (exists && weaponStats.isActive) {
                // Get the relevant stat based on weapon's affinity
                uint256 affinityStat;
                if (weaponStats.statAffinity == Types.Alignment.STRENGTH) {
                    affinityStat = stats.strength;
                } else if (weaponStats.statAffinity == Types.Alignment.AGILITY) {
                    affinityStat = stats.agility;
                } else if (weaponStats.statAffinity == Types.Alignment.MAGIC) {
                    affinityStat = stats.magic;
                }

                // Calculate base damage using affinity stat
                damage = BASE_DAMAGE + affinityStat;

                // Apply weapon stat bonuses
                damage += weaponStats.strengthBonus + weaponStats.agilityBonus + weaponStats.magicBonus;

                // Apply affinity bonus if character's alignment matches weapon affinity
                (,, Types.CharacterState memory state) = characterContract.getCharacter(characterId);
                if (state.alignment == weaponStats.statAffinity) {
                    damage = (damage * AFFINITY_BONUS_MULTIPLIER) / SCALING_DENOMINATOR;
                }
            }
        }

        return damage;
    }
}
