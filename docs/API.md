# Dungeons & DeFi - Smart Contract API Documentation

This document provides a comprehensive overview of all public functions available in the Dungeons & DeFi smart contracts.

## Core Contracts

### Character Contract
ERC721 token representing player characters with stats, equipment, and state management.

#### View Functions

##### `getCharacter(uint256 tokenId) → (Stats, EquipmentSlots, CharacterState)`
Returns complete character information for a given token ID.
- `tokenId`: The unique identifier of the character
- Returns: A tuple containing character stats, equipped items, and current state

##### `characterStats(uint256 tokenId) → Stats`
Returns the base stats for a character.
- `tokenId`: The unique identifier of the character
- Returns: Character's strength, agility, and magic stats

##### `characterStates(uint256 tokenId) → CharacterState`
Returns the current state of a character.
- `tokenId`: The unique identifier of the character
- Returns: Character's health, combat stats, and alignment

##### `characterWallets(uint256 tokenId) → CharacterWallet`
Returns the wallet contract associated with a character.
- `tokenId`: The unique identifier of the character
- Returns: Address of the character's equipment wallet

#### State-Changing Functions

##### `mintCharacter(address to, Stats initialStats, Alignment alignment) → uint256`
Creates a new character NFT with initial stats and alignment.
- `to`: Address that will own the character
- `initialStats`: Initial strength, agility, and magic values
- `alignment`: Character's moral alignment (Good, Neutral, Evil)
- Returns: The token ID of the newly minted character

##### `equip(uint256 tokenId, uint256 weaponId, uint256 armorId)`
Equips weapon and armor to a character.
- `tokenId`: The character equipping the items
- `weaponId`: ID of the weapon to equip
- `armorId`: ID of the armor to equip

##### `unequip(uint256 tokenId, bool weapon, bool armor)`
Removes equipped items from a character.
- `tokenId`: The character unequipping items
- `weapon`: Whether to unequip the weapon
- `armor`: Whether to unequip the armor

##### `updateStats(uint256 tokenId, Stats newStats)`
Updates a character's base stats (owner only).
- `tokenId`: The character to update
- `newStats`: New strength, agility, and magic values

##### `updateState(uint256 tokenId, CharacterState newState)`
Updates a character's state (owner only).
- `tokenId`: The character to update
- `newState`: New health, combat stats, and alignment values

### Equipment Contract
ERC1155 token representing weapons, armor, and items with special abilities.

#### View Functions

##### `equipmentStats(uint256 id) → EquipmentStats`
Returns stats for an equipment type.
- `id`: The equipment type ID
- Returns: Stats including strength, agility, and magic bonuses

##### `balanceOf(address account, uint256 id) → uint256`
Returns how many of a specific equipment type an account owns.
- `account`: The address to check
- `id`: The equipment type ID
- Returns: Amount owned

##### `getEquipmentStats(uint256 equipmentId) → EquipmentStats`
Returns complete stats for an equipment type.
- `equipmentId`: The equipment type ID
- Returns: Full equipment statistics and properties

##### `getSpecialAbility(uint256 equipmentId, uint256 abilityIndex) → SpecialAbility`
Returns a specific special ability for an equipment type.
- `equipmentId`: The equipment type ID
- `abilityIndex`: Index of the ability to retrieve
- Returns: Ability details including triggers and effects

##### `getSpecialAbilities(uint256 equipmentId) → SpecialAbility[]`
Returns all special abilities for an equipment type.
- `equipmentId`: The equipment type ID
- Returns: Array of all special abilities

##### `checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound) → bool`
Checks if a special ability can be triggered.
- `characterId`: The character attempting to use the ability
- `equipmentId`: The equipment with the ability
- `abilityIndex`: Index of the ability to check
- `currentRound`: Current game round number
- Returns: Whether the ability can be triggered

##### `calculateEquipmentBonus(uint256 characterId) → (uint8, uint8, uint8)`
Calculates total equipment bonuses for a character.
- `characterId`: The character to calculate bonuses for
- Returns: Total strength, agility, and magic bonuses

#### State-Changing Functions

##### `setCharacterContract(address characterContract)`
Sets the authorized character contract (owner only).
- `characterContract`: Address of the character contract

##### `createEquipment(uint256 equipmentId, string name, string description, uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)`
Creates a new equipment type (owner only).
- `equipmentId`: Unique ID for the equipment type
- `name`: Equipment name
- `description`: Equipment description
- `strengthBonus`: Strength bonus provided
- `agilityBonus`: Agility bonus provided
- `magicBonus`: Magic bonus provided

##### `mint(address to, uint256 id, uint256 amount, bytes data)`
Mints new equipment tokens.
- `to`: Recipient address
- `id`: Equipment type ID
- `amount`: Amount to mint
- `data`: Additional data for the mint

##### `setEquipmentStats(uint256 equipmentId, EquipmentStats stats)`
Updates stats for an equipment type (owner only).
- `equipmentId`: The equipment type to update
- `stats`: New stats to set

##### `setSpecialAbilities(uint256 equipmentId, SpecialAbility[] abilities)`
Sets special abilities for an equipment type (owner only).
- `equipmentId`: The equipment type to update
- `abilities`: Array of special abilities to set

##### `updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)`
Updates the cooldown for a special ability (character contract only).
- `characterId`: The character that used the ability
- `equipmentId`: The equipment with the ability
- `abilityIndex`: Index of the ability used
- `currentRound`: Current game round number

### GameToken Contract
ERC20 token representing the in-game currency.

#### View Functions

##### `questContracts(address) → bool`
Checks if an address is an authorized quest contract.
- `address`: Contract address to check
- Returns: Authorization status

##### `marketplaceContracts(address) → bool`
Checks if an address is an authorized marketplace contract.
- `address`: Contract address to check
- Returns: Authorization status

#### State-Changing Functions

##### `setQuestContract(address questContract, bool authorized)`
Authorizes or deauthorizes a quest contract (owner only).
- `questContract`: Contract address to update
- `authorized`: New authorization status

##### `setMarketplaceContract(address marketplaceContract, bool authorized)`
Authorizes or deauthorizes a marketplace contract (owner only).
- `marketplaceContract`: Contract address to update
- `authorized`: New authorization status

##### `mint(address to, uint256 amount)`
Mints new tokens (quest contract or owner only).
- `to`: Recipient address
- `amount`: Amount to mint

##### `burn(address from, uint256 amount)`
Burns tokens (marketplace contract or owner only).
- `from`: Address to burn from
- `amount`: Amount to burn

### Quest Contract
Manages character quests and rewards.

#### View Functions

##### `character() → ICharacter`
Returns the character contract address.

##### `gameToken() → IGameToken`
Returns the game token contract address.

##### `questTemplates(uint256) → QuestTemplate`
Returns details for a quest template.
- `uint256`: Quest ID
- Returns: Quest requirements and rewards

##### `lastQuestCompletionTime(uint256, uint256) → uint256`
Returns when a character last completed a quest.
- First `uint256`: Character ID
- Second `uint256`: Quest ID
- Returns: Timestamp of last completion

##### `activeQuests(uint256) → bool`
Checks if a quest is currently active.
- `uint256`: Quest ID
- Returns: Active status

#### State-Changing Functions

##### `initialize(address _gameToken)`
Initializes the quest contract with the game token (owner only).
- `_gameToken`: Address of the game token contract

##### `createQuest(uint8 requiredLevel, uint8 requiredStrength, uint8 requiredAgility, uint8 requiredMagic, uint256 rewardAmount, uint256 cooldown) → uint256`
Creates a new quest template (owner only).
- `requiredLevel`: Minimum level required
- `requiredStrength`: Minimum strength required
- `requiredAgility`: Minimum agility required
- `requiredMagic`: Minimum magic required
- `rewardAmount`: Token reward for completion
- `cooldown`: Time before character can repeat quest
- Returns: Generated quest ID

##### `startQuest(uint256 characterId, uint256 questId)`
Starts a quest for a character.
- `characterId`: Character attempting the quest
- `questId`: Quest to attempt

##### `completeQuest(uint256 characterId, uint256 questId)`
Completes a quest and claims rewards.
- `characterId`: Character completing the quest
- `questId`: Quest being completed

## Data Structures

### Types.Stats
```solidity
struct Stats {
    uint8 strength;
    uint8 agility;
    uint8 magic;
}
```

### Types.CharacterState
```solidity
struct CharacterState {
    uint8 health;
    uint16 consecutiveHits;
    uint16 damageReceived;
    uint16 roundsParticipated;
    Types.Alignment alignment;
}
```

### Types.EquipmentStats
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

### Types.SpecialAbility
```solidity
struct SpecialAbility {
    string name;
    string description;
    Types.TriggerCondition triggerCondition;
    uint256 triggerValue;
    Types.EffectType effectType;
    uint256 effectValue;
    uint256 cooldown;
}
```

### Quest.QuestTemplate
```solidity
struct QuestTemplate {
    uint8 requiredLevel;
    uint8 requiredStrength;
    uint8 requiredAgility;
    uint8 requiredMagic;
    uint256 rewardAmount;
    uint256 cooldown;
}
``` 