# Equipment System Tutorial

## Overview
The Equipment System manages in-game items as ERC1155 tokens, providing stat bonuses and special abilities to characters. Each piece of equipment can be created, activated/deactivated, and equipped by characters.

## Core Components

### Equipment Contract
- Manages equipment creation and minting
- Handles equipment stats and bonuses
- Controls equipment activation state
- Implements ERC1155 for NFT functionality

### Public Functions

#### Admin Functions
```solidity
// Set the character contract address
function setCharacterContract(address characterContract) external onlyOwner

// Create new equipment
function createEquipment(
    string memory name,
    string memory description,
    uint8 strengthBonus,
    uint8 agilityBonus,
    uint8 magicBonus
) external onlyOwner returns (uint256)

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