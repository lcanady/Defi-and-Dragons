# Pet & Mount System Tutorial

## Overview
The Pet & Mount System provides companions and transportation options for characters, offering various bonuses and gameplay enhancements. Pets provide passive bonuses like increased drop rates and yield boosts, while mounts offer travel benefits and staking advantages.

## Core Components

### Pet Contract
- Manages pet creation and minting
- Handles pet bonding and unbonding
- Controls pet benefits
- Tracks pet ownership

### Mount Contract
- Manages mount creation and minting
- Handles mount riding
- Controls mount benefits
- Tracks mount ownership

## Key Features

### Pet Creation
```solidity
function createPet(
    string memory name,
    string memory description,
    Rarity rarity,
    uint256 yieldBoost,
    uint256 dropRateBoost,
    uint256 requiredLevel
) external returns (uint256)
```

Creates new pets with:
- Unique name and description
- Rarity level
- Yield and drop rate boosts
- Level requirements

### Mount Creation
```solidity
function createMount(
    string memory name,
    string memory description,
    MountType mountType,
    uint256 questFeeReduction,
    uint256 travelTimeReduction,
    uint256 stakingBoost,
    uint256 lpLockReduction,
    uint256 requiredLevel
) external returns (uint256)
```

Creates new mounts with:
- Unique name and description
- Mount type
- Travel and staking benefits
- Level requirements

## Integration Points

### Character System
- Pet/mount ownership
- Level requirements
- Bonus calculations

### AMM System
- LP staking benefits
- Fee reductions
- Lock period modifiers

### Quest System
- Travel time reductions
- Quest fee reductions
- Drop rate bonuses

## Usage Examples

### Creating and Bonding Pets
```solidity
// Create a new pet
uint256 petId = pet.createPet(
    "Dragon Hatchling",
    "A baby dragon companion",
    Pet.Rarity.LEGENDARY,
    5000, // 50% yield boost
    3000, // 30% drop rate boost
    10    // Level 10 required
);

// Mint pet to character
pet.mintPet(characterId, petId);
```

### Creating and Using Mounts
```solidity
// Create a new mount
uint256 mountId = mount.createMount(
    "Swift Griffin",
    "A majestic flying mount",
    Mount.MountType.GRIFFIN,
    2000, // 20% quest fee reduction
    12 hours, // Travel time reduction
    3000, // 30% staking boost
    1000, // 10% LP lock reduction
    15    // Level 15 required
);

// Mint mount to character
mount.mintMount(characterId, mountId);
```

### Checking Benefits
```solidity
// Check pet benefits
(uint256 yieldBoost, uint256 dropBoost) = pet.getPetBenefits(characterId);

// Check mount benefits
(
    uint256 questFeeReduction,
    uint256 travelReduction,
    uint256 stakingBoost,
    uint256 lockReduction
) = mount.getMountBenefits(characterId);
```

## Best Practices

1. **Pet Management**
   - Balance pet bonuses
   - Consider rarity tiers
   - Handle pet transfers

2. **Mount Management**
   - Balance mount benefits
   - Consider mount types
   - Handle mount transfers

3. **Integration**
   - Validate level requirements
   - Handle ownership changes
   - Maintain bonus consistency

4. **Gas Optimization**
   - Batch pet/mount operations
   - Optimize benefit calculations
   - Cache frequently used values

## Common Pitfalls

1. **Ownership Management**
   - Not checking ownership
   - Incorrect transfers
   - Missing unbinding

2. **Benefit Calculation**
   - Incorrect stacking
   - Missing modifiers
   - Overflow issues

3. **Integration Issues**
   - Level requirement bugs
   - Missing state updates
   - Incorrect permissions

## Security Considerations

1. **Access Control**
   - Creation permissions
   - Transfer restrictions
   - Benefit modifications

2. **State Protection**
   - Ownership validation
   - Level requirements
   - Benefit limits

3. **Asset Safety**
   - Safe transfers
   - State consistency
   - Emergency functions

## Advanced Features

### Pet Evolution
- Pet leveling system
- Evolution requirements
- Enhanced benefits

### Mount Training
- Mount skill system
- Training requirements
- Special abilities

### Companion Synergies
- Pet-mount combinations
- Enhanced bonuses
- Special effects

## Testing Guidelines

1. **Unit Tests**
   - Test creation functions
   - Verify benefit calculations
   - Check ownership management

2. **Integration Tests**
   - Test character interactions
   - Verify bonus applications
   - Check system integrations

3. **Edge Cases**
   - Test transfer edge cases
   - Verify level requirements
   - Check benefit limits

## Performance Optimization

1. **Gas Usage**
   - Optimize transfers
   - Batch operations
   - Minimize state changes

2. **Memory Management**
   - Efficient struct usage
   - Optimize arrays
   - Minimize storage

3. **Computation**
   - Cache calculations
   - Use efficient math
   - Optimize loops

## Monitoring and Maintenance

1. **System Health**
   - Monitor pet/mount creation
   - Track benefit usage
   - Check ownership patterns

2. **Balance**
   - Monitor benefit impact
   - Track usage patterns
   - Adjust parameters

3. **Integration**
   - Monitor system interactions
   - Track errors
   - Update integrations

## Future Enhancements

1. **Pet Features**
   - Breeding system
   - Pet battles
   - Pet quests

2. **Mount Features**
   - Mount racing
   - Mount customization
   - Mount abilities

3. **System Expansion**
   - New pet types
   - New mount types
   - Enhanced benefits 