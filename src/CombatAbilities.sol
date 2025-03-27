// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";

// Custom errors
error AbilityNotActive();
error AbilityOnCooldown();
error ComboTooShort();

/// @title CombatAbilities
/// @notice Manages abilities, elements, and special effects for combat
contract CombatAbilities is Ownable {
    using Math for uint256;

    // Element types
    enum Element {
        NEUTRAL,
        FIRE,
        WATER,
        EARTH,
        AIR,
        LIGHT,
        DARK
    }

    // Ability types
    enum AbilityType {
        DAMAGE, // Direct damage
        DOT, // Damage over time
        BUFF, // Positive status effect
        DEBUFF, // Negative status effect
        HEAL, // Healing effect
        SHIELD, // Damage reduction
        SPECIAL // Special effects

    }

    // Packed struct - saves gas by using smaller uint types
    struct Ability {
        string name;
        AbilityType abilityType;
        Element element;
        uint32 power; // Reduced from uint256
        uint32 duration; // Reduced from uint256
        uint32 cooldown; // Reduced from uint256
        bool isAOE;
        bool requiresCharge;
        string[] requirements;
        bool active;
    }

    // Packed struct for status effects
    struct StatusEffect {
        bytes32 abilityId;
        uint40 startTime; // Reduced from uint256
        uint32 duration; // Reduced from uint256
        uint32 power; // Reduced from uint256
        bool isActive;
    }

    // Packed struct for combo bonus
    struct ComboBonus {
        Element[] elements;
        uint32 bonusMultiplier; // Reduced from uint256
        uint32 timeWindow; // Reduced from uint256
    }

    // Mappings
    mapping(bytes32 => Ability) public abilities;
    mapping(uint256 => StatusEffect[]) public statusEffects;
    mapping(uint256 => mapping(Element => uint40)) public lastElementCast; // Reduced timestamp from uint256
    mapping(bytes32 => ComboBonus) public comboBonuses;
    mapping(Element => mapping(Element => uint16)) public elementalEffectiveness; // Reduced from uint256 since it's percentage based

    event AbilityCreated(bytes32 indexed id, string name, AbilityType abilityType, Element element);
    event AbilityUsed(bytes32 indexed abilityId, uint256 indexed userId, uint256 indexed targetId);
    event StatusEffectApplied(uint256 indexed targetId, bytes32 indexed abilityId, uint32 duration);
    event ComboAchieved(bytes32 indexed comboId, uint256 indexed userId, uint32 bonusMultiplier);
    event ElementalResonance(uint256 indexed userId, Element element, uint32 bonus);

    constructor(address initialOwner) Ownable() {
        _transferOwnership(initialOwner);
        setupElementalEffectiveness();
    }

    /// @notice Setup base elemental effectiveness values
    function setupElementalEffectiveness() internal {
        // Fire is strong against Earth, weak against Water
        elementalEffectiveness[Element.FIRE][Element.EARTH] = 150; // 1.5x
        elementalEffectiveness[Element.FIRE][Element.WATER] = 50; // 0.5x

        // Water is strong against Fire, weak against Air
        elementalEffectiveness[Element.WATER][Element.FIRE] = 150;
        elementalEffectiveness[Element.WATER][Element.AIR] = 50;

        // Earth is strong against Air, weak against Fire
        elementalEffectiveness[Element.EARTH][Element.AIR] = 150;
        elementalEffectiveness[Element.EARTH][Element.FIRE] = 50;

        // Air is strong against Water, weak against Earth
        elementalEffectiveness[Element.AIR][Element.WATER] = 150;
        elementalEffectiveness[Element.AIR][Element.EARTH] = 50;

        // Light and Dark are strong against each other
        elementalEffectiveness[Element.LIGHT][Element.DARK] = 150;
        elementalEffectiveness[Element.DARK][Element.LIGHT] = 150;
    }

    /// @notice Create a new ability
    function createAbility(
        string calldata name,
        AbilityType abilityType,
        Element element,
        uint32 power,
        uint32 duration,
        uint32 cooldown,
        bool isAOE,
        bool requiresCharge,
        string[] calldata requirements
    ) external onlyOwner returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(name, abilityType, element, block.timestamp));

        abilities[id] = Ability({
            name: name,
            abilityType: abilityType,
            element: element,
            power: power,
            duration: duration,
            cooldown: cooldown,
            isAOE: isAOE,
            requiresCharge: requiresCharge,
            requirements: requirements,
            active: true
        });

        emit AbilityCreated(id, name, abilityType, element);
        return id;
    }

    /// @notice Create a combo bonus
    function createComboBonus(Element[] calldata elements, uint32 bonusMultiplier, uint32 timeWindow)
        external
        onlyOwner
        returns (bytes32)
    {
        if (elements.length < 2) revert ComboTooShort();

        bytes32 id = keccak256(abi.encodePacked(elements, bonusMultiplier, block.timestamp));

        comboBonuses[id] = ComboBonus({ elements: elements, bonusMultiplier: bonusMultiplier, timeWindow: timeWindow });

        return id;
    }

    /// @notice Use an ability
    function useAbility(bytes32 abilityId, uint256 userId, uint256 targetId) external returns (uint256) {
        Ability storage ability = abilities[abilityId];
        if (!ability.active) revert AbilityNotActive();

        uint40 lastCast = lastElementCast[userId][ability.element];
        if (block.timestamp < lastCast + ability.cooldown) revert AbilityOnCooldown();

        // Update last cast time
        lastElementCast[userId][ability.element] = uint40(block.timestamp);

        // Calculate base effect
        uint256 effectPower = calculateAbilityEffect(ability, userId, targetId);

        // Apply status effects if applicable
        if (ability.duration > 0) {
            applyStatusEffect(targetId, abilityId, ability.duration, uint32(effectPower));
        }

        emit AbilityUsed(abilityId, userId, targetId);
        return effectPower;
    }

    /// @notice Calculate ability effect considering elements and status
    function calculateAbilityEffect(Ability storage ability, uint256 userId, uint256 targetId)
        internal
        view
        returns (uint256)
    {
        uint256 basePower = ability.power;

        // Apply elemental effectiveness
        Element targetElement = getUserElement(targetId);
        uint16 elementalMod = elementalEffectiveness[ability.element][targetElement];
        if (elementalMod == 0) elementalMod = 100; // Default to 1x if not set

        uint256 effectPower;
        unchecked {
            effectPower = (basePower * elementalMod) / 100;
        }

        // Apply active status effects
        StatusEffect[] storage effects = statusEffects[userId];
        uint256 len = effects.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (effects[i].isActive && block.timestamp < effects[i].startTime + effects[i].duration) {
                    // Modify effect power based on status
                    effectPower = modifyPowerByStatus(effectPower, effects[i]);
                }
            }
        }

        return effectPower;
    }

    /// @notice Apply a status effect to a target
    function applyStatusEffect(uint256 targetId, bytes32 abilityId, uint32 duration, uint32 power) internal {
        StatusEffect[] storage effects = statusEffects[targetId];

        // Remove expired effects
        uint256 len = effects.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (block.timestamp >= effects[i].startTime + effects[i].duration) {
                    effects[i].isActive = false;
                }
            }
        }

        // Add new effect
        effects.push(
            StatusEffect({
                abilityId: abilityId,
                startTime: uint40(block.timestamp),
                duration: duration,
                power: power,
                isActive: true
            })
        );

        emit StatusEffectApplied(targetId, abilityId, duration);
    }

    /// @notice Modify power based on status effect
    function modifyPowerByStatus(uint256 power, StatusEffect memory effect) internal view returns (uint256) {
        Ability storage ability = abilities[effect.abilityId];

        unchecked {
            if (ability.abilityType == AbilityType.BUFF) {
                return power * (100 + effect.power) / 100;
            } else if (ability.abilityType == AbilityType.DEBUFF) {
                return power * (100 - effect.power) / 100;
            }
        }

        return power;
    }

    /// @notice Check for and process combos
    function checkCombo(uint256 userId, Element[] calldata elementSequence) external returns (uint256) {
        bytes32[] memory activeComboIds = getActiveComboIds();

        uint256 len = activeComboIds.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                ComboBonus storage combo = comboBonuses[activeComboIds[i]];

                if (isComboAchieved(combo, elementSequence)) {
                    emit ComboAchieved(activeComboIds[i], userId, combo.bonusMultiplier);
                    return combo.bonusMultiplier;
                }
            }
        }

        return 100; // Default 1x multiplier if no combo achieved
    }

    /// @notice Check if a combo has been achieved
    function isComboAchieved(ComboBonus storage combo, Element[] calldata elementSequence)
        internal
        view
        returns (bool)
    {
        if (elementSequence.length != combo.elements.length) return false;

        uint256 len = combo.elements.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (elementSequence[i] != combo.elements[i]) return false;
            }
        }

        return true;
    }

    /// @notice Get active status effects for a target
    function getActiveEffects(uint256 targetId)
        external
        view
        returns (
            bytes32[] memory abilityIds,
            uint32[] memory durations,
            uint32[] memory powers,
            uint32[] memory remainingTimes
        )
    {
        StatusEffect[] storage effects = statusEffects[targetId];
        uint256 activeCount;

        // Count active effects
        uint256 len = effects.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (effects[i].isActive && block.timestamp < effects[i].startTime + effects[i].duration) {
                    ++activeCount;
                }
            }
        }

        // Initialize arrays
        abilityIds = new bytes32[](activeCount);
        durations = new uint32[](activeCount);
        powers = new uint32[](activeCount);
        remainingTimes = new uint32[](activeCount);

        // Fill arrays
        uint256 index;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (effects[i].isActive && block.timestamp < effects[i].startTime + effects[i].duration) {
                    abilityIds[index] = effects[i].abilityId;
                    durations[index] = effects[i].duration;
                    powers[index] = effects[i].power;
                    remainingTimes[index] = uint32(effects[i].startTime + effects[i].duration - block.timestamp);
                    ++index;
                }
            }
        }

        return (abilityIds, durations, powers, remainingTimes);
    }

    // Placeholder - implement based on your character/monster system
    function getUserElement(uint256 /* _userId */ ) internal pure returns (Element) {
        return Element.NEUTRAL;
    }

    // Placeholder - implement based on your combo system
    function getActiveComboIds() internal pure returns (bytes32[] memory) {
        return new bytes32[](0);
    }
}
