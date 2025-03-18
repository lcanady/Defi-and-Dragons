# Equipment System Documentation

## Overview
The Equipment System is a sophisticated ERC1155-based implementation that manages in-game items, providing dynamic stat bonuses and special abilities to characters. This system integrates seamlessly with character progression, crafting, and marketplace mechanics while ensuring gas-efficient operations and robust security measures.

## Core Components

### Equipment Contract Architecture
The Equipment contract is built on the following principles:
- ERC1155 compliance for efficient multi-token management
- Modular design for easy upgrades and maintenance
- Gas-optimized storage patterns
- Comprehensive event emission for off-chain tracking
- Role-based access control for administrative functions

### Equipment Types and Categories
```solidity
enum EquipmentType {
    WEAPON,
    ARMOR,
    ACCESSORY,
    CONSUMABLE
}

enum EquipmentRarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
}
```

### Public Functions

#### Admin Functions
```solidity
// Set the character contract address
function setCharacterContract(address characterContract) external onlyOwner {
    require(characterContract != address(0), "Invalid address");
    _characterContract = characterContract;
    emit CharacterContractUpdated(characterContract);
}

// Create new equipment with extended properties
function createEquipment(
    string memory name,
    string memory description,
    uint8 strengthBonus,
    uint8 agilityBonus,
    uint8 magicBonus,
    EquipmentType equipType,
    EquipmentRarity rarity,
    uint256[] memory specialAbilityIds
) external onlyOwner returns (uint256 tokenId) {
    require(bytes(name).length > 0, "Name required");
    require(bytes(description).length > 0, "Description required");
    
    tokenId = _nextTokenId++;
    
    equipmentStats[tokenId] = Types.EquipmentStats({
        strengthBonus: strengthBonus,
        agilityBonus: agilityBonus,
        magicBonus: magicBonus,
        isActive: true,
        equipType: equipType,
        rarity: rarity,
        name: name,
        description: description
    });

    _setupSpecialAbilities(tokenId, specialAbilityIds);
    
    emit EquipmentCreated(tokenId, name, equipType, rarity);
    return tokenId;
}

// Activate equipment
function activateEquipment(uint256 tokenId) external onlyOwner

// Deactivate equipment
function deactivateEquipment(uint256 tokenId) external onlyOwner

// Mint equipment tokens
function mint(
    address to, 
    uint256 id, 
    uint256 amount, 
    bytes memory data
) external
```

#### View Functions
```solidity
// Get equipment stats
function getEquipmentStats(uint256 tokenId) 
    external view returns (Types.EquipmentStats memory stats, bool exists)

// Get special ability by index
function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
    external view returns (Types.SpecialAbility memory)

// Get all special abilities
function getSpecialAbilities(uint256 equipmentId) 
    external view returns (Types.SpecialAbility[] memory)

// Check ability trigger condition
function checkTriggerCondition(
    uint256 characterId,
    uint256 equipmentId,
    uint256 abilityIndex,
    uint256 currentRound
) external view returns (bool)

// Calculate total equipment bonuses
function calculateEquipmentBonus(uint256 characterId)
    external view returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)

// Get token balance
function balanceOf(address account, uint256 id) 
    public view returns (uint256)

// Get token URI
function uri(uint256 tokenId) 
    public view returns (string memory)

// Check interface support
function supportsInterface(bytes4 interfaceId) 
    public view returns (bool)

// Get equipment stats mapping
function equipmentStats(uint256) 
    public view returns (Types.EquipmentStats memory)

// Get special abilities mapping
function specialAbilities(uint256, uint256) 
    public view returns (Types.SpecialAbility memory)

// Get ability cooldowns mapping
function abilityCooldowns(uint256, uint256, uint256) 
    public view returns (uint256)
```

#### Integration Functions
```solidity
// Update ability cooldown (only character contract)
function updateAbilityCooldown(
    uint256 characterId,
    uint256 equipmentId,
    uint256 abilityIndex,
    uint256 currentRound
) external onlyCharacterContract
```

### Equipment Stats Structure
```solidity
struct EquipmentStats {
    uint8 strengthBonus;
    uint8 agilityBonus;
    uint8 magicBonus;
    bool isActive;
    string name;
    string description;
}
```

### Special Ability Structure
```solidity
struct SpecialAbility {
    string name;
    uint256 triggerValue;
    uint256 effectValue;
    uint256 cooldown;
}
```

## Key Features

### Equipment Creation and Management
- Create equipment with unique stats and bonuses
- Activate/deactivate equipment
- Mint equipment tokens to players
- Track equipment ownership and transfers

### Equipment Stats and Bonuses
- Equipment provides attribute bonuses
- Stats can be queried and calculated
- Bonuses stack from multiple equipment pieces

### Special Abilities
- Equipment can have special abilities
- Abilities have cooldowns and triggers
- Effects can be activated under conditions

## Integration Points

### Character System
- Equipment provides stat bonuses to characters
- Characters can equip/unequip items via their wallet
- Equipment affects character performance and abilities

### Marketplace System
- Equipment tokens can be listed on the marketplace
- Players can buy/sell equipment using the marketplace contract
- Market prices determined by player-driven economy
- Supports both fixed price and auction listings

### Crafting System
- New equipment can be crafted using resources
- Crafting success rates affect equipment creation
- Crafted equipment enters circulation through crafting contract

## Usage Examples

### Creating Equipment
```solidity
// Create a new weapon
uint256 weaponId = equipment.createEquipment(
    "Flaming Sword",
    "A powerful sword imbued with fire",
    5, // strength bonus
    2, // agility bonus
    3  // magic bonus
);
```

### Managing Equipment State
```solidity
// Deactivate equipment
equipment.deactivateEquipment(weaponId);

// Activate equipment
equipment.activateEquipment(weaponId);
```

### Checking Equipment Stats
```solidity
// Get equipment stats
(Types.EquipmentStats memory stats, bool exists) = equipment.getEquipmentStats(weaponId);

// Calculate total bonuses
(uint8 strength, uint8 agility, uint8 magic) = equipment.calculateEquipmentBonus(characterId);
```

### Managing Special Abilities
```solidity
// Get special abilities
Types.SpecialAbility[] memory abilities = equipment.getSpecialAbilities(weaponId);

// Check trigger condition
bool canTrigger = equipment.checkTriggerCondition(
    characterId,
    weaponId,
    0, // ability index
    currentRound
);
```

## Best Practices

1. **Equipment Creation**
   - Use meaningful names and descriptions
   - Balance stat bonuses appropriately
   - Consider equipment tiers

2. **State Management**
   - Check equipment state before operations
   - Handle state changes atomically
   - Emit events for state changes

3. **Integration**
   - Validate equipment compatibility
   - Handle equipment transfers safely
   - Maintain proper access control

4. **Gas Optimization**
   - Batch equipment operations
   - Use efficient storage patterns
   - Minimize state changes

## Common Pitfalls

1. **State Validation**
   - Not checking equipment existence
   - Ignoring equipment state
   - Missing permission checks

2. **Balance Management**
   - Incorrect balance tracking
   - Missing balance checks
   - Improper transfer handling

3. **Integration Issues**
   - Incorrect bonus calculations
   - Missing event emissions
   - Improper error handling

## Security Considerations

1. **Access Control**
   - Restrict admin functions
   - Validate equipment ownership
   - Implement proper modifiers

2. **State Protection**
   - Prevent unauthorized changes
   - Protect against manipulation
   - Validate all inputs

3. **Asset Safety**
   - Secure transfer mechanisms
   - Handle edge cases safely
   - Implement emergency functions

## Testing Guidelines

1. **Unit Tests**
   - Test equipment creation
   - Verify state changes
   - Check balance management

2. **Integration Tests**
   - Test character interactions
   - Verify bonus calculations
   - Check system integrations

3. **Edge Cases**
   - Test boundary conditions
   - Verify error handling
   - Check permission systems

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
   - Monitor equipment creation
   - Track usage patterns
   - Check ownership patterns

2. **Balance**
   - Monitor equipment stats
   - Track market prices
   - Adjust parameters

3. **Integration**
   - Check systems
   - Track issues
   - Update logic

### Advanced Equipment Features

#### Quality System
Equipment quality affects stat bonuses and can be improved through crafting:

```solidity
struct QualityModifier {
    uint8 qualityLevel;      // 1-100
    uint8 bonusMultiplier;   // Percentage boost to base stats
    bool canBeUpgraded;      // Whether quality can be improved
}

function improveQuality(uint256 tokenId) external {
    require(_exists(tokenId), "Equipment does not exist");
    require(quality[tokenId].canBeUpgraded, "Cannot upgrade quality");
    require(quality[tokenId].qualityLevel < 100, "Max quality reached");
    
    // Quality improvement logic
    quality[tokenId].qualityLevel++;
    _recalculateStats(tokenId);
    
    emit QualityImproved(tokenId, quality[tokenId].qualityLevel);
}
```

#### Durability System
```solidity
struct DurabilityInfo {
    uint16 currentDurability;
    uint16 maxDurability;
    bool needsRepair;
}

function updateDurability(uint256 tokenId, uint16 damage) external {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized");
    DurabilityInfo storage durability = durabilityInfo[tokenId];
    
    if (damage >= durability.currentDurability) {
        durability.currentDurability = 0;
        durability.needsRepair = true;
    } else {
        durability.currentDurability -= damage;
    }
    
    emit DurabilityUpdated(tokenId, durability.currentDurability);
}
```

## Integration Examples

### Character System Integration
```solidity
// Example of equipping items with validation
function equipItem(uint256 characterId, uint256 equipmentId) external {
    require(ownerOf(characterId) == msg.sender, "Not character owner");
    require(balanceOf(msg.sender, equipmentId) > 0, "Don't own equipment");
    require(!isEquipped[equipmentId], "Already equipped");
    
    // Validate equipment requirements
    require(_meetsRequirements(characterId, equipmentId), "Requirements not met");
    
    // Update character stats
    (uint8 str, uint8 agi, uint8 mag) = equipment.getEquipmentStats(equipmentId);
    characters[characterId].strength += str;
    characters[characterId].agility += agi;
    characters[characterId].magic += mag;
    
    isEquipped[equipmentId] = true;
    characterEquipment[characterId].push(equipmentId);
    
    emit ItemEquipped(characterId, equipmentId);
}
```

### Marketplace Integration
```solidity
// Example of listing equipment for sale
function listEquipment(
    uint256 tokenId,
    uint256 price,
    bool isAuction,
    uint256 duration
) external {
    require(balanceOf(msg.sender, tokenId) > 0, "Not owner");
    require(!isEquipped[tokenId], "Equipment is equipped");
    
    if (isAuction) {
        _createAuction(tokenId, price, duration);
    } else {
        _createFixedPriceListing(tokenId, price);
    }
    
    emit EquipmentListed(tokenId, price, isAuction);
}
```

## Advanced Usage Examples

### Special Ability Implementation
```solidity
// Example of a complex special ability system
function executeSpecialAbility(
    uint256 characterId,
    uint256 equipmentId,
    uint256 abilityIndex,
    uint256 targetId
) external returns (bool success) {
    require(_canUseAbility(characterId, equipmentId, abilityIndex), "Cannot use ability");
    
    Types.SpecialAbility memory ability = specialAbilities[equipmentId][abilityIndex];
    
    // Execute ability effects
    success = _processAbilityEffects(ability, characterId, targetId);
    
    if (success) {
        // Update cooldown
        uint256 currentRound = getCurrentRound();
        abilityCooldowns[characterId][equipmentId][abilityIndex] = currentRound + ability.cooldown;
        
        emit AbilityUsed(characterId, equipmentId, abilityIndex, targetId);
    }
    
    return success;
}
```

## Gas Optimization Strategies

### Batch Operations
```solidity
// Example of batch equipment creation
function batchCreateEquipment(
    Types.EquipmentCreationParams[] memory params
) external onlyOwner returns (uint256[] memory tokenIds) {
    tokenIds = new uint256[](params.length);
    
    for (uint256 i = 0; i < params.length; i++) {
        tokenIds[i] = _createSingleEquipment(params[i]);
    }
    
    emit BatchEquipmentCreated(tokenIds);
    return tokenIds;
}
```

### Storage Optimization
```solidity
// Example of packed storage for equipment stats
struct PackedStats {
    uint8 strength;
    uint8 agility;
    uint8 magic;
    uint8 level;
    bool isActive;
    EquipmentType equipType;  // uint8
    EquipmentRarity rarity;   // uint8
}
```

## Error Handling and Recovery

### Equipment State Recovery
```solidity
// Example of equipment state recovery
function recoverEquipmentState(uint256 tokenId) external onlyOwner {
    require(_exists(tokenId), "Equipment does not exist");
    
    // Verify current state
    Types.EquipmentStats memory stats = equipmentStats[tokenId];
    
    // Check for inconsistencies
    if (stats.isActive && isEquipped[tokenId]) {
        // Fix inconsistent state
        _resolveStateConflict(tokenId);
    }
    
    emit EquipmentStateRecovered(tokenId);
}
```

## Security Considerations

### Access Control
- Implement proper role-based access control
- Validate all state transitions
- Protect against reentrancy attacks
- Implement emergency pause functionality

### State Management
- Validate equipment existence before operations
- Ensure atomic state updates
- Implement proper event emission
- Handle edge cases and error conditions

### Integration Security
- Validate cross-contract calls
- Implement proper error handling
- Maintain state consistency across contracts
- Use safe math operations

## Monitoring and Maintenance

### Event Monitoring
Monitor these key events for system health:
- EquipmentCreated
- EquipmentStateChanged
- AbilityUsed
- QualityImproved
- DurabilityUpdated

### System Maintenance
Regular maintenance tasks:
1. Monitor gas costs and optimize as needed
2. Review and update equipment balance
3. Audit special ability usage patterns
4. Monitor and adjust quality/durability mechanics
5. Review and update integration points

## Troubleshooting Guide

### Common Issues and Solutions
1. Equipment State Inconsistency
   - Verify equipment exists
   - Check ownership and equipped status
   - Review recent transactions
   - Use recovery functions if needed

2. Special Ability Failures
   - Verify cooldown periods
   - Check ability requirements
   - Validate target conditions
   - Review ability parameters

3. Integration Problems
   - Verify contract addresses
   - Check permission settings
   - Review event emissions
   - Validate state changes

## Future Enhancements
Planned system improvements:
1. Enhanced quality system with crafting integration
2. Dynamic ability system based on equipment combinations
3. Advanced durability mechanics with repair costs
4. Expanded rarity system with unique effects
5. Integration with achievement system