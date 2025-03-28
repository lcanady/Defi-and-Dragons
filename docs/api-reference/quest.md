# Quest System API Reference 📜

Welcome, quest master! Here lies the knowledge of creating and managing heroic challenges across the various quest contracts in our realm.

## Overview

The quest system is modular, comprising several contracts:

- **`Quest.sol`**: The core contract managing quest templates, party/raid coordination, and objective tracking.
- **`CombatQuest.sol`**: Manages monster hunts and boss fights.
- **`SocialQuest.sol`**: Manages team-based quests and player referrals.
- **`TimeQuest.sol`**: Manages daily and seasonal quests with time-based bonuses.
- **`ProtocolQuest.sol`**: Manages quests requiring interaction with specific DeFi protocols.

---

## Core Quest Contract (`Quest.sol`)

Handles the fundamental structure of quests, including templates, objectives, and party/raid mechanics.

### Contract Setup & Roles

**Constructor:**
```solidity
constructor(address characterContract, address partyContract_)
```
Initializes with Character and Party contract addresses. Grants `DEFAULT_ADMIN_ROLE` to deployer.

**Initialize:**
```solidity
function initialize(address _gameToken) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Sets the GameToken contract address (callable once).

**Roles:**
- `DEFAULT_ADMIN_ROLE (0x00)`: Can create quests, manage roles, initialize.
- `QUEST_MANAGER_ROLE`: Can manage quests on behalf of characters (e.g., start/update progress).
- `QUEST_VALIDATOR_ROLE`: Can validate quest completion (implementation specific, potentially used by other quest contracts).

**Access Modifiers:**
- `onlyRole(bytes32 role)`: Standard OpenZeppelin role check.
- `onlyCharacterOwnerOrManager(uint256 characterId)`: Requires caller to be character owner or have `QUEST_MANAGER_ROLE`.

### Core Functions

**createQuest:**
```solidity
function createQuest(
    uint8 requiredLevel,
    uint8 requiredStrength,
    uint8 requiredAgility,
    uint8 requiredMagic,
    uint128 rewardAmount,
    uint32 cooldown,
    bool supportsParty,
    uint8 maxPartySize,
    uint8 partyBonusPercent,
    bool isRaid,
    uint8 maxParties,
    QuestType questType,
    QuestObjective[] calldata objectives
) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 questId)
```
Creates a new quest template.
- `questId` is generated via keccak256.
- `objectives` define specific goals (see Structs).
- `partyBonusPercent` is bonus % for *full* party completion.
- Raids require `supportsParty=true`.

**startQuest:**
```solidity
function startQuest(
    uint256 characterId, // Character initiating the start
    uint256 questId,
    bytes32 partyId // Optional: Party ID if starting as a party
) external onlyCharacterOwnerOrManager(characterId)
```
Starts a quest instance.
- Handles solo starts (partyId = 0).
- Handles party starts: verifies party ownership, size, member requirements, cooldowns, builds participation mask.
- Handles raid starts: checks raid limits, requires party.
- Emits `PartyJoinedQuest` or potentially `QuestStarted` (check contract for specific solo emit).

**updateQuestProgress:**
```solidity
function updateQuestProgress(
    uint256 questId,
    bytes32 partyId,
    bytes32 objectiveType,
    uint128 progressAmount
) external // Access control likely via specific quest type contracts or roles
```
Updates progress towards a specific objective for a party.
- Emits `QuestProgressUpdated`.
- Checks for completion via `_checkAndCompleteQuest`.

**completeQuest:**
```solidity
function completeQuest(
    uint256 questId,
    bytes32 partyId
) external onlyRole(QUEST_VALIDATOR_ROLE)
```
Marks a party\'s quest as complete and distributes rewards.
- Called when objectives met (often internally via `_checkAndCompleteQuest`).
- Calculates party bonus if applicable.
- Handles raid reward distribution.
- Updates `lastQuestCompletionTime` for members.
- Emits `QuestCompleted` and potentially `RaidReward`.

### View Functions

**getQuestTemplate:**
```solidity
function getQuestTemplate(uint256 questId) external view returns (QuestTemplate memory)
```
Returns the template details for a given quest ID.

**getQuestProgress:**
```solidity
function getQuestProgress(
    uint256 questId,
    bytes32 partyId,
    bytes32 objectiveType
) external view returns (uint128)
```
Returns the current progress for a specific party objective.

**canStartQuest:**
```solidity
function canStartQuest(
    uint256 characterId,
    uint256 questId,
    bytes32 partyId
) external view returns (bool, string memory)
```
Checks if a character/party meets all requirements to start a quest (stats, cooldowns, etc.). Returns boolean and reason string if false.

### Structs

**QuestTemplate:**
```solidity
struct QuestTemplate {
    uint8 requiredLevel;
    uint8 requiredStrength;
    uint8 requiredAgility;
    uint8 requiredMagic;
    uint128 rewardAmount; // Base reward
    uint32 cooldown; // Seconds between attempts per character
    bool supportsParty;
    uint8 maxPartySize;
    uint8 partyBonusPercent; // For full party
    bool isRaid;
    uint8 maxParties; // For raids
    QuestType questType; // Enum: COMBAT, SOCIAL, ACHIEVEMENT, PROTOCOL, TIME
    QuestObjective[] objectives;
}
```

**QuestObjective:**
```solidity
struct QuestObjective {
    uint128 targetValue; // Goal value
    // currentValue is tracked in ActiveQuest mapping
    bytes32 objectiveType; // Type ID (e.g., KILLS, DAMAGE_DEALT)
}
```
*(Objective types like `KILLS`, `DAMAGE_DEALT`, `TRADES_MADE`, `ITEMS_COLLECTED`, `LIQUIDITY_PROVIDED`, `TIME_SPENT`, `COMBAT_COMPLETED` are defined as `bytes32` constants)*

**ActiveQuest:** (Internal structure accessed via mappings)
```solidity
struct ActiveQuest {
    bool isActive;
    bytes32[] activeParties;
    mapping(address => bool) participatingWallets;
    mapping(bytes32 => mapping(bytes32 => uint128)) partyProgress; // partyId => objectiveType => progress
    mapping(bytes32 => uint256) partyMemberMask; // partyId => bitmask of member IDs
}
```

### Events

- `QuestProgressUpdated(uint256 indexed questId, bytes32 indexed partyId, bytes32 objectiveType, uint128 progress)`
- `QuestStarted(uint256 indexed questId, bytes32[] parties)`
- `PartyJoinedQuest(uint256 indexed questId, bytes32 indexed partyId)`
- `QuestCompleted(uint256 indexed questId, bytes32[] parties, uint128 reward)`
- `RaidReward(address indexed wallet, uint256 indexed questId, uint128 reward)`

---

## Combat Quests (`CombatQuest.sol`)

Manages monster definitions, boss fights, and hunting quests.

### Setup

**Constructor:**
```solidity
constructor(
    address initialOwner,
    address _character,
    address _gameToken,
    address _abilities, // CombatAbilities contract
    address _itemDrop, // ItemDrop contract
    address _damageCalculator // CombatDamageCalculator contract
)
```

### Monster/Boss Management

**createMonster:**
```solidity
function createMonster(
    string calldata name,
    uint32 level,
    uint128 health,
    uint32 damage,
    uint32 defense,
    uint32 rewardBase,
    bool isBoss,
    string[] calldata requiredItems // Currently unused check
) external onlyOwner returns (bytes32 monsterId)
```
Defines a new monster or boss. `monsterId` generated via keccak256.

**startBossFight:**
```solidity
function startBossFight(bytes32 monsterId, uint40 duration) external onlyOwner returns (bytes32 fightId)
```
Initiates a boss fight instance. Requires `monsterId` to be an active boss.

**attackBoss:**
```solidity
function attackBoss(bytes32 fightId, uint256 characterId, bytes32 abilityId) external nonReentrant
```
Allows a character (owner must call) to attack an active boss within the duration.
- Calculates damage via `CombatDamageCalculator`.
- Applies ability effects (`CombatAbilities`).
- Records damage dealt (`damageDealt` mapping).
- Updates participant count/list.
- Triggers boss counter-attack (`useRandomBossAbility`).
- Checks for boss defeat (`defeatBoss`).
- Requires `COMBAT_COOLDOWN` to have passed (`canFight`).
- Emits `BossDamageDealt`.

**defeatBoss:** (Internal)
Called when boss health reaches zero during `attackBoss`.
- Calculates total reward based on base reward + participant bonus.
- Distributes rewards proportionally to damage dealt.
- Emits `BossDefeated`.

**toggleMonsterActive:**
```solidity
function toggleMonsterActive(bytes32 monsterId) external onlyOwner
```
Toggles the active status of a monster/boss.

### Hunts

**createHunt:**
```solidity
function createHunt(
    bytes32 monsterId,
    uint32 count, // Number of monsters to slay
    uint40 timeLimit, // Time limit in seconds
    uint32 bonusReward // Bonus for completing within time limit
) external onlyOwner returns (bytes32 huntId)
```
Creates a repeatable hunt quest template.

**startHunt:**
```solidity
function startHunt(bytes32 huntId, uint256 characterId) external nonReentrant
```
Starts a hunt instance for a character (owner must call).
- Requires `COMBAT_COOLDOWN` to have passed.
- Emits `HuntStarted`.

**recordMonsterSlain:**
```solidity
function recordMonsterSlain(bytes32 huntId, uint256 characterId, bytes32 monsterId) external // Likely restricted access
```
Records progress for a hunt.
- Checks if `monsterId` matches the hunt.
- Checks time limit.
- Mints base reward per kill.
- Checks for completion (`completeHunt`).
- Emits `MonsterSlain`.

**completeHunt:** (Internal)
Called when required kill count is met in `recordMonsterSlain`.
- Mints bonus reward if within time limit.
- Emits `HuntCompleted`.

### Abilities & Loot

**setMonsterAbilities:**
```solidity
function setMonsterAbilities(bytes32 monsterId, bytes32[] calldata abilityIds, uint32[] calldata weights) external onlyOwner
```
Assigns weighted abilities (from `CombatAbilities`) to a monster.

**setLootTable:**
```solidity
function setLootTable(
    bytes32 monsterId,
    uint256[] calldata itemIds,
    uint32[] calldata weights,
    uint16 dropChance, // Base chance (0-10000 = 0-100%)
    uint16 dropRateBonus // Bonus modifier (0-10000 = 0-100%)
) external onlyOwner
```
Defines potential item drops for a monster.

### View Functions

- `getMonster(bytes32 monsterId)`
- `getBossFight(bytes32 fightId)`
- `getHunt(bytes32 huntId)`
- `getHuntProgress(bytes32 huntId, uint256 characterId)`
- `getDamageDealt(bytes32 fightId, uint256 characterId)`
- `canFight(uint256 characterId)`: Checks `COMBAT_COOLDOWN`.

### Structs

**Monster:** (See `docs/gameplay/index.md`)
**PackedBossFight:** (See `docs/gameplay/index.md`)
**PackedHunt:**
```solidity
struct PackedHunt {
    bytes32 monsterId;
    uint32 count; // Target kill count
    uint40 timeLimit; // Seconds
    uint32 bonusReward; // For completion within timeLimit
    bool active;
}
```
**PackedHuntProgress:**
```solidity
struct PackedHuntProgress {
    uint40 startTime;
    uint32 monstersSlain;
    bool completed;
}
```
**MonsterAbility:**
```solidity
struct MonsterAbility {
    bytes32[] abilityIds; // From CombatAbilities
    uint32[] weights;
    uint32 totalWeight;
}
```
**LootTable:**
```solidity
struct LootTable {
    uint256[] itemIds; // From Equipment
    uint32[] weights;
    uint32 totalWeight;
    uint16 dropChance; // 0-10000
    uint16 dropRateBonus; // 0-10000
}
```

### Events

- `MonsterCreated(bytes32 indexed id, string name, bool isBoss)`
- `BossFightStarted(bytes32 indexed fightId, bytes32 indexed monsterId, uint40 startTime)`
- `BossDamageDealt(bytes32 indexed fightId, uint256 indexed characterId, uint128 damage)`
- `BossDefeated(bytes32 indexed fightId, uint128 totalDamage, uint16 participants)`
- `HuntCreated(bytes32 indexed id, bytes32 indexed monsterId, uint32 count)`
- `HuntStarted(bytes32 indexed huntId, uint256 indexed characterId)`
- `MonsterSlain(bytes32 indexed huntId, uint256 indexed characterId, uint32 reward)`
- `HuntCompleted(bytes32 indexed huntId, uint256 indexed characterId, uint32 totalReward)`
- `AbilityUsed(bytes32 indexed monsterId, bytes32 indexed abilityId, uint256 indexed targetId)`
- `LootDropped(bytes32 indexed monsterId, uint256 indexed characterId, uint256 itemId)`
- `MonsterToggled(bytes32 indexed monsterId, bool active)`

---

## Social Quests (`SocialQuest.sol`)

Manages team-based quests and referral programs.

### Setup

**Constructor:**
```solidity
constructor(address _character, address _gameToken, address _itemDrop)
```

**setApprovedTracker:**
```solidity
function setApprovedTracker(address tracker, bool approved) external onlyOwner
```
Grants an address permission to record contribution/progress.

### Team Quests

**createTeamQuest:**
```solidity
function createTeamQuest(
    string calldata name,
    string calldata description,
    uint32 minTeamSize,
    uint32 maxTeamSize,
    uint128 targetValue, // e.g., total contribution goal
    uint32 duration, // Seconds
    uint128 teamReward, // Base reward split among team
    uint128 topReward, // Bonus for top contributor
    uint32 dropRateBonus // Item drop bonus multiplier
) external onlyOwner returns (bytes32 questId)
```
Defines a new team quest. `questId` generated via keccak256.

**formTeam:**
```solidity
function formTeam(bytes32 questId, uint256[] calldata memberIds) external nonReentrant
```
Forms a team for a quest. Caller must own all characters.
- Checks min/max size, character availability.
- Creates team state (`Team` struct).
- Records members in `memberTeams` mapping.
- Emits `TeamFormed`.

**recordContribution:**
```solidity
function recordContribution(bytes32 questId, uint256 characterId, uint128 value) external
```
Records a character\'s contribution to their team quest.
- Requires caller to be owner or an `approvedTracker`.
- Checks if character is in a team for this quest.
- Checks expiry and completion status.
- Updates `contributions` and `totalValue` in `Team` struct.
- Emits `ContributionRecorded`.
- Checks for completion (`completeTeamQuest`).

**completeTeamQuest:** (Internal)
Called when `totalValue` reaches `targetValue` during `recordContribution`.
- Finds top contributor.
- Calculates base reward per member.
- Distributes rewards (base + top bonus if applicable) via `gameToken.mint`.
- Requests item drops via `itemDrop.requestRandomDrop`.
- Marks team as completed.
- Emits `TeamQuestCompleted`.

### Referral Quests

**createReferralQuest:**
```solidity
function createReferralQuest(
    string calldata name,
    uint128 referrerReward,
    uint128 referreeReward,
    uint32 requiredLevel, // Level referree must reach
    uint32 duration // Time limit in seconds
) external onlyOwner returns (bytes32 questId)
```
Defines a referral program.

**registerReferral:**
```solidity
function registerReferral(bytes32 questId, uint256 referrerId, uint256 referreeId) external nonReentrant
```
Registers a referral link (caller must own `referrerId`).
- Requires `referrerId` and `referreeId` to be different.
- Cannot register if already referred for this quest.
- Emits `ReferralRegistered`.

**completeReferralQuest:**
```solidity
function completeReferralQuest(bytes32 questId, uint256 referreeId) external nonReentrant
```
Called (likely by an approved system) when a referred character reaches the required level.
- Verifies referral exists and is within duration.
- Verifies `referreeId` level using `character.getCharacter`.
- Distributes rewards to referrer and referree.
- Emits `ReferralCompleted`.

### View Functions

- `getTeamQuest(bytes32 questId)`
- `getTeam(bytes32 teamId)`
- `getMemberTeam(bytes32 questId, uint256 characterId)`
- `getReferralQuest(bytes32 questId)`
- `getReferralStatus(bytes32 questId, uint256 referrerId, uint256 referreeId)`

### Structs

**TeamQuest:** (See `docs/gameplay/index.md`)
**Team:**
```solidity
struct Team {
    uint256[] memberIds; // Character IDs
    uint64 startTime;
    uint128 totalValue; // Total contribution
    bool completed;
    mapping(uint256 => uint128) contributions; // memberId => contribution
}
```
**ReferralQuest:**
```solidity
struct ReferralQuest {
    string name;
    uint128 referrerReward;
    uint128 referreeReward;
    uint32 requiredLevel;
    uint32 duration; // Seconds
    bool active;
}
```

### Events

- `TeamQuestCreated(bytes32 indexed id, string name, uint128 teamReward)`
- `TeamFormed(bytes32 indexed questId, bytes32 indexed teamId, uint256[] members)`
- `ContributionRecorded(bytes32 indexed questId, bytes32 indexed teamId, uint256 indexed characterId, uint128 amount)`
- `TeamQuestCompleted(bytes32 indexed questId, bytes32 indexed teamId, uint128 totalReward)`
- `ReferralQuestCreated(bytes32 indexed id, string name)`
- `ReferralRegistered(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId)`
- `ReferralCompleted(uint256 indexed referrer, uint256 indexed referree, bytes32 indexed questId)`

---

## Time Quests (`TimeQuest.sol`)

Manages daily and seasonal quests with time-based modifiers.

### Setup

**Constructor:**
```solidity
constructor(address _character, address _gameToken)
```

**setApprovedTracker:** (Not explicitly in snippet, but likely needed for `updateSeasonalProgress`)
```solidity
// function setApprovedTracker(address tracker, bool approved) external onlyOwner
```

### Daily Quests

**createDailyQuest:**
```solidity
function createDailyQuest(
    string calldata name,
    string calldata description,
    uint256 baseReward,
    uint256 streakBonus, // Added per consecutive day
    uint256 maxStreakBonus,
    uint256 resetTime // Seconds into day (e.g., 0 for midnight UTC)
) external onlyOwner returns (bytes32 questId)
```
Defines a repeatable daily quest.

**completeDailyQuest:**
```solidity
function completeDailyQuest(bytes32 questId, uint256 characterId) external nonReentrant
```
Marks a daily quest as completed for the day (caller must own character).
- Checks if already completed since last `resetTime`.
- Calculates streak and applies `streakBonus` (up to `maxStreakBonus`).
- Applies time bonus via `applyTimeBonus`.
- Mints total reward.
- Updates `lastCompletion` and `currentStreak`.
- Emits `DailyQuestCompleted`.

### Seasonal Quests

**createSeasonalQuest:**
```solidity
function createSeasonalQuest(
    string calldata name,
    string calldata description,
    uint256 startTime,
    uint256 duration,
    uint256 targetValue, // Overall goal for the season
    uint256 baseReward, // Reward for reaching targetValue
    uint256[] calldata milestones, // Intermediate progress points
    uint256[] calldata bonuses // Rewards for reaching milestones
) external onlyOwner returns (bytes32 questId)
```
Defines a quest running for a specific season.

**updateSeasonalProgress:**
```solidity
function updateSeasonalProgress(bytes32 questId, uint256 characterId, uint256 progress) external // Requires owner or approved tracker
```
Updates a character\'s progress towards the seasonal target.
- Checks if quest is active and within `startTime`/`endTime`.
- Updates `seasonalProgress`.
- Checks for milestone completion, distributes milestone bonuses, and emits `MilestoneReached`.
- Checks for overall completion (`completeSeasonalQuest`).
- Emits `SeasonalProgressUpdated`.

**completeSeasonalQuest:** (Internal)
Called when `seasonalProgress` reaches `targetValue` during `updateSeasonalProgress`.
- Applies time bonus via `applyTimeBonus` to `baseReward`.
- Mints final reward.
- Emits `SeasonalQuestCompleted`.

### Bonus Time Windows

**addBonusWindow:**
```solidity
function addBonusWindow(bytes32 questId, uint256 startTime, uint256 endTime, uint256 multiplier) external onlyOwner
```
Adds a time period where rewards for a specific quest (`questId` can be daily or seasonal) are multiplied.
- `multiplier` is in basis points (100 = 1x, 150 = 1.5x).

**applyTimeBonus:** (Internal/View)
```solidity
function applyTimeBonus(bytes32 questId, uint256 baseAmount) public view returns (uint256)
```
Calculates the reward amount including the highest active bonus window multiplier.

### View Functions

- `getDailyQuest(bytes32 questId)`
- `getSeasonalQuest(bytes32 questId)`
- `getUserProgress(bytes32 questId, uint256 characterId)`
- `getLastResetTime(uint256 resetTime)`: Calculates previous reset timestamp.

### Structs

**DailyQuest:** (See `docs/gameplay/index.md`)
**SeasonalQuest:** (See `docs/gameplay/index.md`)
**TimeWindow:**
```solidity
struct TimeWindow {
    uint256 startTime;
    uint256 endTime;
    uint256 multiplier; // Basis points (100 = 1x)
}
```
**UserProgress:**
```solidity
struct UserProgress {
    uint256 lastCompletion; // Timestamp for daily
    uint256 currentStreak; // For daily
    uint256 bestStreak; // For daily
    uint256 seasonalProgress; // For seasonal
    uint256 milestone; // Index of last achieved milestone for seasonal
}
```

### Events

- `DailyQuestCreated(bytes32 indexed id, string name)`
- `SeasonalQuestCreated(bytes32 indexed id, string name, uint256 startTime, uint256 endTime)`
- `BonusWindowAdded(bytes32 indexed questId, uint256 startTime, uint256 endTime, uint256 multiplier)`
- `DailyQuestCompleted(bytes32 indexed questId, uint256 indexed characterId, uint256 reward, uint256 streak)`
- `SeasonalProgressUpdated(bytes32 indexed questId, uint256 indexed characterId, uint256 progress)`
- `SeasonalQuestCompleted(bytes32 indexed questId, uint256 indexed characterId, uint256 reward)`
- `MilestoneReached(bytes32 indexed questId, uint256 indexed characterId, uint256 milestone, uint256 bonus)`

---

## Protocol Quests (`ProtocolQuest.sol`)

Manages quests requiring interaction with specific (approved) external protocols.

### Setup

**Constructor:**
```solidity
constructor(address _character, address _gameToken, address _questContract) // _questContract likely refers to the core Quest.sol
```

**setProtocolApproval:**
```solidity
function setProtocolApproval(address protocol, bool approved) external onlyOwner
```
Approves or disapproves an external protocol contract address, allowing it to record interactions.

### Quest Management

**createProtocolQuest:**
```solidity
function createProtocolQuest(
    address protocol, // Approved protocol address
    uint32 minInteractions, // Min calls to recordInteraction
    uint128 minVolume, // Min total volume across interactions
    uint128 rewardAmount, // Base reward
    uint128 bonusRewardCap, // Max bonus based on excess volume
    uint32 duration // Seconds to complete
) external onlyOwner returns (uint256 questId)
```
Defines a quest linked to an approved protocol.

**startQuest:**
```solidity
function startQuest(uint256 characterId, uint256 questId) external nonReentrant
```
Starts the quest for a character (caller must own character).
- Records `startTime`.
- Emits `ProtocolQuestStarted`.

**recordInteraction:**
```solidity
function recordInteraction(uint256 characterId, uint256 questId, uint128 volume) external nonReentrant
```
Called *by the approved protocol* (`msg.sender == quest.protocol`) to record an interaction.
- Checks if quest is active and within duration.
- Increments `interactionCount` and adds to `volumeTraded`.
- Emits `ProtocolInteractionRecorded`.
- Checks for completion (`canCompleteQuest` and `completeQuest`).

**completeQuest:**
```solidity
function completeQuest(uint256 characterId, uint256 questId) public nonReentrant
```
Completes the quest if requirements met (caller must own character).
- Can be called directly if `canCompleteQuest` is true, or is called internally by `recordInteraction`.
- Calculates bonus reward based on excess volume (up to `bonusRewardCap`).
- Mints total reward.
- Marks quest as completed.
- Emits `ProtocolQuestCompleted`.

### View Functions

**getQuestTemplate(uint256 questId)**
**getUserProgress(uint256 questId, uint256 characterId)**
**canCompleteQuest(uint256 characterId, uint256 questId)**

### Structs

**ProtocolQuestTemplate:** (See `docs/gameplay/index.md`)
**UserQuestProgress:**
```solidity
struct UserQuestProgress {
    uint64 startTime;
    uint32 interactionCount;
    uint128 volumeTraded;
    bool completed;
}
```

### Events

- `ProtocolQuestCreated(uint256 indexed questId, address protocol, uint128 rewardAmount)`
- `ProtocolQuestStarted(uint256 indexed questId, uint256 indexed characterId)`
- `ProtocolQuestCompleted(uint256 indexed questId, uint256 indexed characterId, uint128 reward)`
- `ProtocolInteractionRecorded(uint256 indexed questId, uint256 indexed characterId, uint128 volume)`
- `ProtocolApprovalUpdated(address indexed protocol, bool approved)`

---

*May these scrolls guide you in crafting epic adventures!* 🗺️✨ 