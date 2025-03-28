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
    // Potentially missing CharacterWallet address if used
)
```
Initializes the facade with references to all game system contracts. The `msg.sender` typically owns the underlying contracts and configures permissions.

## Core Systems 🌟

### Character Management

(Interacts with `Character.sol`)

#### createCharacter
```solidity
function createCharacter(Types.Alignment alignment) external returns (uint256 characterId)
```
Creates a new character NFT for the player (`msg.sender`). Calls `character.mintCharacter`.

**Parameters:**
- `alignment`: Character's starting alignment (STRENGTH, AGILITY, MAGIC)

**Returns:**
- `characterId`: The ID of the newly created character NFT

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
Retrieves complete details about a character by calling `character.getCharacter`.

**Parameters:**
- `characterId`: The character's ID

**Returns:**
- `stats`: Character's base stats
- `equipmentSlots`: Currently equipped items
- `state`: Character's current state (level, xp, alignment etc.)

**Example:**
```typescript
const [stats, equipment, state] = await gameFacade.getCharacterDetails(characterId);
```

### Equipment Management

(Interacts with `Character.sol` for equipping, `Equipment.sol` for details)

#### equipItems
```solidity
function equipItems(uint256 characterId, uint256 weaponId, uint256 armorId) external
```
Equips weapon and/or armor to a character via `character.equip`. Requires `msg.sender` to own `characterId`.

**Parameters:**
- `characterId`: The character's ID
- `weaponId`: ID of the weapon to equip (0 if none)
- `armorId`: ID of the armor to equip (0 if none)

**Events Emitted:**
- `EquipmentEquipped(address indexed player, uint256 characterId, uint256 weaponId, uint256 armorId)`

#### unequipItems
```solidity
function unequipItems(uint256 characterId, bool weapon, bool armor) external
```
Removes equipment from a character via `character.unequip`. Requires `msg.sender` to own `characterId`.

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
Gets detailed stats of an equipment piece via `equipment.getEquipmentStats`.

#### getEquipmentAbilities
```solidity
function getEquipmentAbilities(uint256 equipmentId) external view returns (Types.SpecialAbility[] memory abilities)
```
Retrieves all special abilities of an equipment piece via `equipment.getSpecialAbilities`.

### Quest System

(Interacts with `Quest.sol` and `ItemDrop.sol`)

#### startQuest
```solidity
function startQuest(uint256 characterId, uint256 questId) external
```
Begins a solo quest for a character by calling `quest.startQuest(characterId, questId, bytes32(0))`. Requires `msg.sender` to own `characterId`.

**Events Emitted:**
- `QuestStarted(address indexed player, uint256 questId)`

#### completeQuest
```solidity
function completeQuest(uint256 characterId, uint256 questId) external
```
Attempts to complete an active quest via `quest.completeQuest`. If successful, calculates a `dropRateBonus` and potentially requests a random item drop via `itemDrop.requestRandomDrop`. Requires `msg.sender` to own `characterId`.

**Events Emitted:**
- `QuestCompleted(address indexed player, uint256 questId, uint256 requestId)` (Note: `requestId` is from ItemDrop, 0 if no drop requested/successful)

### Item Drop System

(Interacts with `ItemDrop.sol`)

#### requestRandomDrop
```solidity
function requestRandomDrop(uint256 dropRateBonus) external returns (uint256 requestId)
```
Requests a random item drop with a bonus chance via `itemDrop.requestRandomDrop(msg.sender, uint32(dropRateBonus))`.

**Parameters:**
- `dropRateBonus`: Bonus chance modifier (e.g., 100 = +1%)

**Returns:**
- `requestId`: ID to track the VRF request for the drop

**Events Emitted:**
- `ItemDropped(address indexed player, uint256 requestId, uint256 dropRateBonus)`

#### claimItem (Assumed)
*(Likely exists in `ItemDrop.sol`, potentially exposed via facade)*
```solidity
// function claimItem(uint256 requestId) external;
```
Mints the dropped item to the player once the VRF request is fulfilled.

**Events Emitted:**
- `ItemClaimed(address indexed player, uint256 itemId)`

### Marketplace

(Interacts with `Marketplace.sol`, `Equipment.sol`, `GameToken.sol`)

#### listItem
```solidity
function listItem(uint256 equipmentId, uint256 price, uint256 amount) external
```
Lists owned equipment (`equipmentId`) for sale. Requires `msg.sender` to own the equipment and approve the Marketplace contract. Calls `marketplace.listItem`.

**Events Emitted:**
- `ItemListed(address indexed player, uint256 itemId, uint256 price)`

#### purchaseItem
```solidity
function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external
```
Purchases equipment from a listing. Requires `msg.sender` to approve `GameToken` transfer to the Marketplace. Calls `marketplace.purchaseItem`.

**Events Emitted:**
- `ItemPurchased(address indexed player, uint256 itemId, uint256 listingId)`

#### cancelListing
```solidity
function cancelListing(uint256 equipmentId, uint256 listingId) external
```
Cancels an active listing owned by `msg.sender`. Calls `marketplace.cancelListing`.

### Pet System

(Interacts with `Pet.sol`)

#### summonPet (Assumed)
```solidity
// function summonPet(uint256 characterId, uint256 petId) external;
```
Assigns a pet NFT (`petId`) to a character (`characterId`). Requires ownership of both.

**Events Emitted:**
- `PetSummoned(address indexed player, uint256 characterId, uint256 petId)`

#### dismissPet (Assumed)
```solidity
// function dismissPet(uint256 characterId, uint256 petId) external;
```
Removes a pet assignment from a character. Requires ownership.

**Events Emitted:**
- `PetDismissed(address indexed player, uint256 characterId, uint256 petId)`

### Mount System

(Interacts with `Mount.sol`)

#### equipMount (Assumed)
```solidity
// function equipMount(uint256 characterId, uint256 mountId) external;
```
Assigns a mount NFT (`mountId`) to a character (`characterId`). Requires ownership.

**Events Emitted:**
- `MountEquipped(address indexed player, uint256 characterId, uint256 mountId)`

#### unequipMount (Assumed)
```solidity
// function unequipMount(uint256 characterId, uint256 mountId) external;
```
Removes a mount assignment. Requires ownership.

**Events Emitted:**
- `MountUnequipped(address indexed player, uint256 characterId, uint256 mountId)`

### Title System

(Interacts with `Title.sol`)

#### awardTitle (Assumed - likely restricted access)
```solidity
// function awardTitle(uint256 characterId, uint256 titleId) external; // Probably admin only
```
Grants a specific title (`titleId`) to a character.

**Events Emitted:**
- `TitleAwarded(address indexed player, uint256 characterId, uint256 titleId)`

#### revokeTitle (Assumed - likely restricted access)
```solidity
// function revokeTitle(uint256 characterId, uint256 titleId) external; // Probably admin only
```
Removes a title from a character.

**Events Emitted:**
- `TitleRevoked(address indexed player, uint256 characterId, uint256 titleId)`

### Token Management

(Interacts with `CharacterWallet.sol` or similar)

#### transferTokens (Assumed)
```solidity
// function transferTokens(uint256 fromCharacterId, uint256 toCharacterId, uint256 amount) external;
```
Moves game tokens between character wallets. Requires ownership of `fromCharacterId`.

**Events Emitted:**
- `TokensTransferred(address indexed player, uint256 characterId, uint256 amount)` (Note: Event might be ambiguous, needs verification)

#### withdrawTokens (Assumed)
```solidity
// function withdrawTokens(uint256 characterId, uint256 amount) external;
```
Withdraws game tokens from a character wallet to the owner's address. Requires ownership.

**Events Emitted:**
- `TokensWithdrawn(address indexed player, uint256 characterId, uint256 amount)`

## DeFi Integration 💰

(Interacts with various Arcane contracts)

#### stakeArcane (Assumed)
```solidity
// function stakeArcane(uint256 amount) external;
```
Stakes `GameToken` (or LP tokens) into `ArcaneStaking`. Requires token approval.

**Events Emitted:**
- `ArcaneStaked(address indexed player, uint256 amount)`

#### unstakeArcane (Assumed)
```solidity
// function unstakeArcane(uint256 amount) external;
```
Unstakes tokens from `ArcaneStaking`.

**Events Emitted:**
- `ArcaneUnstaked(address indexed player, uint256 amount)`

#### craftArcane (Assumed)
```solidity
// function craftArcane(bytes memory craftingData) external returns (uint256 itemId);
```
Uses `ArcaneCrafting` to create items, potentially consuming resources/tokens.

**Events Emitted:**
- `ArcaneCrafted(address indexed player, uint256 itemId)`

#### addLiquidity (Assumed)
```solidity
// function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
```
Adds liquidity to an AMM pair via `ArcaneRouter`.

#### removeLiquidity (Assumed)
```solidity
// function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, uint256 deadline) external returns (uint amountA, uint amountB);
```
Removes liquidity from an AMM pair via `ArcaneRouter`.

#### swapTokens (Assumed)
```solidity
// function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
```
Swaps tokens via `ArcaneRouter`.

#### startArcaneQuest (Assumed)
```solidity
// function startArcaneQuest(uint256 questId) external;
```
Initiates a DeFi-related quest via `ArcaneQuestIntegration`.

**Events Emitted:**
- `ArcaneQuestStarted(address indexed player, uint256 questId)`

#### completeArcaneQuest (Assumed)
```solidity
// function completeArcaneQuest(uint256 questId) external;
```
Completes a DeFi-related quest via `ArcaneQuestIntegration`.

**Events Emitted:**
- `ArcaneQuestCompleted(address indexed player, uint256 questId)`

## Contract References 🔗

The facade provides direct, immutable access to all major game system contracts:

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
ArcaneStaking public immutable arcaneStaking;
ArcaneCrafting public immutable arcaneCrafting;
ArcaneFactory public immutable arcaneFactory;
ArcanePair public immutable arcanePair;
ArcaneQuestIntegration public immutable arcaneQuestIntegration;
ArcaneRouter public immutable arcaneRouter;
```

## Events 📯

*(Note: Some event parameter names might differ slightly from underlying contracts)*

### Core Game Events
```solidity
event CharacterCreated(address indexed player, uint256 characterId);
event EquipmentEquipped(address indexed player, uint256 characterId, uint256 weaponId, uint256 armorId);
event EquipmentUnequipped(address indexed player, uint256 characterId, bool weapon, bool armor);
event QuestStarted(address indexed player, uint256 questId);
event QuestCompleted(address indexed player, uint256 questId, uint256 requestId); // requestId from ItemDrop
event ItemDropped(address indexed player, uint256 requestId, uint256 dropRateBonus); // requestId from ItemDrop
event ItemClaimed(address indexed player, uint256 itemId);

event PetSummoned(address indexed player, uint256 characterId, uint256 petId);
event PetDismissed(address indexed player, uint256 characterId, uint256 petId);
event MountEquipped(address indexed player, uint256 characterId, uint256 mountId);
event MountUnequipped(address indexed player, uint256 characterId, uint256 mountId);
event TitleAwarded(address indexed player, uint256 characterId, uint256 titleId);
event TitleRevoked(address indexed player, uint256 characterId, uint256 titleId);
event TokensTransferred(address indexed player, uint256 characterId, uint256 amount); // Verify direction/source/dest
event TokensWithdrawn(address indexed player, uint256 characterId, uint256 amount);
```

### Marketplace Events
```solidity
event ItemListed(address indexed player, uint256 itemId, uint256 price);
event ItemPurchased(address indexed player, uint256 itemId, uint256 listingId);
```

### DeFi Events
```solidity
event ArcaneStaked(address indexed player, uint256 amount);
event ArcaneUnstaked(address indexed player, uint256 amount);
event ArcaneCrafted(address indexed player, uint256 itemId);
event ArcaneQuestStarted(address indexed player, uint256 questId);
event ArcaneQuestCompleted(address indexed player, uint256 questId);
// Note: AMM events (Swap, Mint, Burn) likely emitted by Pair/Router directly
```

## Best Practices 💡

1.  **Primary Interface:** Use the `GameFacade` for nearly all user interactions with the game contracts. This simplifies integration and reduces the chance of errors.
2.  **Approvals:** Remember that interactions involving token transfers (Marketplace purchases, DeFi staking/liquidity/swaps) will require the user to approve the respective underlying contract (Marketplace, Router, Staking) to spend their `GameToken` or other ERC20 tokens.
3.  **Ownership:** Many facade functions implicitly require `msg.sender` to own the relevant Character or Equipment NFT. Ensure your frontend/integration verifies ownership or handles potential reverts gracefully.
4.  **Event Handling:** Monitor events emitted by the facade to update UI state efficiently without needing constant contract reads.
5.  **Gas Costs:** While the facade simplifies calls, be mindful that complex interactions (like DeFi swaps or multi-step quests) might still incur significant gas costs due to the underlying contract calls.

*This facade is your key to unlocking the vast world of DeFi & Dragons!* ✨🔑 