# Character Contract API Reference 📜

Welcome, sage developer! Here lies the ancient knowledge of the Character contract, the cornerstone of our mystical realm.

## Overview

This contract manages Character NFTs (ERC721), their core stats, state, and equipment. It interacts with `IEquipment`, uses `ProvableRandom` for stat generation, and creates a unique `CharacterWallet` contract for each character to manage its items.

## Dependencies & Setup

- **`IEquipment`**: Interface to the Equipment contract (provided in constructor).
- **`ProvableRandom`**: Used for random stat generation during minting (provided in constructor).
- **`CharacterWallet`**: Contract created *by* `Character.sol` for each NFT to hold equipment.
- **`Ownable`**: Access control for administrative functions.

**Constructor:**
```solidity
constructor(address _equipmentContract, address _provableRandom)
```
Initializes the contract name/symbol, sets immutable dependencies (`equipment`, `provableRandom`), and transfers ownership to the deployer.

## Core Functions 🎭

### mintCharacter
```solidity
function mintCharacter(address to, Types.Alignment alignment) external returns (uint256 tokenId)
```
Forges a new hero (NFT) into existence.
- Mints the ERC721 token to the `to` address.
- Uses `ProvableRandom` to generate initial Strength, Agility, and Magic stats (between `MIN_STAT` (5) and `MAX_STAT` (18)).
- Adjusts stats to ensure they sum exactly to `TOTAL_POINTS` (45), prioritizing the chosen `alignment` stat if points need to be added.
- Creates a new dedicated `CharacterWallet` contract instance for this `tokenId`.
- Initializes the character's state (Level 1, Health 100, etc.).

**Parameters:**
- `to`: The destined owner of this hero.
- `alignment`: The hero's chosen path (STRENGTH, AGILITY, or MAGIC), influencing initial stat distribution.

**Returns:**
- `tokenId`: The unique identifier of the newly forged hero.

**Events Emitted:**
- `CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet)` (Note: `wallet` is the address of the *new* `CharacterWallet` contract).

**Example (Conceptual Client-side):**
```typescript
const alignment = Types.Alignment.STRENGTH;
const tx = await character.mintCharacter(playerAddress, alignment);
const receipt = await tx.wait();
// Find the CharacterCreated event in receipt.events to get the tokenId and wallet address
const event = receipt.events?.find(e => e.event === "CharacterCreated");
const tokenId = event?.args?.tokenId;
const characterWalletAddress = event?.args?.wallet;
```

### getCharacter / getCharacterInfo
```solidity
function getCharacter(uint256 tokenId) external view returns (
    Types.Stats memory stats,
    Types.EquipmentSlots memory equipment,
    Types.CharacterState memory state
)

// Internal helper, also callable directly:
function getCharacterInfo(uint256 tokenId) public view returns (...)
```
Gazes into a hero's essence, revealing their complete state.
- Reads the character's stats (`PackedStats`) and state (`PackedState`) from internal mappings.
- Calls the character's specific `CharacterWallet` contract (`characterWallets[tokenId].getEquippedItems()`) to retrieve currently equipped items.
- Converts internal packed structs to the unpacked `Types.*` structs for the return value.

**Parameters:**
- `tokenId`: The hero's unique identifier.

**Returns:**
- `stats`: The hero's attributes (strength, agility, magic).
- `equipment`: Currently equipped items (weaponId, armorId).
- `state`: Current state (health, level, alignment, etc.).

**Example:**
```typescript
const {stats, equipment, state} = await character.getCharacter(tokenId);
```

### equip
```solidity
function equip(uint256 tokenId, uint256 weaponId, uint256 armorId) external
```
Bestows equipment upon a hero by delegating to the character's wallet.
- Requires `msg.sender` to be the owner of the `tokenId`.
- Calls `characterWallets[tokenId].equip(weaponId, armorId)`. The wallet contract handles verification (e.g., ownership of equipment NFTs).

**Parameters:**
- `tokenId`: The hero to equip.
- `weaponId`: The weapon to wield (0 for none).
- `armorId`: The armor to don (0 for none).

**Events Emitted:**
- `EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId)` (Emits the IDs passed into the function).

**Example:**
```typescript
// Ensure player owns character `tokenId` and equipment NFTs `myWeaponId`, `myArmorId`
// Ensure CharacterWallet has approval for equipment NFTs
await character.equip(tokenId, myWeaponId, myArmorId);
```

### unequip
```solidity
function unequip(uint256 tokenId, bool weapon, bool armor) external
```
Removes equipment from a hero by delegating to the character's wallet.
- Requires `msg.sender` to be the owner of the `tokenId`.
- Calls `characterWallets[tokenId].unequip(weapon, armor)`.

**Parameters:**
- `tokenId`: The hero to unequip.
- `weapon`: Whether to remove the weapon.
- `armor`: Whether to remove the armor.

**Events Emitted:**
- `EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId)` (Note: Implementation emits `weaponId = 0`, `armorId = 0` regardless of which was unequipped, representing the *potential* new state after unequip).

**Example:**
```typescript
await character.unequip(tokenId, true, false); // Remove weapon only
```

## State Management 📊

*(These functions are restricted to the contract owner)*

### updateStats
```solidity
function updateStats(uint256 tokenId, Types.Stats memory newStats) external onlyOwner
```
Alters a hero's attributes.
- Stores the data in the internal `PackedStats` format.

**Parameters:**
- `tokenId`: The hero to modify.
- `newStats`: New attribute values (`uint64` strength, agility, magic).

**Events Emitted:**
- `StatsUpdated(uint256 indexed tokenId, uint64 strength, uint64 agility, uint64 magic)`

### updateState
```solidity
function updateState(uint256 tokenId, Types.CharacterState memory newState) external onlyOwner
```
Modifies a hero's state.
- Stores the data in the internal `PackedState` format.

**Parameters:**
- `tokenId`: The hero to modify.
- `newState`: New state values (health, level, alignment etc.).

**Events Emitted:**
- `StateUpdated(uint256 indexed tokenId, PackedState state)` (Note: Emits the internal packed state struct).

## Events 📯

### CharacterCreated
```solidity
event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet)
```
Heralds the birth of a new hero and provides the address of their dedicated `CharacterWallet`.

### EquipmentChanged
```solidity
event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId)
```
Announces changes in a hero's equipment slots.

### StatsUpdated
```solidity
event StatsUpdated(uint256 indexed tokenId, uint64 strength, uint64 agility, uint64 magic)
```
Proclaims changes in a hero's attributes.

### StateUpdated
```solidity
event StateUpdated(uint256 indexed tokenId, PackedState state)
```
Declares changes in a hero's state, emitting the internal packed struct directly.

## Custom Errors

- `CharacterNotFound()`: Thrown if `tokenId` does not exist.
- `NotCharacterOwner()`: Thrown if `msg.sender` is not the owner of the `tokenId` for `equip`/`unequip` calls.

## Data Structures 📚

### External Structs (Input/Output)
*(Defined in `Types.sol`)*

**Types.Stats:**
```solidity
struct Stats {
    uint64 strength;  // Physical might (5-18)
    uint64 agility;   // Swift grace (5-18)
    uint64 magic;     // Arcane power (5-18)
}
```

**Types.CharacterState:**
```solidity
struct CharacterState {
    uint64 health;             // Life force (0-100)
    uint32 consecutiveHits;    // Battle momentum
    uint32 damageReceived;     // Battle scars
    uint32 roundsParticipated; // Tales of glory
    Types.Alignment alignment;  // Chosen path
    uint8 level;             // Experience rank
}
```

**Types.EquipmentSlots:**
```solidity
struct EquipmentSlots {
    uint256 weaponId; // Equipped weapon (0 if none)
    uint256 armorId;  // Equipped armor (0 if none)
}
```

### Internal Structs (Storage)
*(Used internally for gas optimization)*

**PackedStats:**
```solidity
struct PackedStats {
    uint64 strength;
    uint64 agility;
    uint64 magic;
    uint64 reserved;
}
```

**PackedState:**
```solidity
struct PackedState {
    uint64 health;
    uint32 consecutiveHits;
    uint32 damageReceived;
    uint32 roundsParticipated;
    uint8 level;
    Types.Alignment alignment;
    uint8 reserved;
}
```
*(The `StateUpdated` event emits this `PackedState` struct)*


May these sacred texts guide your journey in our mystical realm! 🌟 