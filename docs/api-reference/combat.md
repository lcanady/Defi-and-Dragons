# Combat System API Reference 🗡️

Welcome to the combat system documentation! This guide covers the core combat mechanics, abilities, and quest systems.

## Core Combat Actions 🎯

### CombatActions Contract

The `CombatActions` contract manages combat moves and special effects in battle.

#### Action Types
```solidity
enum ActionType {
    NONE,              // Default state
    TRADE,             // Trading actions
    YIELD_FARM,        // Yield farming actions
    GOVERNANCE_VOTE,   // Governance voting
    BRIDGE_TOKENS,     // Token bridging
    FLASH_LOAN,        // Flash loan actions
    NFT_TRADE,        // NFT trading
    CREATE_PROPOSAL,   // Proposal creation
    DELEGATE          // Power delegation
}
```

#### Special Effects
```solidity
enum SpecialEffect {
    NONE,           // No special effect
    CHAIN_ATTACK,   // Chain multiple attacks
    CRITICAL_HIT,   // Increased damage chance
    LIFE_STEAL,     // Drain health
    ARMOR_BREAK,    // Reduce defense
    COMBO_ENABLER,  // Enable combo moves
    MULTI_STRIKE,   // Multiple hits
    DOT            // Damage over time
}
```

#### Combat Move Structure
```solidity
struct CombatMove {
    string name;           // Move name
    uint256 baseDamage;   // Base damage amount
    uint256 scalingFactor;// Damage scaling
    uint256 cooldown;     // Time between uses
    ActionType[] triggers;// Triggering actions
    uint256 minValue;     // Minimum value required
    SpecialEffect effect; // Special effect type
    uint256 effectValue;  // Effect magnitude
    bool active;          // Whether move is active
}
```

### Core Functions

#### createMove
```solidity
function createMove(
    string memory name,
    uint256 baseDamage,
    uint256 scalingFactor,
    uint256 cooldown,
    ActionType[] memory triggers,
    uint256 minValue,
    SpecialEffect effect,
    uint256 effectValue
) external onlyOwner returns (bytes32)
```
Creates a new combat move.

**Parameters:**
- `name`: Name of the move
- `baseDamage`: Base damage amount
- `scalingFactor`: Damage scaling factor
- `cooldown`: Cooldown period in seconds
- `triggers`: Array of actions that trigger this move
- `minValue`: Minimum value required to use
- `effect`: Special effect type
- `effectValue`: Effect magnitude

**Returns:**
- `bytes32`: Unique ID of the created move

#### triggerMove
```solidity
function triggerMove(
    uint256 characterId,
    ActionType actionType,
    uint256 actionValue
) external returns (uint256)
```
Triggers a combat move based on an action.

**Parameters:**
- `characterId`: ID of the character
- `actionType`: Type of action performed
- `actionValue`: Value of the action

**Returns:**
- `uint256`: Damage dealt

## Combat Abilities 🔮

### CombatAbilities Contract

Manages elemental abilities and status effects.

#### Element Types
```solidity
enum Element {
    NEUTRAL,
    FIRE,
    WATER,
    EARTH,
    AIR,
    LIGHT,
    DARK
}
```

#### Ability Types
```solidity
enum AbilityType {
    DAMAGE,   // Direct damage
    DOT,      // Damage over time
    BUFF,     // Positive effect
    DEBUFF,   // Negative effect
    HEAL,     // Healing
    SHIELD,   // Damage reduction
    SPECIAL   // Special effects
}
```

### Core Functions

#### createAbility
```solidity
function createAbility(
    string calldata name,
    AbilityType abilityType,
    Element element,
    uint256 power,
    uint256 duration,
    uint256 cooldown,
    bool isAOE,
    bool requiresCharge,
    string[] calldata requirements
) external onlyOwner returns (bytes32)
```
Creates a new ability.

**Parameters:**
- `name`: Ability name
- `abilityType`: Type of ability
- `element`: Elemental type
- `power`: Base power
- `duration`: Effect duration
- `cooldown`: Cooldown period
- `isAOE`: Whether affects multiple targets
- `requiresCharge`: Whether needs charging
- `requirements`: Required items/conditions

**Returns:**
- `bytes32`: Unique ID of the created ability

#### useAbility
```solidity
function useAbility(
    bytes32 abilityId,
    uint256 userId,
    uint256 targetId
) external returns (uint256)
```
Uses an ability on a target.

**Parameters:**
- `abilityId`: ID of the ability
- `userId`: ID of the user
- `targetId`: ID of the target

**Returns:**
- `uint256`: Effect power

## Combat Quests ⚔️

### CombatQuest Contract

Manages combat-based quests including boss fights and monster hunts.

#### Monster Structure
```solidity
struct Monster {
    string name;
    uint256 level;
    uint256 health;
    uint256 damage;
    uint256 defense;
    uint256 rewardBase;
    bool isBoss;
    string[] requiredItems;
    bool active;
}
```

### Core Functions

#### createMonster
```solidity
function createMonster(
    string calldata name,
    uint256 level,
    uint256 health,
    uint256 damage,
    uint256 defense,
    uint256 rewardBase,
    bool isBoss,
    string[] calldata requiredItems
) external onlyOwner returns (bytes32)
```
Creates a new monster.

**Parameters:**
- `name`: Monster name
- `level`: Monster level
- `health`: Health points
- `damage`: Base damage
- `defense`: Defense rating
- `rewardBase`: Base reward
- `isBoss`: Whether it's a boss
- `requiredItems`: Required items to fight

**Returns:**
- `bytes32`: Monster ID

#### startBossFight
```solidity
function startBossFight(
    bytes32 monsterId,
    uint256 duration
) external onlyOwner returns (bytes32)
```
Starts a boss fight.

**Parameters:**
- `monsterId`: ID of the boss monster
- `duration`: Fight duration

**Returns:**
- `bytes32`: Fight ID

#### attackBoss
```solidity
function attackBoss(
    bytes32 fightId,
    uint256 characterId,
    uint256 damage,
    bytes32 abilityId
) external
```
Attack a boss monster.

**Parameters:**
- `fightId`: ID of the fight
- `characterId`: ID of the attacker
- `damage`: Damage amount
- `abilityId`: ID of ability used

## Events 📢

### CombatActions Events
- `MoveCreated(bytes32 indexed moveId, string name, ActionType[] triggers)`
- `MoveTriggered(bytes32 indexed moveId, uint256 indexed characterId, uint256 damage)`
- `ComboTriggered(uint256 indexed characterId, uint256 comboCount, uint256 bonusDamage)`
- `SpecialEffectTriggered(uint256 indexed characterId, SpecialEffect effect, uint256 value)`
- `CriticalHit(uint256 indexed characterId, uint256 originalDamage, uint256 criticalDamage)`

### CombatAbilities Events
- `AbilityCreated(bytes32 indexed id, string name, AbilityType abilityType, Element element)`
- `AbilityUsed(bytes32 indexed abilityId, uint256 indexed userId, uint256 indexed targetId)`
- `StatusEffectApplied(uint256 indexed targetId, bytes32 indexed abilityId, uint256 duration)`
- `ComboAchieved(bytes32 indexed comboId, uint256 indexed userId, uint256 bonusMultiplier)`

### CombatQuest Events
- `MonsterCreated(bytes32 indexed id, string name, bool isBoss)`
- `BossFightStarted(bytes32 indexed fightId, bytes32 indexed monsterId, uint256 startTime)`
- `BossDamageDealt(bytes32 indexed fightId, uint256 indexed characterId, uint256 damage)`
- `BossDefeated(bytes32 indexed fightId, uint256 totalDamage, uint256 participants)`
- `HuntCreated(bytes32 indexed id, bytes32 indexed monsterId, uint256 count)`
- `MonsterSlain(bytes32 indexed huntId, uint256 indexed characterId, uint256 reward)`

## Constants ⚡

### CombatActions
```solidity
uint256 public constant MAX_CRIT_CHANCE = 5000;     // 50%
uint256 public constant MAX_LIFE_STEAL = 2000;      // 20%
uint256 public constant CHAIN_ATTACK_WINDOW = 5;    // 5 seconds
uint256 public constant COMBO_BONUS_PERCENT = 1000; // 10% per combo
uint256 public constant MAX_RANDOM = 10000;         // Base for percentages
```

### CombatQuest
```solidity
uint256 public constant COMBAT_COOLDOWN = 5 minutes; // Time between combat actions
```

## Best Practices 💡

1. **Combat Move Design**
   - Balance damage with cooldowns
   - Consider scaling factors carefully
   - Use special effects strategically
   - Design meaningful combos

2. **Ability Management**
   - Track cooldowns properly
   - Handle status effects
   - Consider elemental interactions
   - Manage AOE effects carefully

3. **Quest Implementation**
   - Scale monster difficulty appropriately
   - Balance rewards with challenge
   - Consider required items
   - Implement proper cooldowns

4. **Error Handling**
   - Validate all inputs
   - Check cooldowns
   - Verify ownership
   - Handle status effects properly

May your battles be glorious! 🗡️✨ 