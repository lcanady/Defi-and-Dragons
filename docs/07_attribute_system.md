# Attribute System Documentation

## Overview
The Attribute System is a sophisticated framework for managing character statistics, modifiers, and their complex interactions within the game. It implements a comprehensive calculation engine that handles attribute stacking, temporary buffs, conditional modifiers, and synergistic effects from various sources including equipment, pets, mounts, abilities, and environmental factors. The system features dynamic scaling based on character progression, equipment quality, and strategic choices.

## Core Components

### Contract Architecture
The system is built on a modular architecture with the following key contracts:

```solidity
interface IAttribute {
    enum AttributeType {
        STRENGTH,
        AGILITY,
        MAGIC,
        VITALITY,
        WISDOM,
        LUCK
    }
    
    enum ModifierType {
        FLAT,
        PERCENTAGE,
        MULTIPLICATIVE
    }
    
    struct AttributeModifier {
        AttributeType attributeType;
        ModifierType modifierType;
        uint256 value;
        uint256 duration;
        bool isStackable;
        uint256 maxStacks;
        bytes32 source;
    }
    
    struct Stats {
        uint256 strength;
        uint256 agility;
        uint256 magic;
        uint256 vitality;
        uint256 wisdom;
        uint256 luck;
    }
    
    struct StatBonuses {
        uint256 flatBonus;
        uint256 percentageBonus;
        uint256 multiplicativeBonus;
    }
}

interface IAttributeCalculator {
    struct CalculationContext {
        uint256 characterId;
        uint256 timestamp;
        bool includeTemporary;
        bool includeEquipment;
        bool includePets;
        bool includeMounts;
        bool includeAbilities;
    }
}
```

### AttributeCalculator Contract Implementation
```solidity
contract ArcaneAttributeCalculator is IAttributeCalculator, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    // Constants for calculation precision
    uint256 constant PERCENTAGE_BASE = 10000;  // 100% = 10000
    uint256 constant MAX_MULTIPLIER = 50000;   // 500% maximum multiplier
    uint256 constant MIN_MULTIPLIER = 2500;    // 25% minimum multiplier
    
    // Mapping for active modifiers
    mapping(uint256 => mapping(AttributeType => AttributeModifier[])) 
        public activeModifiers;
    
    // Mapping for modifier sources
    mapping(uint256 => EnumerableSet.Bytes32Set) private modifierSources;
    
    event ModifierApplied(
        uint256 indexed characterId,
        AttributeType indexed attributeType,
        ModifierType modifierType,
        uint256 value,
        uint256 duration,
        bytes32 source
    );
    
    event ModifierExpired(
        uint256 indexed characterId,
        AttributeType indexed attributeType,
        bytes32 source
    );
    
    function calculateTotalAttributes(
        uint256 characterId,
        CalculationContext memory context
    ) external view returns (Stats memory totalStats) {
        // Get base stats
        Stats memory baseStats = ICharacter(characterContract).getBaseStats(characterId);
        
        // Apply level scaling
        totalStats = applyLevelScaling(baseStats, characterId);
        
        // Apply equipment bonuses if requested
        if (context.includeEquipment) {
            totalStats = applyEquipmentBonuses(totalStats, characterId);
        }
        
        // Apply pet bonuses if requested
        if (context.includePets) {
            totalStats = applyPetBonuses(totalStats, characterId);
        }
        
        // Apply mount bonuses if requested
        if (context.includeMounts) {
            totalStats = applyMountBonuses(totalStats, characterId);
        }
        
        // Apply ability effects if requested
        if (context.includeAbilities) {
            totalStats = applyAbilityEffects(totalStats, characterId);
        }
        
        // Apply temporary modifiers if requested
        if (context.includeTemporary) {
            totalStats = applyTemporaryModifiers(
                totalStats,
                characterId,
                context.timestamp
            );
        }
        
        // Apply final caps and limits
        totalStats = applyAttributeCaps(totalStats);
        
        return totalStats;
    }
    
    function applyModifier(
        uint256 characterId,
        AttributeModifier memory modifier
    ) external returns (bool) {
        require(
            isValidModifier(modifier),
            "Invalid modifier parameters"
        );
        
        // Check if source already exists
        require(
            !modifierSources[characterId].contains(modifier.source) ||
            modifier.isStackable,
            "Non-stackable modifier source already exists"
        );
        
        // Add modifier to active modifiers
        activeModifiers[characterId][modifier.attributeType].push(modifier);
        modifierSources[characterId].add(modifier.source);
        
        emit ModifierApplied(
            characterId,
            modifier.attributeType,
            modifier.modifierType,
            modifier.value,
            modifier.duration,
            modifier.source
        );
        
        return true;
    }
    
    function calculateAttributeMultiplier(
        uint256 characterId,
        AttributeType attributeType
    ) public view returns (uint256 multiplier) {
        StatBonuses memory bonuses = getAttributeBonuses(
            characterId,
            attributeType
        );
        
        // Start with base 100%
        multiplier = PERCENTAGE_BASE;
        
        // Add flat bonuses
        multiplier = multiplier.add(bonuses.flatBonus);
        
        // Apply percentage bonuses
        multiplier = multiplier.mul(
            PERCENTAGE_BASE.add(bonuses.percentageBonus)
        ).div(PERCENTAGE_BASE);
        
        // Apply multiplicative bonuses
        multiplier = multiplier.mul(
            PERCENTAGE_BASE.add(bonuses.multiplicativeBonus)
        ).div(PERCENTAGE_BASE);
        
        // Apply caps
        multiplier = multiplier.clamp(MIN_MULTIPLIER, MAX_MULTIPLIER);
        
        return multiplier;
    }
}
```

### AttributeEffects Contract Implementation
```solidity
contract ArcaneAttributeEffects {
    using SafeMath for uint256;
    
    struct AttributeEffect {
        AttributeType attributeType;
        uint256 value;
        uint256 duration;
        uint256 startTime;
        uint256 endTime;
        bytes32 source;
    }
    
    mapping(uint256 => mapping(AttributeType => AttributeEffect[])) 
        public activeEffects;
    
    event EffectApplied(
        uint256 indexed characterId,
        AttributeType indexed attributeType,
        uint256 value,
        uint256 duration,
        bytes32 source
    );
    
    function applyEffect(
        uint256 characterId,
        AttributeEffect memory effect
    ) external returns (bool) {
        require(
            effect.duration > 0 && effect.value > 0,
            "Invalid effect parameters"
        );
        
        effect.startTime = block.timestamp;
        effect.endTime = block.timestamp.add(effect.duration);
        
        activeEffects[characterId][effect.attributeType].push(effect);
        
        emit EffectApplied(
            characterId,
            effect.attributeType,
            effect.value,
            effect.duration,
            effect.source
        );
        
        return true;
    }
    
    function processEffects(uint256 characterId) external {
        for (uint i = 0; i < uint(AttributeType.LUCK); i++) {
            AttributeType attributeType = AttributeType(i);
            AttributeEffect[] storage effects = activeEffects[characterId][attributeType];
            
            for (uint j = effects.length; j > 0; j--) {
                if (block.timestamp > effects[j-1].endTime) {
                    // Remove expired effect
                    effects[j-1] = effects[effects.length - 1];
                    effects.pop();
                }
            }
        }
    }
}
```

## Integration Examples

### Character System Integration
```solidity
contract ArcaneCharacter {
    IAttributeCalculator public attributeCalculator;
    
    function getEffectiveStats(
        uint256 characterId
    ) external view returns (Stats memory) {
        CalculationContext memory context = CalculationContext({
            characterId: characterId,
            timestamp: block.timestamp,
            includeTemporary: true,
            includeEquipment: true,
            includePets: true,
            includeMounts: true,
            includeAbilities: true
        });
        
        return attributeCalculator.calculateTotalAttributes(characterId, context);
    }
    
    function getCombatStats(
        uint256 characterId
    ) external view returns (Stats memory) {
        CalculationContext memory context = CalculationContext({
            characterId: characterId,
            timestamp: block.timestamp,
            includeTemporary: true,
            includeEquipment: true,
            includePets: false,
            includeMounts: false,
            includeAbilities: true
        });
        
        return attributeCalculator.calculateTotalAttributes(characterId, context);
    }
}
```

### Equipment System Integration
```solidity
contract ArcaneEquipment {
    struct AttributeBonus {
        AttributeType attributeType;
        ModifierType modifierType;
        uint256 value;
    }
    
    mapping(uint256 => AttributeBonus[]) public equipmentBonuses;
    
    function getEquipmentBonuses(
        uint256 characterId
    ) external view returns (
        uint256[] memory flatBonuses,
        uint256[] memory percentageBonuses
    ) {
        uint256[] memory equipped = getEquippedItems(characterId);
        
        flatBonuses = new uint256[](uint(AttributeType.LUCK));
        percentageBonuses = new uint256[](uint(AttributeType.LUCK));
        
        for (uint256 i = 0; i < equipped.length; i++) {
            AttributeBonus[] memory bonuses = equipmentBonuses[equipped[i]];
            
            for (uint256 j = 0; j < bonuses.length; j++) {
                if (bonuses[j].modifierType == ModifierType.FLAT) {
                    flatBonuses[uint(bonuses[j].attributeType)] = 
                        flatBonuses[uint(bonuses[j].attributeType)].add(
                            bonuses[j].value
                        );
                } else if (bonuses[j].modifierType == ModifierType.PERCENTAGE) {
                    percentageBonuses[uint(bonuses[j].attributeType)] = 
                        percentageBonuses[uint(bonuses[j].attributeType)].add(
                            bonuses[j].value
                        );
                }
            }
        }
    }
}
```

## Advanced Features

### Synergy System
```solidity
contract AttributeSynergy {
    struct SynergyEffect {
        AttributeType[] attributeTypes;
        uint256[] thresholds;
        uint256[] bonusValues;
    }
    
    mapping(bytes32 => SynergyEffect) public synergyEffects;
    
    function calculateSynergyBonuses(
        uint256 characterId,
        Stats memory baseStats
    ) external view returns (Stats memory) {
        Stats memory bonusStats;
        
        // Check each synergy effect
        for (bytes32 synergyId : activeSynergies) {
            SynergyEffect memory effect = synergyEffects[synergyId];
            
            // Check if thresholds are met
            bool allThresholdsMet = true;
            for (uint i = 0; i < effect.attributeTypes.length; i++) {
                uint256 attributeValue = getAttribute(
                    baseStats,
                    effect.attributeTypes[i]
                );
                
                if (attributeValue < effect.thresholds[i]) {
                    allThresholdsMet = false;
                    break;
                }
            }
            
            // Apply bonuses if all thresholds are met
            if (allThresholdsMet) {
                for (uint i = 0; i < effect.attributeTypes.length; i++) {
                    addAttributeBonus(
                        bonusStats,
                        effect.attributeTypes[i],
                        effect.bonusValues[i]
                    );
                }
            }
        }
        
        return bonusStats;
    }
}
```

## Gas Optimization Examples

### Efficient Storage Layout
```solidity
contract OptimizedAttributes {
    // Pack common variables into single storage slots
    struct PackedStats {
        uint32 strength;    // Up to 4.29B
        uint32 agility;     // Up to 4.29B
        uint32 magic;       // Up to 4.29B
        uint32 vitality;    // Up to 4.29B
        uint32 wisdom;      // Up to 4.29B
        uint32 luck;        // Up to 4.29B
    }
    
    // Use bit flags for status effects
    uint256 constant BUFF_STRENGTH = 1 << 0;
    uint256 constant BUFF_AGILITY = 1 << 1;
    uint256 constant BUFF_MAGIC = 1 << 2;
    uint256 constant DEBUFF_STRENGTH = 1 << 3;
    uint256 constant DEBUFF_AGILITY = 1 << 4;
    uint256 constant DEBUFF_MAGIC = 1 << 5;
    
    mapping(uint256 => uint256) public attributeFlags;
}
```

## Analytics and Monitoring

### System Analytics
```solidity
contract AttributeAnalytics {
    struct AttributeStats {
        uint256 averageValue;
        uint256 maxValue;
        uint256 minValue;
        uint256 totalModifiers;
        uint256 activeEffects;
        mapping(bytes32 => uint256) sourceDistribution;
    }
    
    mapping(AttributeType => AttributeStats) public attributeStats;
    
    function updateAttributeStats(
        AttributeType attributeType,
        uint256 value,
        bytes32 source
    ) external {
        AttributeStats storage stats = attributeStats[attributeType];
        
        // Update statistics
        stats.averageValue = (
            stats.averageValue.mul(stats.totalModifiers).add(value)
        ).div(stats.totalModifiers.add(1));
        
        stats.maxValue = Math.max(stats.maxValue, value);
        stats.minValue = stats.minValue == 0 ? 
            value : Math.min(stats.minValue, value);
        
        stats.totalModifiers = stats.totalModifiers.add(1);
        stats.sourceDistribution[source] = stats.sourceDistribution[source].add(1);
        
        emit StatsUpdated(attributeType, stats);
    }
}
```

## Future Enhancements
1. Dynamic Attribute System
   - Context-sensitive attributes
   - Environmental effects
   - Time-based variations

2. Advanced Synergy System
   - Cross-character synergies
   - Guild-wide attribute bonuses
   - Dynamic synergy discovery

3. Attribute Specialization
   - Specialized paths
   - Unique combinations
   - Advanced scaling

4. Social Attributes
   - Team bonuses
   - Guild attributes
   - Cooperative effects

5. Environmental System
   - Weather effects
   - Location bonuses
   - Event modifiers 