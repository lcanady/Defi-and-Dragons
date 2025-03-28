# Combat System API Reference 🗡️

Welcome to the combat system documentation! This guide covers the core combat mechanics, damage calculation, abilities, and related quest systems.

## Overview

The combat system is composed of several key contracts:

-   **`CombatDamageCalculator.sol`**: Calculates base damage based on character stats, equipment, and affinities.
-   **`CombatActions.sol`**: Manages specific "combat moves" triggered by DeFi actions, tracks battle state, combos, critical hits, and life steal.
-   **`CombatAbilities.sol`**: Defines elemental abilities, manages their usage, status effects (buffs/debuffs), and elemental interactions/combos.
-   **`CombatQuest.sol`**: Manages combat-specific quests like monster hunts and boss fights, utilizing the other combat contracts. (See `quest.md` for full Quest API details).

---

## Combat Damage Calculator (`CombatDamageCalculator.sol`) 🧮

Handles the fundamental damage calculation based on character stats and equipped weapon affinity.

### Contract Setup

**Constructor:**
```solidity
constructor(address _characterContract, address _equipmentContract) Ownable()
```
Initializes with the `Character` and `Equipment` contract addresses.

**Dependencies:**
- `ICharacter`: To fetch character stats and equipment slots.
- `IEquipment`: To fetch weapon stats and stat affinity.

### Core Function

**calculateDamage:**
```solidity
function calculateDamage(uint256 characterId, uint256 targetId) external view returns (uint256)
```
Calculates the potential damage an attacker (`characterId`) can deal.
- Starts with `BASE_DAMAGE`.
- Fetches character stats and equipped weapon (`equipment.weaponId`) via `ICharacter`.
- If a weapon is equipped, fetches `EquipmentStats` via `IEquipment`.
- Adds the character's relevant stat (Strength, Agility, or Magic based on `weaponStats.statAffinity`) to `BASE_DAMAGE`.
- Adds weapon stat bonuses (`strengthBonus`, etc.).
- Applies `AFFINITY_BONUS_MULTIPLIER` if the character's alignment matches the weapon's `statAffinity`.
- **Note:** The `targetId` parameter is currently unused in this specific calculation but might be relevant for future defense/resistance calculations.

**Constants:**
- `BASE_DAMAGE`: 10
- `AFFINITY_BONUS_MULTIPLIER`: 150 (1.5x)
- `SCALING_DENOMINATOR`: 100

---

## Combat Actions (`CombatActions.sol`) ⚔️

Manages specific "combat moves" triggered by DeFi actions, tracks battle state, combos, critical hits, and life steal.

### Contract Setup

**Constructor:**
```solidity
constructor(address _character, address _gameToken, address _randomness, address _damageCalculator) Ownable()
```
Initializes with `Character`, `GameToken`, `ProvableRandom`, and `CombatDamageCalculator` contract addresses.

**Dependencies:**
- `ICharacter`: For character ownership and stats (potentially).
- `IGameToken`: For potential reward/cost mechanics (not directly used in snippets).
- `ProvableRandom`: For randomness in critical hits, combos, etc.
- `CombatDamageCalculator`: Referenced, but damage calculation seems handled internally in `calculateDamage`.

**Roles & Access:**
- `Ownable`: Most creation/configuration functions are `onlyOwner`.
- `setProtocolApproval`: `onlyOwner` function to approve external contracts (e.g., DeFi protocols) to call `triggerMove`.
- `triggerMove`: Requires `msg.sender` to be an `approvedProtocol`.
- `startBattle`: Requires `msg.sender` to be the `character.ownerOf(characterId)`.

### Enums

**ActionType:** (Triggers for moves)
```solidity
enum ActionType { NONE, TRADE, YIELD_FARM, GOVERNANCE_VOTE, BRIDGE_TOKENS, FLASH_LOAN, NFT_TRADE, CREATE_PROPOSAL, DELEGATE }
```

**SpecialEffect:** (Effects applied by moves)
```solidity
enum SpecialEffect { NONE, CHAIN_ATTACK, CRITICAL_HIT, LIFE_STEAL, ARMOR_BREAK, COMBO_ENABLER, MULTI_STRIKE, DOT }
```

### Structs

**CombatMove:** (Packed for gas efficiency)
```solidity
struct CombatMove {
    string name;
    uint32 baseDamage;      // Base damage
    uint32 scalingFactor;   // Scaling modifier (applied in internal calculateDamage)
    uint32 cooldown;        // Seconds between uses
    uint32 minValue;        // Minimum action value to trigger
    uint32 effectValue;     // Magnitude of special effect
    ActionType[] triggers;  // DeFi actions that can trigger this
    SpecialEffect effect;   // Special effect applied
    bool active;            // Is the move usable?
    uint16 criticalChance; // Specific crit chance added by this move
}
```

**PackedBattleState:** (Tracks ongoing battles per character)
```solidity
struct PackedBattleState {
    bytes32 targetId;       // ID of the opponent
    uint128 remainingHealth; // Target's current health
    uint40 battleStartTime;  // Timestamp battle began
    uint8 comboCount;       // Current combo chain length
    bool isActive;          // Is a battle currently happening?
}
```

**EffectState:** (Tracks temporary applied effects)
```solidity
struct EffectState {
    uint40 endTime;         // Timestamp effect expires
    uint32 value;           // Magnitude of the effect
}
```

### State Variables & Mappings

- `moves`: `bytes32 => CombatMove`
- `battles`: `uint256 (characterId) => PackedBattleState`
- `approvedProtocols`: `address => bool`
- `comboPaths`: `bytes32 (moveId) => mapping(bytes32 (moveId) => bool)` (Valid sequences)
- `lastMove`: `uint256 (characterId) => bytes32 (moveId)`
- `criticalChances`: `uint256 (characterId) => uint16` (Base crit chance, 0-10000)
- `lifeStealAmounts`: `uint256 (characterId) => uint16` (Base life steal %, 0-10000)
- `moveCooldowns`: `uint256 (characterId) => mapping(bytes32 (moveId) => uint40 (timestamp))`
- `effectStates`: `uint256 (characterId) => mapping(SpecialEffect => EffectState)` (Private)

### Events

- `MoveCreated(bytes32 indexed moveId, string name, ActionType[] triggers)`
- `MoveTriggered(bytes32 indexed moveId, uint256 indexed characterId, uint256 damage)`
- `BattleStarted(uint256 indexed characterId, bytes32 indexed targetId, uint256 health)`
- `BattleEnded(uint256 indexed characterId, bytes32 indexed targetId, bool victory)`
- `DamageDealt(uint256 indexed characterId, bytes32 indexed targetId, uint256 damage)`
- `ComboTriggered(uint256 indexed characterId, uint8 comboCount, uint256 bonusDamage)`
- `SpecialEffectTriggered(uint256 indexed characterId, SpecialEffect effect, uint32 value)`
- `CriticalHit(uint256 indexed characterId, uint256 originalDamage, uint256 criticalDamage)`

### Core Functions

**setProtocolApproval:**
```solidity
function setProtocolApproval(address protocol, bool approved) external onlyOwner
```
Approves/revokes an external contract's ability to call `triggerMove`.

**createMove:**
```solidity
function createMove(
    string calldata name,
    uint32 baseDamage,
    uint32 scalingFactor,
    uint32 cooldown,
    ActionType[] calldata triggers,
    uint32 minValue,
    SpecialEffect effect,
    uint32 effectValue,
    uint16 criticalChance // Added chance for this specific move
) external onlyOwner returns (bytes32 moveId)
```
Creates a new combat move definition. `moveId` is generated via keccak256.

**createComboPath:**
```solidity
function createComboPath(bytes32 firstMoveId, bytes32 secondMoveId) external onlyOwner
```
Defines a valid sequence: `secondMoveId` can follow `firstMoveId` for combo bonuses.

**setCriticalChance:**
```solidity
function setCriticalChance(uint256 characterId, uint16 chance) external onlyOwner
```
Sets the base critical hit chance (0-5000, i.e., 0-50%) for a character.

**setLifeSteal:**
```solidity
function setLifeSteal(uint256 characterId, uint16 amount) external onlyOwner
```
Sets the base life steal percentage (0-2000, i.e., 0-20%) for a character.

**startBattle:**
```solidity
function startBattle(uint256 characterId, bytes32 targetId, uint128 targetHealth) external
```
Initiates a battle for `characterId` against `targetId`. Requires caller to be character owner. Sets `battles[characterId]`.

**triggerMove:**
```solidity
function triggerMove(uint256 characterId, ActionType actionType, uint256 actionValue) external returns (uint256 damage)
```
Called by an `approvedProtocol` when a character performs a relevant DeFi action.
- Finds the best eligible move (`findBestMove`) based on `actionType` and `actionValue`.
- Checks move cooldown (`moveCooldowns`).
- Calculates damage using internal `calculateDamage` (applies move scaling, crit chance, effects).
- Applies potential base critical hit (using `criticalChances` and `ProvableRandom`).
- Applies potential base life steal (using `lifeStealAmounts`).
- Updates `battles[characterId].remainingHealth`.
- Applies the move's `SpecialEffect` (e.g., DOT, Armor Break via `effectStates`).
- Updates combo state (`comboCount`, `lastMove`) and applies combo bonus damage if `comboPaths` allows.
- Records move cooldown.
- Checks if `remainingHealth <= 0` and calls `endBattle`.
- Emits relevant events (`MoveTriggered`, `DamageDealt`, `CriticalHit`, etc.).

**endBattle:** (Internal - called by `triggerMove`)
```solidity
// Conceptual - not explicitly shown but implied by BattleEnded event
// function endBattle(uint256 characterId, bool victory) internal
```
Marks the battle inactive (`battles[characterId].isActive = false`), resets combo count, emits `BattleEnded`.

### Custom Errors

- `NotCharacterOwner()`
- `NotAuthorized()` (e.g., `triggerMove` caller not approved)
- `BattleInProgress()`
- `NoActiveBattle()`
- `NoEligibleMoves()`
- `MoveOnCooldown()`
- `InvalidMoves()` (e.g., for `createComboPath`)
- `ChanceTooHigh()` (e.g., `setCriticalChance`)
- `AmountTooHigh()` (e.g., `setLifeSteal`)
- `NameRequired()`
- `TriggersRequired()`

---

## Combat Abilities (`CombatAbilities.sol`) 🔮

Manages elemental abilities, status effects (buffs/debuffs), and elemental interactions/combos.

### Contract Setup

**Constructor:**
```solidity
constructor(address initialOwner) Ownable()
```
Initializes ownership and calls `setupElementalEffectiveness`.

**Dependencies:** None explicitly listed beyond OpenZeppelin Ownable.

**Roles & Access:**
- `Ownable`: Used for creating abilities and combos.
- `useAbility`: Can be called externally, likely by players/characters or other game contracts.

### Enums

**Element:**
```solidity
enum Element { NEUTRAL, FIRE, WATER, EARTH, AIR, LIGHT, DARK }
```

**AbilityType:**
```solidity
enum AbilityType { DAMAGE, DOT, BUFF, DEBUFF, HEAL, SHIELD, SPECIAL }
```

### Structs

**Ability:** (Packed)
```solidity
struct Ability {
    string name;
    AbilityType abilityType;
    Element element;
    uint32 power;       // Base magnitude
    uint32 duration;    // Effect duration in seconds (for DOT, BUFF, DEBUFF)
    uint32 cooldown;    // Seconds between uses
    bool isAOE;         // Area of effect?
    bool requiresCharge;// Special condition?
    string[] requirements;// Other conditions (e.g., item names)
    bool active;        // Is usable?
}
```

**StatusEffect:** (Packed - tracks active effects on characters)
```solidity
struct StatusEffect {
    bytes32 abilityId;  // ID of the ability causing the effect
    uint40 startTime;   // Timestamp effect began
    uint32 duration;    // How long it lasts
    uint32 power;       // Magnitude (e.g., damage per tick, stat change)
    bool isActive;      // Is currently active?
}
```

**ComboBonus:** (Packed - defines elemental combos)
```solidity
struct ComboBonus {
    Element[] elements;     // Sequence of elements needed
    uint32 bonusMultiplier; // Damage multiplier (e.g., 150 for 1.5x)
    uint32 timeWindow;      // Max seconds between casts to continue combo
}
```

### State Variables & Mappings

- `abilities`: `bytes32 => Ability`
- `statusEffects`: `uint256 (characterId) => StatusEffect[]` (Array of effects on a character)
- `lastElementCast`: `uint256 (userId) => mapping(Element => uint40 (timestamp))` (Tracks cooldowns)
- `comboBonuses`: `bytes32 (comboId) => ComboBonus`
- `elementalEffectiveness`: `Element => mapping(Element => uint16 (percentage))` (e.g., Fire vs Earth = 150)

### Events

- `AbilityCreated(bytes32 indexed id, string name, AbilityType abilityType, Element element)`
- `AbilityUsed(bytes32 indexed abilityId, uint256 indexed userId, uint256 indexed targetId)`
- `StatusEffectApplied(uint256 indexed targetId, bytes32 indexed abilityId, uint32 duration)`
- `ComboAchieved(bytes32 indexed comboId, uint256 indexed userId, uint32 bonusMultiplier)`
- `ElementalResonance(uint256 indexed userId, Element element, uint32 bonus)` (Likely related to combos/sequences)

### Core Functions

**setupElementalEffectiveness:** (Internal - called by constructor)
Initializes the `elementalEffectiveness` mapping with base strengths/weaknesses (e.g., Fire > Earth, Fire < Water).

**createAbility:**
```solidity
function createAbility(
    string calldata name,
    AbilityType abilityType,
    Element element,
    uint32 power,
    uint32 duration,
    uint32 cooldown,
    bool isAOE,
    bool requiresCharge,
    string[] calldata requirements
) external onlyOwner returns (bytes32 abilityId)
```
Creates a new ability definition. `abilityId` generated via keccak256.

**createComboBonus:**
```solidity
function createComboBonus(Element[] calldata elements, uint32 bonusMultiplier, uint32 timeWindow) external onlyOwner returns (bytes32 comboId)
```
Defines an elemental combo sequence and its reward multiplier. `comboId` generated via keccak256. Requires `elements.length >= 2`.

**useAbility:**
```solidity
function useAbility(bytes32 abilityId, uint256 userId, uint256 targetId) external returns (uint256 effectPower)
```
Executes an ability.
- Checks if ability is active and not on cooldown (`lastElementCast`).
- Updates `lastElementCast`.
- Calculates base effect power using internal `calculateAbilityEffect` (considers elemental effectiveness vs target, user's active status effects).
- Applies status effects to `targetId` using `applyStatusEffect` if `ability.duration > 0`.
- Checks for completed elemental combos (`checkCombo`) based on `lastElementCast` history and `comboBonuses`. Applies bonus if achieved.
- Emits `AbilityUsed`, potentially `StatusEffectApplied`, `ComboAchieved`.
- Returns the final calculated `effectPower`.

**applyStatusEffect:** (Internal)
Adds a `StatusEffect` struct to the `statusEffects[targetId]` array and emits `StatusEffectApplied`. Handles cleanup of expired effects.

**calculateAbilityEffect:** (Internal View)
Calculates power based on base power, elemental effectiveness (`elementalEffectiveness`), and modifies based on the user's current `statusEffects` (buffs/debuffs).

**checkCombo:** (Internal)
Checks if the sequence of recently cast elements by `userId` matches any defined `comboBonuses` within their `timeWindow`.

### Custom Errors

- `AbilityNotActive()`
- `AbilityOnCooldown()`
- `ComboTooShort()` (For `createComboBonus`)

---

## Combat Quests (`CombatQuest.sol`) 🐉

Manages combat-specific quests like monster hunts and boss fights. This is a brief summary; see `docs/api-reference/quest.md` for full details on the quest system.

### Key Interactions

- **Uses `CombatDamageCalculator`**: The `attackBoss` function calls `damageCalculator.calculateDamage(characterId, targetId)` to determine character damage against the boss.
- **Uses `CombatAbilities`**: Can be configured with abilities (`setMonsterAbilities`). Bosses use these abilities (`useRandomBossAbility`) during fights, potentially applying status effects defined in `CombatAbilities`.
- **Uses `ItemDrop`**: For distributing loot upon defeating bosses or monsters.

### Combat-Specific Features

- **Monster/Boss Creation (`createMonster`)**: Defines monsters with stats (health, damage, defense) and whether they are a boss. Uses packed types (`uint32`, `uint128`).
- **Boss Fights (`startBossFight`, `attackBoss`, `defeatBoss`)**: Manages timed boss encounters where multiple players can deal damage (`damageDealt` mapping). Rewards are distributed based on damage contribution.
- **Hunts (`createHunt`, `startHunt`, `recordMonsterSlain`, `completeHunt`)**: Manages quests to defeat a specific number of a certain monster type, potentially within a time limit for bonus rewards. Uses packed structs (`PackedHunt`, `PackedHuntProgress`).
- **Abilities & Loot (`setMonsterAbilities`, `setLootTable`)**: Allows assigning abilities (from `CombatAbilities`) and item drop tables (using `ItemDrop`) to monsters.

*(Refer to `docs/api-reference/quest.md` for detailed function signatures, structs like `Monster`, `PackedBossFight`, `PackedHunt`, events, etc.)*

---

*May your strikes be true and your defenses hold!* 🛡️🔥 