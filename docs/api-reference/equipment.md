# Equipment Contract API Reference 🗡️

Welcome, master blacksmith! Here lies the knowledge of magical items and equipment that heroes may wield in their adventures.

## Core Functions 🛠️

### createEquipment
```solidity
function createEquipment(
    string memory name,
    string memory description,
    uint8 strengthBonus,
    uint8 agilityBonus,
    uint8 magicBonus
) external onlyOwner returns (uint256)
```
Forges a new type of equipment into existence.

**Parameters:**
- `name`: The equipment's name
- `description`: The equipment's description
- `strengthBonus`: Bonus to strength stat
- `agilityBonus`: Bonus to agility stat
- `magicBonus`: Bonus to magic stat

**Returns:**
- `uint256`: The unique identifier (tokenId) of the equipment type

**Events Emitted:**
- `EquipmentCreated(uint256 tokenId, string name, string description)`

**Access:**
- Only contract owner

**Example:**
```typescript
const equipmentId = await equipment.createEquipment(
    "Dragon's Blade",
    "A mighty sword forged in dragon's breath",
    5,  // +5 strength
    2,  // +2 agility
    0   // No magic bonus
);
```

### mint
```solidity
function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyRole(MINTER_ROLE)
```
Creates new instances of an equipment type.

**Parameters:**
- `to`: The recipient address
- `id`: The equipment type ID
- `amount`: Number of copies to mint
- `data`: Additional data for the mint

**Requirements:**
- Caller must have MINTER_ROLE
- Equipment type must exist and be active

**Example:**
```typescript
await equipment.mint(playerAddress, equipmentId, 1, "0x");
```

### getEquipmentStats
```solidity
function getEquipmentStats(uint256 tokenId) external view returns (Types.EquipmentStats memory stats, bool exists)
```
Examines an equipment type's properties.

**Parameters:**
- `tokenId`: The equipment type ID

**Returns:**
- `stats`: The equipment's stats (bonuses, name, description, etc.)
- `exists`: Whether the equipment type exists

**Example:**
```typescript
const [stats, exists] = await equipment.getEquipmentStats(equipmentId);
console.log("Name:", stats.name);
console.log("Strength Bonus:", stats.strengthBonus);
console.log("Is Active:", stats.isActive);
```

### calculateEquipmentBonus
```solidity
function calculateEquipmentBonus(uint256 characterId) external view returns (
    uint8 strengthBonus,
    uint8 agilityBonus,
    uint8 magicBonus
)
```
Calculates total stat bonuses from a character's equipped items.

**Parameters:**
- `characterId`: The character to check

**Returns:**
- Combined bonuses from all equipped items

**Example:**
```typescript
const [str, agi, mag] = await equipment.calculateEquipmentBonus(characterId);
console.log("Total Bonuses:", { strength: str, agility: agi, magic: mag });
```

## Special Abilities 🌟

Equipment can have special abilities that trigger under specific conditions during combat or gameplay. Each ability has a name, description, trigger condition, effect type, and cooldown period.

### getSpecialAbility
```solidity
function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex) external view returns (Types.SpecialAbility memory)
```
Retrieves a specific special ability of an equipment type.

**Parameters:**
- `equipmentId`: The equipment type ID
- `abilityIndex`: Index of the ability to retrieve

**Returns:**
- A `SpecialAbility` struct containing:
  - `name`: Ability name
  - `description`: Ability description
  - `triggerCondition`: When the ability can trigger (ON_LOW_HEALTH, ON_HIGH_DAMAGE, ON_CONSECUTIVE_HITS)
  - `triggerValue`: Threshold value for the trigger condition
  - `effectType`: Type of effect (DAMAGE_BOOST, HEALING_BOOST, DEFENSE_BOOST)
  - `effectValue`: Magnitude of the effect
  - `cooldown`: Number of rounds before ability can be used again

**Example:**
```typescript
const ability = await equipment.getSpecialAbility(equipmentId, 0);
console.log("Ability Name:", ability.name);
console.log("Trigger:", ability.triggerCondition);
console.log("Effect:", ability.effectType);
```

### getSpecialAbilities
```solidity
function getSpecialAbilities(uint256 equipmentId) external view returns (Types.SpecialAbility[] memory)
```
Retrieves all special abilities of an equipment type.

**Parameters:**
- `equipmentId`: The equipment type ID

**Returns:**
- Array of all `SpecialAbility` structs for this equipment

**Example:**
```typescript
const abilities = await equipment.getSpecialAbilities(equipmentId);
for (const ability of abilities) {
    console.log(`${ability.name}: ${ability.description}`);
}
```

### checkTriggerCondition
```solidity
function checkTriggerCondition(
    uint256 characterId,
    uint256 equipmentId,
    uint256 abilityIndex,
    uint256 currentRound
) external view returns (bool)
```
Checks if a special ability can be triggered based on its cooldown.

**Parameters:**
- `characterId`: The character attempting to use the ability
- `equipmentId`: The equipment with the ability
- `abilityIndex`: Index of the ability to check
- `currentRound`: Current combat round number

**Returns:**
- `bool`: True if the ability can be triggered (cooldown has expired)

**Example:**
```typescript
const canTrigger = await equipment.checkTriggerCondition(
    characterId,
    equipmentId,
    0,  // First ability
    currentRound
);
if (canTrigger) {
    console.log("Ability ready to use!");
}
```

### updateAbilityCooldown
```solidity
function updateAbilityCooldown(
    uint256 characterId,
    uint256 equipmentId,
    uint256 abilityIndex,
    uint256 currentRound
) external onlyCharacterContract
```
Updates the last used round for an ability after it's triggered.

**Parameters:**
- `characterId`: The character that used the ability
- `equipmentId`: The equipment with the ability
- `abilityIndex`: Index of the ability used
- `currentRound`: Current combat round number

**Access:**
- Only callable by the character contract

**Example:**
```typescript
// This would be called internally by the character contract
await equipment.updateAbilityCooldown(
    characterId,
    equipmentId,
    0,  // First ability
    currentRound
);
```

## Equipment Management 🛠️

### activateEquipment
```solidity
function activateEquipment(uint256 equipmentId) external onlyOwner
```
Enables an equipment type for use.

### deactivateEquipment
```solidity
function deactivateEquipment(uint256 equipmentId) external onlyOwner
```
Disables an equipment type from use.

## Events 📯

### EquipmentCreated
```solidity
event EquipmentCreated(uint256 indexed tokenId, string name, string description)
```
Announces the creation of a new equipment type.

### EquipmentActivated
```solidity
event EquipmentActivated(uint256 indexed tokenId)
```
Announces when an equipment type becomes available.

### EquipmentDeactivated
```solidity
event EquipmentDeactivated(uint256 indexed tokenId)
```
Announces when an equipment type is disabled.

## Data Structures 📚

### EquipmentStats
```solidity
struct EquipmentStats {
    uint8 strengthBonus;   // Bonus to strength
    uint8 agilityBonus;    // Bonus to agility
    uint8 magicBonus;      // Bonus to magic
    bool isActive;         // Whether equipment is usable
    string name;           // Equipment name
    string description;    // Equipment description
}
```

### SpecialAbility
```solidity
struct SpecialAbility {
    string name;           // Name of the ability
    string description;    // Description of what it does
    TriggerCondition triggerCondition;  // When it can activate
    uint256 triggerValue; // Threshold for activation
    EffectType effectType;  // What kind of effect
    uint256 effectValue;   // How strong the effect is
    uint256 cooldown;      // Rounds between uses
}
```

### TriggerCondition
```solidity
enum TriggerCondition {
    NONE,
    ON_LOW_HEALTH,    // Triggers when health below threshold
    ON_HIGH_DAMAGE,   // Triggers when damage taken above threshold
    ON_CONSECUTIVE_HITS  // Triggers after X consecutive hits
}
```

### EffectType
```solidity
enum EffectType {
    NONE,
    DAMAGE_BOOST,    // Increases damage dealt
    HEALING_BOOST,   // Increases healing received
    DEFENSE_BOOST    // Increases defense
}
```

## Error Messages 🚫

```solidity
"Equipment does not exist"     // When accessing invalid equipment
"Equipment not active"         // When minting disabled equipment
"Invalid ability index"        // When accessing invalid special ability
"Only character contract"      // When unauthorized contract calls
"Invalid character contract"   // When setting invalid character contract
```

## Best Practices 💡

1. **Equipment Creation**
   - Balance stat bonuses for game balance
   - Provide clear names and descriptions
   - Consider special ability combinations
   - Design abilities that complement different playstyles

2. **Equipment Management**
   - Track active/inactive status
   - Monitor equipment distribution
   - Handle ability cooldowns properly
   - Test ability triggers thoroughly

3. **Gas Optimization**
   - Batch mint operations when possible
   - Cache equipment stats for frequent access
   - Use view functions for queries
   - Consider cooldown timing in ability design

May your forge burn bright and your equipment serve heroes well! ⚔️✨