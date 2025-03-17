# Character System Tutorial

## Overview
The Character System is the foundation of the game, managing character creation, stats, equipment, and progression. Each character is a unique NFT with its own attributes and equipment loadout.

## Core Components

### Character Contract
- Manages character creation and base stats
- Handles character progression and leveling
- Tracks character state and alignment
- Integrates with equipment and abilities

### Character Wallet
- Manages character's equipment loadout
- Handles equipping/unequipping items
- Stores character-specific items
- Implements ERC1155 receiver for NFT items

## Key Features

### Character Creation
```solidity
function mintCharacter(
    address to,
    Types.Stats memory baseStats,
    Types.Alignment alignment
) external returns (uint256)
```

Creates a new character with:
- Base stats (strength, agility, magic)
- Alignment (determines bonus calculations)
- Unique character ID
- Equipment slots

### Equipment Management
```solidity
function equip(uint256 weaponId, uint256 armorId) external
function unequip(bool weapon, bool armor) external
```

- Characters can equip one weapon and one armor piece
- Equipment provides stat bonuses
- Equipment can be swapped or unequipped

### Character Stats
```solidity
struct Stats {
    uint8 strength;
    uint8 agility;
    uint8 magic;
}
```

- Base stats affect various game mechanics
- Stats can be modified by:
  - Equipment bonuses
  - Pet bonuses
  - Mount bonuses
  - Ability effects

### Character State
```solidity
struct State {
    uint256 level;
    uint256 experience;
    bool isActive;
    uint256 lastActionTime;
}
```

- Tracks character progression
- Manages cooldowns and timers
- Controls character availability

## Integration Points

### Equipment System
- Characters can equip NFT items
- Equipment provides stat bonuses
- Equipment affects gameplay mechanics

### Pet System
- Characters can own and bond with pets
- Pets provide passive bonuses
- Pet abilities complement character stats

### Mount System
- Characters can own and ride mounts
- Mounts provide travel benefits
- Mount bonuses affect gameplay mechanics

### Ability System
- Characters can learn and use abilities
- Abilities provide active and passive effects
- Ability cooldowns are tracked per character

## Usage Examples

### Creating a New Character
```solidity
// Create base stats
Types.Stats memory stats = Types.Stats({
    strength: 10,
    agility: 8,
    magic: 6
});

// Mint character
uint256 characterId = character.mintCharacter(
    playerAddress,
    stats,
    Types.Alignment.STRENGTH
);
```

### Equipping Items
```solidity
// Get character's wallet
CharacterWallet wallet = character.getWallet(characterId);

// Equip items
wallet.equip(weaponId, armorId);
```

### Checking Character Stats
```solidity
// Get total stats including equipment
(Types.Stats memory totalStats,) = calculator.calculateTotalAttributes(characterId);

// Access individual stats
uint8 strength = totalStats.strength;
uint8 agility = totalStats.agility;
uint8 magic = totalStats.magic;
```

## Best Practices

1. **State Management**
   - Always check character state before actions
   - Update state after significant changes
   - Handle cooldowns appropriately

2. **Equipment Handling**
   - Verify equipment ownership before equipping
   - Check equipment compatibility
   - Handle equipment bonuses correctly

3. **Integration**
   - Use events to track important changes
   - Maintain proper access control
   - Follow the checks-effects-interactions pattern

4. **Gas Optimization**
   - Batch operations when possible
   - Use efficient storage patterns
   - Minimize state changes

## Common Pitfalls

1. **Equipment Validation**
   - Not checking equipment ownership
   - Ignoring equipment requirements
   - Incorrect bonus calculations

2. **State Updates**
   - Missing state updates after actions
   - Incorrect cooldown management
   - Race conditions in state changes

3. **Integration Issues**
   - Incorrect permission handling
   - Missing event emissions
   - Improper error handling

## Security Considerations

1. **Access Control**
   - Use proper modifiers for restricted functions
   - Validate caller permissions
   - Implement reentrancy guards

2. **State Protection**
   - Prevent unauthorized state changes
   - Protect against manipulation
   - Validate all inputs

3. **Asset Safety**
   - Secure equipment transfers
   - Protect against unauthorized equips
   - Handle edge cases safely 