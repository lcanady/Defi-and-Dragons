# 🎮 The Adventurer's Chronicle: Core Game Systems

*Welcome, brave soul, to the sacred texts that detail the fundamental systems of our realm. Here you shall learn the ancient arts of combat, the ways of special actions, and the core mechanics that govern our world.*

## ⚔️ The Combat Codex
Deep within the ancient tomes, we find the sacred `CombatActions` scrolls, which reveal the following mystical arts:

```solidity
// The Sacred Actions
enum ActionType {
    NONE,              // The void state
    TRADE,             // The merchant's way
    YIELD_FARM,        // The harvest ritual
    GOVERNANCE_VOTE,   // The council's voice
    BRIDGE_TOKENS,     // The planar bridge
    FLASH_LOAN,        // The lightning borrower
    NFT_TRADE,         // The artifact exchange
    CREATE_PROPOSAL,   // The lawmaker's craft
    DELEGATE          // The power transfer
}

// The Mystical Effects
enum SpecialEffect {
    NONE,           // No magical effect
    CHAIN_ATTACK,   // The combo strike
    CRITICAL_HIT,   // The vital blow
    LIFE_STEAL,     // The essence drain
    ARMOR_BREAK,    // The shield shatterer
    COMBO_ENABLER,  // The sequence starter
    MULTI_STRIKE,   // The flurry of blows
    DOT            // The lasting wound
}
```

### 🗡️ Combat Techniques
Each technique in your arsenal carries these mystical properties:
```solidity
// The Warrior's Technique Scroll
struct CombatMove {
    string name;          // The technique's true name
    uint256 baseDamage;   // Raw power
    uint256 scalingFactor; // Power growth
    uint256 cooldown;      // Time between uses
    ActionType[] triggers; // Activation conditions
    uint256 minValue;      // Power requirement
    SpecialEffect effect;  // Magical enhancement
    uint256 effectValue;   // Enhancement power
    bool active;          // Ready for battle
}
```

### ⚡ The Battle Weave
The threads of combat are woven into this mystical pattern:
```solidity
// The Battle's Tapestry
struct BattleState {
    bytes32 targetId;        // The chosen foe
    uint256 remainingHealth; // Life force remaining
    uint256 battleStartTime; // When combat began
    bool isActive;          // Battle engaged?
    uint256 comboCount;     // Strike sequence
    mapping(SpecialEffect => uint256) activeEffects;   // Current enchantments
    mapping(SpecialEffect => uint256) effectEndTimes;  // Enchantment duration
}
```

## 📜 The Quest Compendium

### 🎯 Basic Trials
The fundamental challenges that test a hero's worth:
```solidity
// The Trial Scroll
struct QuestTemplate {
    uint8 requiredLevel;     // Experience threshold
    uint8 requiredStrength;  // Might requirement
    uint8 requiredAgility;   // Grace requirement
    uint8 requiredMagic;     // Arcane requirement
    uint256 rewardAmount;    // Promised bounty
    uint256 cooldown;        // Rest period
}
```

### 🤝 Fellowship Trials
Sacred missions that require the strength of many:
```solidity
// The Fellowship Scroll
struct TeamQuest {
    string name;           // Legend's title
    string description;    // Tale's description
    uint256 minTeamSize;  // Minimum companions
    uint256 maxTeamSize;  // Maximum companions
    uint256 targetValue;  // Victory condition
    uint256 duration;     // Time of trial
    uint256 teamReward;   // Shared bounty
    uint256 topReward;    // Champion's prize
    uint256 dropRateBonus; // Fortune's favor
    bool active;          // Available to heroes
}
```

### 🐉 Monster Hunts
Face the realm's most fearsome creatures:
```solidity
// The Bestiary Entry
struct Monster {
    string name;           // Creature's title
    uint256 level;        // Power level
    uint256 health;       // Life force
    uint256 damage;       // Attack might
    uint256 defense;      // Protective ward
    uint256 rewardBase;   // Base bounty
    bool isBoss;         // Legendary being?
    string[] requiredItems; // Required artifacts
    bool active;         // Currently huntable
}

// The Epic Battle Scroll
struct BossFight {
    bytes32 monsterId;     // The beast's mark
    uint256 startTime;     // Battle's beginning
    uint256 duration;      // Time of conflict
    uint256 totalDamage;   // Collective might
    uint256 participants;  // Brave warriors
    bool defeated;        // Victory achieved?
}
```

### ⏳ Temporal Trials
Challenges that flow with time's river:
```solidity
// The Daily Scroll
struct DailyQuest {
    string name;           // Challenge name
    string description;    // Sacred text
    uint256 baseReward;    // Base offering
    uint256 streakBonus;   // Loyalty reward
    uint256 maxStreakBonus; // Maximum blessing
    uint256 resetTime;     // Next dawn
    bool active;          // Available now?
}

// The Seasonal Prophecy
struct SeasonalQuest {
    string name;           // Season's title
    string description;    // Prophecy text
    uint256 startTime;     // Season's dawn
    uint256 endTime;       // Season's dusk
    uint256 targetValue;   // Victory condition
    uint256 baseReward;    // Base treasure
    uint256[] milestones;  // Achievement marks
    uint256[] bonuses;     // Special rewards
    bool active;          // Current season?
}
```

### 🌟 Protocol Trials
Mystical challenges in the DeFi realms:
```solidity
// The Protocol Scroll
struct ProtocolQuestTemplate {
    address protocol;        // Mystical gateway
    uint256 minInteractions; // Required rituals
    uint256 minVolume;       // Power threshold
    uint256 rewardAmount;    // Base bounty
    uint256 bonusRewardCap;  // Maximum blessing
    uint256 duration;        // Time of trial
    bool active;            // Available now?
}
```

## 🎨 Artifacts and Equipment
The tools of power that aid our heroes:
```solidity
// The Equipment Scroll
struct EquipmentSlots {
    uint256 weaponId;     // Chosen weapon
    uint256 armorId;      // Protective gear
}
```

## 🏪 The Mystical Marketplace
Where heroes trade their treasures:
```solidity
// The Merchant's Ledger
struct Listing {
    address seller;       // The merchant
    uint256 price;        // Required gold
}
```

*May these sacred texts guide you through your journey in the realm of DeFi. Remember, brave adventurer, that each structure and system here serves a greater purpose in your quest for glory and riches.* 🎮✨ 