# GameFacade Contract API Reference 🎮

Welcome, brave adventurer! The GameFacade contract serves as your central gateway to the DeFi & Dragons realm, providing a simplified interface to all game systems.

## Contract Setup 🏗️

### Constructor
```solidity
constructor(
    address _character,
    address _equipment,
    address _gameToken,
    address _itemDrop,
    address _marketplace,
    address _quest,
    address _pet,
    address _mount,
    address _title,
    address _attributeCalculator,
    address _arcaneStaking,
    address _arcaneCrafting,
    address _arcaneFactory,
    address _arcanePair,
    address _arcaneQuestIntegration,
    address _arcaneRouter
)
```
Initializes the facade with references to all game system contracts.

## Core Systems 🌟

### Character Management

#### createCharacter
```solidity
function createCharacter(Types.Alignment alignment) external returns (uint256 characterId)
```
Creates a new character for the player.

**Parameters:**
- `alignment`: Character's alignment (STRENGTH, AGILITY, MAGIC)

**Returns:**
- `characterId`: The ID of the newly created character

**Events Emitted:**
- `CharacterCreated(address indexed player, uint256 characterId)`

**Example:**
```typescript
const characterId = await gameFacade.createCharacter(Types.Alignment.STRENGTH);
```

#### getCharacterDetails
```solidity
function getCharacterDetails(uint256 characterId) external view returns (
    Types.Stats memory stats,
    Types.EquipmentSlots memory equipmentSlots,
    Types.CharacterState memory state
)
```
Retrieves complete details about a character.

**Parameters:**
- `characterId`: The character's ID

**Returns:**
- `stats`: Character's base stats
- `equipmentSlots`: Currently equipped items
- `state`: Character's current state

**Example:**
```typescript
const [stats, equipment, state] = await gameFacade.getCharacterDetails(characterId);
```

### Equipment Management

#### equipItems
```solidity
function equipItems(uint256 characterId, uint256 weaponId, uint256 armorId) external
```
Equips weapon and armor to a character.

**Parameters:**
- `characterId`: The character's ID
- `weaponId`: ID of the weapon to equip
- `armorId`: ID of the armor to equip

**Events Emitted:**
- `EquipmentEquipped(address indexed player, uint256 characterId, uint256 weaponId, uint256 armorId)`

#### unequipItems
```solidity
function unequipItems(uint256 characterId, bool weapon, bool armor) external
```
Removes equipment from a character.

**Parameters:**
- `characterId`: The character's ID
- `weapon`: Whether to unequip weapon
- `armor`: Whether to unequip armor

**Events Emitted:**
- `EquipmentUnequipped(address indexed player, uint256 characterId, bool weapon, bool armor)`

#### getEquipmentDetails
```solidity
function getEquipmentDetails(uint256 equipmentId) external view returns (
    Types.EquipmentStats memory stats,
    bool exists
)
```
Gets detailed information about an equipment piece.

#### getEquipmentAbilities
```solidity
function getEquipmentAbilities(uint256 equipmentId) external view returns (Types.SpecialAbility[] memory abilities)
```
Retrieves all special abilities of an equipment piece.

### Quest System

#### startQuest
```solidity
function startQuest(uint256 characterId, uint256 questId) external
```
Begins a quest for a character.

**Events Emitted:**
- `QuestStarted(address indexed player, uint256 questId)`

#### completeQuest
```solidity
function completeQuest(uint256 characterId, uint256 questId) external
```
Completes an active quest.

**Events Emitted:**
- `QuestCompleted(address indexed player, uint256 questId, uint256 reward)`

### Item Drop System

#### requestRandomDrop
```solidity
function requestRandomDrop(uint256 dropRateBonus) external returns (uint256 requestId)
```
Requests a random item drop with bonus chance.

**Parameters:**
- `dropRateBonus`: Bonus to the drop rate

**Returns:**
- `requestId`: ID to track the drop request

**Events Emitted:**
- `ItemDropped(address indexed player, uint256 itemId, uint256 dropRateBonus)`

### Marketplace

#### listItem
```solidity
function listItem(uint256 equipmentId, uint256 price, uint256 amount) external
```
Lists equipment for sale on the marketplace.

**Events Emitted:**
- `ItemListed(address indexed player, uint256 itemId, uint256 price)`

#### purchaseItem
```solidity
function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external
```
Purchases equipment from the marketplace.

**Events Emitted:**
- `ItemPurchased(address indexed player, uint256 itemId, uint256 listingId)`

#### cancelListing
```solidity
function cancelListing(uint256 equipmentId, uint256 listingId) external
```
Cancels a marketplace listing.

## Contract References 🔗

The facade provides access to all major game systems:

```solidity
Character public immutable character;
Equipment public immutable equipment;
GameToken public immutable gameToken;
ItemDrop public immutable itemDrop;
Marketplace public immutable marketplace;
Quest public immutable quest;
Pet public immutable pet;
Mount public immutable mount;
Title public immutable title;
AttributeCalculator public immutable attributeCalculator;
```

## DeFi Integration 💰

The facade also manages DeFi features through:

```solidity
ArcaneStaking public immutable arcaneStaking;
ArcaneCrafting public immutable arcaneCrafting;
ArcaneFactory public immutable arcaneFactory;
ArcanePair public immutable arcanePair;
ArcaneQuestIntegration public immutable arcaneQuestIntegration;
ArcaneRouter public immutable arcaneRouter;
```

## Events 📯

### Core Game Events
```solidity
event CharacterCreated(address indexed player, uint256 characterId)
event EquipmentEquipped(address indexed player, uint256 characterId, uint256 weaponId, uint256 armorId)
event EquipmentUnequipped(address indexed player, uint256 characterId, bool weapon, bool armor)
event QuestStarted(address indexed player, uint256 questId)
event QuestCompleted(address indexed player, uint256 questId, uint256 reward)
event ItemDropped(address indexed player, uint256 itemId, uint256 dropRateBonus)
event ItemClaimed(address indexed player, uint256 itemId)
```

### Marketplace Events
```solidity
event ItemListed(address indexed player, uint256 itemId, uint256 price)
event ItemPurchased(address indexed player, uint256 itemId, uint256 listingId)
```

### DeFi Events
```solidity
event ArcaneStaked(address indexed player, uint256 amount)
event ArcaneUnstaked(address indexed player, uint256 amount)
event ArcaneCrafted(address indexed player, uint256 itemId)
event ArcaneQuestStarted(address indexed player, uint256 questId)
event ArcaneQuestCompleted(address indexed player, uint256 questId)
```

## Best Practices 💡

1. **System Access**
   - Use the facade for all game interactions
   - Don't interact with individual contracts directly
   - Handle events for UI updates

2. **Transaction Flow**
   - Check requirements before transactions
   - Handle all possible error cases
   - Monitor events for confirmation

3. **Gas Optimization**
   - Batch operations when possible
   - Use view functions for queries
   - Cache frequently accessed data

May your journey through the realm be prosperous! 🗡️✨ 