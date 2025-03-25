# Quest Contract API Reference 📜

Welcome, quest master! Here lies the knowledge of creating and managing heroic challenges in our realm.

## Contract Setup 🏗️

### Constructor
```solidity
constructor(address characterContract)
```
Initializes the quest system with the character contract address.

**Parameters:**
- `characterContract`: Address of the Character contract

**Actions:**
- Sets up the character contract reference
- Grants DEFAULT_ADMIN_ROLE to deployer

### initialize
```solidity
function initialize(address _gameToken) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Sets up the game token contract for quest rewards.

**Parameters:**
- `_gameToken`: Address of the GameToken contract

**Requirements:**
- Can only be called once
- Caller must have DEFAULT_ADMIN_ROLE

## Core Functions 🗺️

### createQuest
```solidity
function createQuest(
    uint8 requiredLevel,
    uint8 requiredStrength,
    uint8 requiredAgility,
    uint8 requiredMagic,
    uint256 rewardAmount,
    uint256 cooldown
) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 questId)
```
Creates a new quest template for heroes to undertake.

**Parameters:**
- `requiredLevel`: Minimum level required
- `requiredStrength`: Minimum strength required
- `requiredAgility`: Minimum agility required
- `requiredMagic`: Minimum magic required
- `rewardAmount`: Amount of tokens rewarded upon completion
- `cooldown`: Time required between attempts (in seconds)

**Returns:**
- `questId`: Unique identifier for the quest

**Access:**
- Only accounts with DEFAULT_ADMIN_ROLE

**Example:**
```typescript
const questId = await quest.createQuest(
    1,      // Level 1 minimum
    10,     // 10 strength required
    8,      // 8 agility required
    5,      // 5 magic required
    100,    // 100 token reward
    3600    // 1 hour cooldown
);
```

### startQuest
```solidity
function startQuest(uint256 characterId, uint256 questId) external
```
Begins a quest for a specific character.

**Parameters:**
- `characterId`: The hero's unique identifier
- `questId`: The quest to undertake

**Requirements:**
- Character must meet stat requirements
- Quest must not be on cooldown
- Quest must not already be active
- Caller must be character owner or quest manager

**Events Emitted:**
- `QuestStarted(uint256 characterId, uint256 questId)`

**Example:**
```typescript
await quest.startQuest(characterId, questId);
```

### completeQuest
```solidity
function completeQuest(uint256 characterId, uint256 questId) external
```
Marks a quest as completed and distributes rewards.

**Parameters:**
- `characterId`: The hero's unique identifier
- `questId`: The quest being completed

**Requirements:**
- Quest must be active
- Caller must be character owner or quest manager

**Events Emitted:**
- `QuestCompleted(uint256 characterId, uint256 questId, uint256 reward)`

**Example:**
```typescript
await quest.completeQuest(characterId, questId);
```

## Contract References 🔗

### Character Contract
```solidity
ICharacter public immutable character
```
Reference to the Character contract for checking stats and ownership.

### Game Token Contract
```solidity
IGameToken public gameToken
```
Reference to the GameToken contract for distributing rewards.

## Quest Templates 📋

### QuestTemplate Structure
```solidity
struct QuestTemplate {
    uint8 requiredLevel;    // Minimum level needed
    uint8 requiredStrength; // Minimum strength needed
    uint8 requiredAgility;  // Minimum agility needed
    uint8 requiredMagic;    // Minimum magic needed
    uint256 rewardAmount;   // Tokens awarded on completion
    uint256 cooldown;       // Time between attempts
}
```

### Accessing Quest Details
```typescript
// Get quest template details
const template = await quest.questTemplates(questId);
console.log("Required Level:", template.requiredLevel);
console.log("Reward Amount:", template.rewardAmount);

// Check if quest is active
const isActive = await quest.activeQuests(questId);

// Check last completion time
const lastCompletion = await quest.lastQuestCompletionTime(characterId, questId);
```

## Events 📯

### QuestStarted
```solidity
event QuestStarted(uint256 indexed characterId, uint256 indexed questId)
```
Announces when a hero begins a quest.

### QuestCompleted
```solidity
event QuestCompleted(uint256 indexed characterId, uint256 indexed questId, uint256 reward)
```
Heralds a hero's successful quest completion.

## Access Control 🔒

### Roles
```solidity
bytes32 public constant QUEST_MANAGER_ROLE = keccak256("QUEST_MANAGER_ROLE")
bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00
```

The contract uses OpenZeppelin's AccessControl with two roles:
- DEFAULT_ADMIN_ROLE: Can create quests and manage roles
- QUEST_MANAGER_ROLE: Can manage quests on behalf of characters

### Modifiers
```solidity
modifier onlyCharacterOwnerOrManager(uint256 characterId)
```
Restricts function access to either:
- The owner of the character
- An address with QUEST_MANAGER_ROLE

## State Management 📊

### Quest State Tracking
```solidity
mapping(uint256 => QuestTemplate) public questTemplates
mapping(uint256 => mapping(uint256 => uint256)) public lastQuestCompletionTime
mapping(uint256 => bool) public activeQuests
```

- `questTemplates`: Stores quest requirements and rewards
- `lastQuestCompletionTime`: Tracks when each character last completed each quest
- `activeQuests`: Tracks which quests are currently active

## Error Messages 🚫

```solidity
"Already initialized"               // When trying to initialize twice
"Quest already active"             // When trying to start an active quest
"Quest does not exist"             // When quest template isn't found
"Quest on cooldown"                // When attempting too soon
"Insufficient strength"            // When strength requirement not met
"Insufficient agility"             // When agility requirement not met
"Insufficient magic"               // When magic requirement not met
"Quest not active"                 // When completing inactive quest
"Not character owner or manager"   // When unauthorized access
```

## Best Practices 💡

1. **Quest Creation**
   - Balance requirements with rewards
   - Set appropriate cooldowns
   - Consider level progression
   - Design quests for different character builds

2. **Quest Management**
   - Monitor active quests
   - Handle completion verification
   - Track reward distribution
   - Consider gas costs for reward distribution

3. **Error Handling**
   - Verify requirements before starting
   - Check quest status before actions
   - Handle cooldown periods
   - Validate contract initialization

## Usage Examples 🎮

### System Setup
```typescript
// Deploy quest contract
const quest = await Quest.deploy(characterContractAddress);

// Initialize with game token
await quest.initialize(gameTokenAddress);

// Grant quest manager role
await quest.grantRole(QUEST_MANAGER_ROLE, managerAddress);
```

### Creating a Beginner Quest
```typescript
// Create an easy starter quest
const beginnerQuestId = await quest.createQuest(
    1,      // Level 1
    5,      // Low strength requirement
    5,      // Low agility requirement
    5,      // Low magic requirement
    50,     // Small reward
    1800    // 30 minute cooldown
);
```

### Managing Quest Flow
```typescript
// Check character stats first
const [stats, equipment, state] = await character.getCharacter(characterId);

// Verify requirements
const template = await quest.questTemplates(questId);
if (stats.strength >= template.requiredStrength &&
    stats.agility >= template.requiredAgility &&
    stats.magic >= template.requiredMagic) {
    
    // Start quest if requirements met
    await quest.startQuest(characterId, questId);
    
    // ... time passes ...
    
    // Complete the quest
    await quest.completeQuest(characterId, questId);
    
    // Check cooldown before next attempt
    const lastCompletion = await quest.lastQuestCompletionTime(characterId, questId);
    const canStart = Date.now() >= lastCompletion + template.cooldown;
}
```

May your quests bring glory to brave heroes! 🗡️✨ 