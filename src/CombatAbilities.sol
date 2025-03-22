// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";

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
        DAMAGE,          // Direct damage
        DOT,            // Damage over time
        BUFF,           // Positive status effect
        DEBUFF,         // Negative status effect
        HEAL,           // Healing effect
        SHIELD,         // Damage reduction
        SPECIAL         // Special effects
    }

    struct Ability {
        string name;
        AbilityType abilityType;
        Element element;
        uint256 power;          // Base power/effectiveness
        uint256 duration;       // Duration in seconds (if applicable)
        uint256 cooldown;       // Cooldown period in seconds
        bool isAOE;            // Whether affects multiple targets
        bool requiresCharge;    // Whether needs charging before use
        string[] requirements;  // Required items/conditions
        bool active;
    }

    struct StatusEffect {
        bytes32 abilityId;
        uint256 startTime;
        uint256 duration;
        uint256 power;
        bool isActive;
    }

    struct ComboBonus {
        Element[] elements;     // Required elements in sequence
        uint256 bonusMultiplier;// Reward multiplier (100 = 1x)
        uint256 timeWindow;     // Time window to complete combo
    }

    // Ability ID => Ability details
    mapping(bytes32 => Ability) public abilities;
    
    // Target ID => Status effects
    mapping(uint256 => StatusEffect[]) public statusEffects;
    
    // Character/Monster ID => Element => Last cast timestamp
    mapping(uint256 => mapping(Element => uint256)) public lastElementCast;
    
    // Combo ID => Combo details
    mapping(bytes32 => ComboBonus) public comboBonuses;
    
    // Element => Element => Effectiveness multiplier (100 = 1x)
    mapping(Element => mapping(Element => uint256)) public elementalEffectiveness;

    event AbilityCreated(bytes32 indexed id, string name, AbilityType abilityType, Element element);
    event AbilityUsed(bytes32 indexed abilityId, uint256 indexed userId, uint256 indexed targetId);
    event StatusEffectApplied(uint256 indexed targetId, bytes32 indexed abilityId, uint256 duration);
    event ComboAchieved(bytes32 indexed comboId, uint256 indexed userId, uint256 bonusMultiplier);
    event ElementalResonance(uint256 indexed userId, Element element, uint256 bonus);

    constructor() Ownable(msg.sender) {
        // Initialize elemental effectiveness
        setupElementalEffectiveness();
    }

    /// @notice Setup base elemental effectiveness values
    function setupElementalEffectiveness() internal {
        // Fire is strong against Earth, weak against Water
        elementalEffectiveness[Element.FIRE][Element.EARTH] = 150;  // 1.5x
        elementalEffectiveness[Element.FIRE][Element.WATER] = 50;   // 0.5x
        
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
        uint256 power,
        uint256 duration,
        uint256 cooldown,
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
    function createComboBonus(
        Element[] calldata elements,
        uint256 bonusMultiplier,
        uint256 timeWindow
    ) external onlyOwner returns (bytes32) {
        require(elements.length >= 2, "Combo must have at least 2 elements");
        
        bytes32 id = keccak256(abi.encodePacked(elements, bonusMultiplier, block.timestamp));
        
        comboBonuses[id] = ComboBonus({
            elements: elements,
            bonusMultiplier: bonusMultiplier,
            timeWindow: timeWindow
        });

        return id;
    }

    /// @notice Use an ability
    function useAbility(
        bytes32 abilityId,
        uint256 userId,
        uint256 targetId
    ) external returns (uint256) {
        Ability storage ability = abilities[abilityId];
        require(ability.active, "Ability not active");
        
        // Check cooldown
        require(
            block.timestamp >= lastElementCast[userId][ability.element] + ability.cooldown,
            "Ability on cooldown"
        );

        // Update last cast time
        lastElementCast[userId][ability.element] = block.timestamp;

        // Calculate base effect
        uint256 effectPower = calculateAbilityEffect(ability, userId, targetId);

        // Apply status effects if applicable
        if (ability.duration > 0) {
            applyStatusEffect(targetId, abilityId, ability.duration, effectPower);
        }

        emit AbilityUsed(abilityId, userId, targetId);
        return effectPower;
    }

    /// @notice Calculate ability effect considering elements and status
    function calculateAbilityEffect(
        Ability storage ability,
        uint256 userId,
        uint256 targetId
    ) internal view returns (uint256) {
        uint256 basePower = ability.power;
        
        // Apply elemental effectiveness
        Element targetElement = getUserElement(targetId); // You'll need to implement this
        uint256 elementalMod = elementalEffectiveness[ability.element][targetElement];
        if (elementalMod == 0) elementalMod = 100; // Default to 1x if not set
        
        uint256 effectPower = (basePower * elementalMod) / 100;
        
        // Apply active status effects
        StatusEffect[] storage effects = statusEffects[userId];
        for (uint256 i = 0; i < effects.length; i++) {
            if (effects[i].isActive && 
                block.timestamp < effects[i].startTime + effects[i].duration) {
                // Modify effect power based on status
                effectPower = modifyPowerByStatus(effectPower, effects[i]);
            }
        }
        
        return effectPower;
    }

    /// @notice Apply a status effect to a target
    function applyStatusEffect(
        uint256 targetId,
        bytes32 abilityId,
        uint256 duration,
        uint256 power
    ) internal {
        StatusEffect[] storage effects = statusEffects[targetId];
        
        // Remove expired effects
        for (uint256 i = 0; i < effects.length; i++) {
            if (block.timestamp >= effects[i].startTime + effects[i].duration) {
                effects[i].isActive = false;
            }
        }
        
        // Add new effect
        effects.push(StatusEffect({
            abilityId: abilityId,
            startTime: block.timestamp,
            duration: duration,
            power: power,
            isActive: true
        }));

        emit StatusEffectApplied(targetId, abilityId, duration);
    }

    /// @notice Modify power based on status effect
    function modifyPowerByStatus(
        uint256 power,
        StatusEffect memory effect
    ) internal view returns (uint256) {
        Ability storage ability = abilities[effect.abilityId];
        
        if (ability.abilityType == AbilityType.BUFF) {
            return power * (100 + effect.power) / 100;
        } else if (ability.abilityType == AbilityType.DEBUFF) {
            return power * (100 - effect.power) / 100;
        }
        
        return power;
    }

    /// @notice Check for and process combos
    function checkCombo(
        uint256 userId,
        Element[] calldata elementSequence
    ) external returns (uint256) {
        bytes32[] memory activeComboIds = getActiveComboIds(); // You'll need to implement this
        
        for (uint256 i = 0; i < activeComboIds.length; i++) {
            ComboBonus storage combo = comboBonuses[activeComboIds[i]];
            
            if (isComboAchieved(combo, elementSequence)) {
                emit ComboAchieved(activeComboIds[i], userId, combo.bonusMultiplier);
                return combo.bonusMultiplier;
            }
        }
        
        return 100; // Default 1x multiplier if no combo achieved
    }

    /// @notice Check if a combo has been achieved
    function isComboAchieved(
        ComboBonus storage combo,
        Element[] calldata elementSequence
    ) internal view returns (bool) {
        if (elementSequence.length != combo.elements.length) return false;
        
        for (uint256 i = 0; i < combo.elements.length; i++) {
            if (elementSequence[i] != combo.elements[i]) return false;
        }
        
        return true;
    }

    /// @notice Get active status effects for a target
    function getActiveEffects(uint256 targetId)
        external
        view
        returns (
            bytes32[] memory abilityIds,
            uint256[] memory durations,
            uint256[] memory powers,
            uint256[] memory remainingTimes
        )
    {
        StatusEffect[] storage effects = statusEffects[targetId];
        uint256 activeCount = 0;
        
        // Count active effects
        for (uint256 i = 0; i < effects.length; i++) {
            if (effects[i].isActive && 
                block.timestamp < effects[i].startTime + effects[i].duration) {
                activeCount++;
            }
        }
        
        // Initialize arrays
        abilityIds = new bytes32[](activeCount);
        durations = new uint256[](activeCount);
        powers = new uint256[](activeCount);
        remainingTimes = new uint256[](activeCount);
        
        // Fill arrays
        uint256 index = 0;
        for (uint256 i = 0; i < effects.length; i++) {
            if (effects[i].isActive && 
                block.timestamp < effects[i].startTime + effects[i].duration) {
                abilityIds[index] = effects[i].abilityId;
                durations[index] = effects[i].duration;
                powers[index] = effects[i].power;
                remainingTimes[index] = effects[i].startTime + 
                    effects[i].duration - block.timestamp;
                index++;
            }
        }
        
        return (abilityIds, durations, powers, remainingTimes);
    }

    // Placeholder - implement based on your character/monster system
    function getUserElement(uint256 /* _userId */) internal pure returns (Element) {
        return Element.NEUTRAL;
    }

    // Placeholder - implement based on your combo system
    function getActiveComboIds() internal pure returns (bytes32[] memory) {
        return new bytes32[](0);
    }
} 