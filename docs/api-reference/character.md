# Character Contract API Reference 📜

Welcome, sage developer! Here lies the ancient knowledge of the Character contract, the cornerstone of our mystical realm.

## Core Functions 🎭

### mintCharacter
```solidity
function mintCharacter(address to, Types.Alignment alignment) external returns (uint256)
```
Forges a new hero into existence with randomly distributed stats.

**Parameters:**
- `to`: The destined owner of this hero
- `alignment`: The hero's chosen path (STRENGTH, AGILITY, or MAGIC)

**Returns:**
- `uint256`: The unique identifier (tokenId) of your newly forged hero

**Events Emitted:**
- `CharacterCreated(uint256 tokenId, address owner, address wallet)`

**Example:**
```typescript
const alignment = Types.Alignment.STRENGTH;
const characterId = await character.mintCharacter(playerAddress, alignment);
```

### getCharacter
```solidity
function getCharacter(uint256 tokenId) external view returns (
    Types.Stats memory stats,
    Types.EquipmentSlots memory equipment,
    Types.CharacterState memory state
)
```
Gazes into a hero's essence, revealing their complete state.

**Parameters:**
- `tokenId`: The hero's unique identifier

**Returns:**
- `stats`: The hero's attributes (strength, agility, magic)
- `equipment`: Currently equipped items
- `state`: Current state (health, level, etc.)

**Example:**
```typescript
const {stats, equipment, state} = await character.getCharacter(characterId);
```

### equip
```solidity
function equip(uint256 tokenId, uint256 weaponId, uint256 armorId) external
```
Bestows equipment upon a hero.

**Parameters:**
- `tokenId`: The hero to equip
- `weaponId`: The weapon to wield (0 for none)
- `armorId`: The armor to don (0 for none)

**Events Emitted:**
- `EquipmentChanged(uint256 tokenId, uint256 weaponId, uint256 armorId)`

**Example:**
```typescript
await character.equip(characterId, myWeaponId, myArmorId);
```

### unequip
```solidity
function unequip(uint256 tokenId, bool weapon, bool armor) external
```
Removes equipment from a hero.

**Parameters:**
- `tokenId`: The hero to unequip
- `weapon`: Whether to remove the weapon
- `armor`: Whether to remove the armor

**Events Emitted:**
- `EquipmentChanged(uint256 tokenId, uint256 weaponId, uint256 armorId)`

**Example:**
```typescript
await character.unequip(characterId, true, false); // Remove weapon only
```

## State Management 📊

### updateStats
```solidity
function updateStats(uint256 tokenId, Types.Stats memory newStats) external onlyOwner
```
Alters a hero's attributes (restricted to contract owner).

**Parameters:**
- `tokenId`: The hero to modify
- `newStats`: New attribute values

**Events Emitted:**
- `StatsUpdated(uint256 tokenId, Types.Stats stats)`

### updateState
```solidity
function updateState(uint256 tokenId, Types.CharacterState memory newState) external onlyOwner
```
Modifies a hero's state (restricted to contract owner).

**Parameters:**
- `tokenId`: The hero to modify
- `newState`: New state values

**Events Emitted:**
- `StateUpdated(uint256 tokenId, Types.CharacterState state)`

## Events 📯

### CharacterCreated
```solidity
event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet)
```
Heralds the birth of a new hero.

### EquipmentChanged
```solidity
event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId)
```
Announces changes in a hero's equipment.

### StatsUpdated
```solidity
event StatsUpdated(uint256 indexed tokenId, Types.Stats stats)
```
Proclaims changes in a hero's attributes.

### StateUpdated
```solidity
event StateUpdated(uint256 indexed tokenId, Types.CharacterState state)
```
Declares changes in a hero's state.

## Data Structures 📚

### Stats
```solidity
struct Stats {
    uint256 strength;  // Physical might (5-18)
    uint256 agility;   // Swift grace (5-18)
    uint256 magic;     // Arcane power (5-18)
}
```

### CharacterState
```solidity
struct CharacterState {
    uint256 health;             // Life force (0-100)
    uint256 consecutiveHits;    // Battle momentum
    uint256 damageReceived;     // Battle scars
    uint256 roundsParticipated; // Tales of glory
    Types.Alignment alignment;  // Chosen path
    uint256 level;             // Experience rank
}
```

### EquipmentSlots
```solidity
struct EquipmentSlots {
    uint256 weaponId; // Equipped weapon (0 if none)
    uint256 armorId;  // Equipped armor (0 if none)
}
```

May these sacred texts guide your journey in our mystical realm! 🌟 