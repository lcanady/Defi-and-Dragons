# 📜 The Sacred Contract: Interface Specifications

*These hallowed scrolls detail the exact incantations needed to communicate with each mystical contract in our realm.*

## Core Interfaces 🔮

### IGameFacade

The central gateway to all realms of interaction:

```solidity
/**
 * @title IGameFacade
 * @notice The grand gateway to all gameplay interactions
 * @dev Simplifies complex multi-contract operations
 */
interface IGameFacade {
    /**
     * @notice Creates a new character with specified stats and alignment
     * @param stats Initial character attributes
     * @param alignment Character's chosen path (STRENGTH, AGILITY, or MAGIC)
     * @return uint256 The ID of the newly created character
     */
    function createCharacter(
        Types.Stats memory stats, 
        Types.Alignment alignment
    ) external returns (uint256);
    
    /**
     * @notice Equips items to a character
     * @param characterId The character to equip items to
     * @param weaponId The weapon to equip
     * @param armorId The armor to equip
     */
    function equipItems(
        uint256 characterId, 
        uint256 weaponId, 
        uint256 armorId
    ) external;
    
    /**
     * @notice Removes equipment from a character
     * @param characterId The character to unequip items from
     * @param weapon Whether to unequip the weapon
     * @param armor Whether to unequip the armor
     */
    function unequipItems(
        uint256 characterId, 
        bool weapon, 
        bool armor
    ) external;
    
    /**
     * @notice Begins a quest for a character
     * @param characterId The character embarking on the quest
     * @param questId The ID of the quest to begin
     */
    function startQuest(
        uint256 characterId, 
        uint256 questId
    ) external;
    
    /**
     * @notice Completes a quest and claims rewards
     * @param characterId The character completing the quest
     * @param questId The ID of the quest being completed
     */
    function completeQuest(
        uint256 characterId, 
        uint256 questId
    ) external;
    
    /**
     * @notice Requests a random equipment drop
     * @param dropRateBonus Optional bonus to increase drop chances
     * @return uint256 Request ID for the drop
     */
    function requestRandomDrop(
        uint256 dropRateBonus
    ) external returns (uint256);
    
    /**
     * @notice Lists an item for sale in the marketplace
     * @param equipmentId ID of the equipment to sell
     * @param price Price in GOLD tokens
     * @param amount Number of items to sell
     */
    function listItem(
        uint256 equipmentId, 
        uint256 price, 
        uint256 amount
    ) external;
    
    /**
     * @notice Purchases an item from the marketplace
     * @param equipmentId ID of the equipment to buy
     * @param listingId ID of the specific listing
     * @param amount Number of items to purchase
     */
    function purchaseItem(
        uint256 equipmentId, 
        uint256 listingId, 
        uint256 amount
    ) external;
    
    /**
     * @notice Performs a batch operation to equip items and start a quest
     * @param characterId The character to equip and send on quest
     * @param weaponId The weapon to equip
     * @param armorId The armor to equip
     * @param questId The quest to start
     */
    function batchEquipAndStartQuest(
        uint256 characterId,
        uint256 weaponId,
        uint256 armorId,
        uint256 questId
    ) external;
    
    /**
     * @notice Records a DeFi action which may trigger combat moves
     * @param characterId The character performing the action
     * @param actionType The type of DeFi action performed
     * @param actionValue The value or amount involved in the action
     */
    function recordAction(
        uint256 characterId,
        Types.ActionType actionType,
        uint256 actionValue
    ) external;
    
    /** 
     * @notice Emitted when a random drop is received
     * @param requestId The original request ID
     * @param recipient Address receiving the drop
     * @param itemId ID of the dropped item
     */
    event DropReceived(
        uint256 indexed requestId,
        address indexed recipient,
        uint256 itemId
    );
}
```

### ICharacter

The contract that manages hero existence and attributes:

```solidity
/**
 * @title ICharacter
 * @notice Manages character NFTs and their attributes
 * @dev Inherits from ERC721 for NFT functionality
 */
interface ICharacter {
    /**
     * @notice Creates a new character NFT
     * @param to Address to mint the character to
     * @param stats Initial character attributes
     * @param alignment Character's chosen path
     * @return uint256 The ID of the newly created character
     */
    function mintCharacter(
        address to,
        Types.Stats memory stats,
        Types.Alignment alignment
    ) external returns (uint256);
    
    /**
     * @notice Retrieves complete information about a character
     * @param characterId The ID of the character to query
     * @return stats Character's attribute stats
     * @return equipment Character's equipped items
     * @return state Character's current state
     */
    function getCharacter(uint256 characterId) external view returns (
        Types.Stats memory stats,
        Types.EquipmentSlots memory equipment,
        Types.CharacterState memory state
    );
    
    /**
     * @notice Equips items to a character
     * @param characterId The character to equip items to
     * @param weaponId The weapon to equip
     * @param armorId The armor to equip
     */
    function equip(
        uint256 characterId,
        uint256 weaponId,
        uint256 armorId
    ) external;
    
    /**
     * @notice Removes equipment from a character
     * @param characterId The character to unequip items from
     * @param weapon Whether to unequip the weapon
     * @param armor Whether to unequip the armor
     */
    function unequip(
        uint256 characterId,
        bool weapon,
        bool armor
    ) external;
    
    /**
     * @notice Gets the wallet associated with a character
     * @param characterId The character ID to query
     * @return CharacterWallet The character's equipment wallet
     */
    function characterWallets(uint256 characterId) external view returns (address);
    
    /**
     * @notice Emitted when a new character is created
     * @param tokenId The ID of the created character
     * @param owner The owner of the character
     * @param wallet The character's equipment wallet
     */
    event CharacterCreated(
        uint256 indexed tokenId,
        address indexed owner,
        address wallet
    );
    
    /**
     * @notice Emitted when a character changes equipment
     * @param tokenId The ID of the character
     * @param weaponId The ID of the equipped weapon (0 if none)
     * @param armorId The ID of the equipped armor (0 if none)
     */
    event EquipmentChanged(
        uint256 indexed tokenId,
        uint256 weaponId,
        uint256 armorId
    );
}
```

## Common Structs and Enums 🧩

The mystical structures that form our world's foundation:

```solidity
/**
 * @title Types
 * @notice Common data structures used throughout the system
 */
library Types {
    /**
     * @notice Character attributes
     * @dev Packed into a single storage slot (3 bytes)
     */
    struct Stats {
        uint8 strength;  // Physical might
        uint8 agility;   // Speed and precision 
        uint8 magic;     // Arcane power
    }
    
    /**
     * @notice Character's equipped items
     */
    struct EquipmentSlots {
        uint256 weaponId;  // Equipped weapon (0 if none)
        uint256 armorId;   // Equipped armor (0 if none)
    }
    
    /**
     * @notice Character's current state
     */
    struct CharacterState {
        uint256 level;          // Current level
        uint256 experience;     // Total experience
        uint256 questId;        // Active quest (0 if none)
        uint256 questStartTime; // When quest began (0 if none)
        bool inBattle;          // Currently in combat?
    }
    
    /**
     * @notice Character's alignment/class
     */
    enum Alignment {
        NONE,      // Invalid state
        STRENGTH,  // Warrior type
        AGILITY,   // Rogue type
        MAGIC      // Mage type
    }
    
    /**
     * @notice Equipment types
     */
    enum EquipmentType {
        NONE,    // Invalid
        WEAPON,  // Offensive
        ARMOR    // Defensive
    }
    
    /**
     * @notice Item rarity levels
     */
    enum Rarity {
        COMMON,    // Basic items
        UNCOMMON,  // Slightly enhanced
        RARE,      // Powerful items
        EPIC,      // Very powerful items
        LEGENDARY  // Extraordinary items
    }
    
    /**
     * @notice DeFi action types that can trigger combat moves
     */
    enum ActionType {
        NONE,             // Invalid
        TRADE,            // DEX trading
        YIELD_FARM,       // Staking/farming
        GOVERNANCE_VOTE,  // DAO voting
        BRIDGE_TOKENS,    // Cross-chain transfers
        FLASH_LOAN,       // Flash loan usage
        NFT_TRADE,        // NFT transactions
        CREATE_PROPOSAL,  // DAO proposals
        DELEGATE          // Delegation actions
    }
    
    /**
     * @notice Combat effects
     */
    enum SpecialEffect {
        NONE,           // No effect
        CHAIN_ATTACK,   // Multiple strikes
        CRITICAL_HIT,   // Increased damage
        LIFE_STEAL,     // Heal on hit
        ARMOR_BREAK,    // Reduce defense
        COMBO_ENABLER,  // Enable combos
        MULTI_STRIKE,   // Hit multiple targets
        DOT             // Damage over time
    }
}
```

## Detailed Error Codes 🚫

The mystical disruptions that may occur during ritual casting:

```solidity
/**
 * @title IGameErrors
 * @notice Custom errors used throughout the system
 * @dev Uses custom errors for gas efficiency
 */
interface IGameErrors {
    /**
     * @notice Thrown when an action is attempted by an unauthorized address
     * @dev Usually indicates the caller is not the owner of a resource
     */
    error NotAuthorized();
    
    /**
     * @notice Thrown when token balance is insufficient
     * @dev Used for GOLD tokens, LP tokens, or other currency checks
     */ 
    error InsufficientBalance();
    
    /**
     * @notice Thrown when function parameters are invalid
     * @dev Used for general validation failures
     */
    error InvalidParameters();
    
    /**
     * @notice Thrown when attempting to interact with an inactive quest
     * @dev Quests must be active to start or interact with them
     */
    error QuestNotActive();
    
    /**
     * @notice Thrown when attempting to complete a quest multiple times
     * @dev Each quest can only be completed once per character
     */
    error QuestAlreadyCompleted();
    
    /**
     * @notice Thrown when an item is not available for purchase or equipping
     * @dev Item may not exist or may not be for sale
     */
    error ItemNotAvailable();
    
    /**
     * @notice Thrown when a character's level is too low
     * @dev Used for quest, equipment, or feature level requirements
     */
    error InsufficientLevel();
    
    /**
     * @notice Thrown when an action is attempted during cooldown
     * @dev Cooldowns prevent action spamming
     */
    error CooldownActive();
    
    /**
     * @notice Thrown when character requirements aren't met
     * @dev Used for stat requirements on quests or equipment
     * @param requiredStrength Minimum strength needed
     * @param requiredAgility Minimum agility needed
     * @param requiredMagic Minimum magic needed
     * @param characterId ID of the character that failed requirements
     */
    error InsufficientStats(
        uint8 requiredStrength,
        uint8 requiredAgility,
        uint8 requiredMagic,
        uint256 characterId
    );
    
    /**
     * @notice Thrown when a quest cannot be completed
     * @dev Usually means quest requirements haven't been met
     * @param questId ID of the quest
     * @param characterId ID of the character
     * @param reason String explanation of failure
     */
    error QuestCompletionFailed(
        uint256 questId,
        uint256 characterId,
        string reason
    );
    
    /**
     * @notice Thrown when equipment type doesn't match slot
     * @dev Equipment must be of correct type for its slot
     * @param equipmentId ID of the equipment
     * @param requestedType Type that was expected
     * @param actualType Actual type of the equipment
     */
    error InvalidEquipmentType(
        uint256 equipmentId,
        Types.EquipmentType requestedType,
        Types.EquipmentType actualType
    );
    
    /**
     * @notice Thrown when blockchain state doesn't allow an operation
     * @dev Used for timing-related issues
     */
    error InvalidState();
}
```

## Event Specifications 📣

The mystical proclamations that echo through the realm:

```solidity
/**
 * @notice Core events emitted by the system
 * @dev Events provide an audit trail and enable off-chain listeners
 */

// Character Events
/**
 * @notice Emitted when a character gains experience
 * @param characterId The character gaining experience
 * @param amount Amount of experience gained
 * @param newTotal New total experience value
 */
event ExperienceGained(
    uint256 indexed characterId,
    uint256 amount,
    uint256 newTotal
);

/**
 * @notice Emitted when a character levels up
 * @param characterId The character leveling up
 * @param oldLevel Previous level
 * @param newLevel New level
 */
event LevelUp(
    uint256 indexed characterId,
    uint256 oldLevel,
    uint256 newLevel
);

// Quest Events
/**
 * @notice Emitted when a quest is started
 * @param characterId Character starting the quest
 * @param questId ID of the quest
 * @param startTime Timestamp when quest began
 */
event QuestStarted(
    uint256 indexed characterId,
    uint256 indexed questId,
    uint256 startTime
);

/**
 * @notice Emitted when a quest is completed
 * @param characterId Character completing the quest
 * @param questId ID of the quest
 * @param reward Amount of GOLD rewarded
 */
event QuestCompleted(
    uint256 indexed characterId,
    uint256 indexed questId,
    uint256 reward
);

// Equipment Events
/**
 * @notice Emitted when new equipment is minted
 * @param to Recipient address
 * @param tokenId ID of the equipment
 * @param equipmentType Type of equipment
 * @param rarity Rarity level of the equipment
 */
event EquipmentMinted(
    address indexed to,
    uint256 indexed tokenId,
    Types.EquipmentType equipmentType,
    Types.Rarity rarity
);

// Marketplace Events
/**
 * @notice Emitted when an item is listed for sale
 * @param seller Address of the seller
 * @param equipmentId ID of the equipment
 * @param listingId ID of the listing
 * @param price Price in GOLD tokens
 * @param amount Number of items listed
 */
event ItemListed(
    address indexed seller,
    uint256 indexed equipmentId,
    uint256 listingId,
    uint256 price,
    uint256 amount
);

/**
 * @notice Emitted when an item is sold
 * @param seller Original seller address
 * @param buyer Purchaser address
 * @param equipmentId ID of the equipment
 * @param listingId ID of the listing
 * @param price Price paid in GOLD tokens
 * @param amount Number of items purchased
 */
event ItemSold(
    address indexed seller,
    address indexed buyer,
    uint256 indexed equipmentId,
    uint256 listingId,
    uint256 price,
    uint256 amount
);

// Team Quest Events
/**
 * @notice Emitted when a team is formed
 * @param questId ID of the team quest
 * @param teamId Unique ID for the team
 * @param members Array of character IDs in the team
 */
event TeamFormed(
    bytes32 indexed questId,
    bytes32 indexed teamId,
    uint256[] members
);

/**
 * @notice Emitted when contribution is recorded
 * @param questId ID of the team quest
 * @param characterId Character making contribution
 * @param value Amount contributed
 * @param totalValue New total contribution for character
 */
event ContributionRecorded(
    bytes32 indexed questId,
    uint256 indexed characterId,
    uint256 value,
    uint256 totalValue
);

/**
 * @notice Emitted when a team quest is completed
 * @param questId ID of the team quest
 * @param teamId ID of the team
 * @param teamReward Total reward for the team
 * @param topContributor Character ID of top contributor
 * @param topReward Bonus reward for top contributor
 */
event TeamQuestCompleted(
    bytes32 indexed questId,
    bytes32 indexed teamId,
    uint256 teamReward,
    uint256 topContributor,
    uint256 topReward
);
```

## Method Return Values 🔄

The mystical treasures returned by our incantations:

### Character Contract

| Method | Return Type | Description |
|--------|-------------|-------------|
| `mintCharacter` | `uint256` | ID of newly created character |
| `getCharacter` | `(Stats, EquipmentSlots, CharacterState)` | Complete character data |
| `ownerOf` | `address` | Owner of the character |
| `characterWallets` | `address` | Address of character's wallet |
| `tokenURI` | `string` | Metadata URI for the character |
| `getCharacterStats` | `Stats` | Character's attribute stats |

### Equipment Contract

| Method | Return Type | Description |
|--------|-------------|-------------|
| `mintEquipment` | `uint256` | ID of newly created equipment |
| `getEquipmentType` | `EquipmentType` | Type of the equipment (WEAPON/ARMOR) |
| `getEquipmentRarity` | `Rarity` | Rarity level of the equipment |
| `getEquipmentDetails` | `(EquipmentType, Rarity, string)` | Complete equipment data |
| `uri` | `string` | Metadata URI for the equipment |
| `balanceOf` | `uint256` | Amount of equipment owned by address |

### Quest Contract

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getQuestTemplate` | `QuestTemplate` | Quest template data |
| `getQuestStatus` | `(bool, uint256, uint256)` | Quest completion status, progress, and target |
| `getActiveQuests` | `uint256[]` | Array of active quest IDs for character |
| `getCompletedQuests` | `uint256[]` | Array of completed quest IDs for character |
| `calculateReward` | `uint256` | Calculated reward for a quest completion |

### Social Quest Contract

| Method | Return Type | Description |
|--------|-------------|-------------|
| `formTeam` | `bytes32` | ID of newly formed team |
| `getTeamProgress` | `(uint256, uint256)` | Current and target contribution values |
| `getTeamMembers` | `uint256[]` | Array of character IDs in team |
| `getContribution` | `uint256` | Character's contribution to a quest |
| `getTopContributor` | `(uint256, uint256)` | Top contributor ID and amount |

May these sacred specifications guide your journey through our mystical API, brave developer! 📜✨ 