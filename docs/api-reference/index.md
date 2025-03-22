# 📚 The Ancient Scrolls: API Reference

## 🏰 Core Systems

### The Grand Facade
The sacred gateway to all realms of interaction:
```solidity
interface IGameFacade {
    // Forge a new hero
    function createCharacter(Types.Stats memory initialStats, Types.Alignment alignment) external returns (uint256);
    // Don or remove equipment
    function equipItems(uint256 characterId, uint256 weaponId, uint256 armorId) external;
    function unequipItems(uint256 characterId, bool weapon, bool armor) external;
    // Embark on quests
    function startQuest(uint256 characterId, uint256 questId) external;
    function completeQuest(uint256 characterId, uint256 questId) external;
    // Invoke divine drops
    function requestRandomDrop(uint256 dropRateBonus) external returns (uint256);
    // Trade in the bazaar
    function listItem(uint256 equipmentId, uint256 price, uint256 amount) external;
    function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external;
}
```

### The Hero's Essence
```solidity
interface ICharacter {
    // Breathe life into a new hero
    function mintCharacter(address to, Types.Stats memory stats, Types.Alignment alignment) external returns (uint256);
    // Glimpse a hero's essence
    function getCharacter(uint256 characterId) external view returns (Types.Stats memory, Types.EquipmentSlots memory, Types.CharacterState memory);
    // Don equipment
    function equip(uint256 characterId, uint256 weaponId, uint256 armorId) external;
    // Remove equipment
    function unequip(uint256 characterId, bool weapon, bool armor) external;
}
```

### The Combat Arts
```solidity
interface ICombatActions {
    // Execute battle maneuvers
    function executeMove(uint256 characterId, bytes32 moveId, uint256 targetId) external;
    // Forge new combat techniques
    function createMove(string memory name, uint256 baseDamage, uint256 scalingFactor, uint256 cooldown, ActionType[] memory triggers, uint256 minValue, SpecialEffect effect, uint256 effectValue) external returns (bytes32);
    // Master combo paths
    function createComboPath(bytes32 firstMoveId, bytes32 secondMoveId) external;
}
```

### The Quest Tome
```solidity
interface IQuest {
    // Begin your journey
    function startQuest(uint256 characterId, uint256 questId) external;
    // Claim your victory
    function completeQuest(uint256 characterId, uint256 questId) external;
    // Study quest requirements
    function getQuestTemplate(uint256 questId) external view returns (QuestTemplate memory);
}
```

### The Fellowship Bonds
```solidity
interface ISocialQuest {
    // Form your fellowship
    function formTeam(bytes32 questId, uint256[] calldata memberIds) external;
    // Record heroic deeds
    function recordContribution(bytes32 questId, uint256 characterId, uint256 value) external;
    // Guide new adventurers
    function registerReferral(bytes32 questId, uint256 referrerId, uint256 referreeId) external;
    // Complete mentorship
    function completeReferral(bytes32 questId, uint256 referrerId, uint256 referreeId) external;
}
```

### The Arcane Markets
```solidity
interface IArcaneStaking {
    // Channel your power
    function deposit(uint256 poolId, uint256 amount) external;
    // Withdraw your essence
    function withdraw(uint256 poolId, uint256 amount) external;
    // Glimpse your rewards
    function pendingReward(uint256 poolId, address user) external view returns (uint256);
}

interface IArcaneCrafting {
    // Forge mystical items
    function craftItem(uint256 recipeId) external returns (uint256);
}

interface IArcaneQuestIntegration {
    // Begin mystical trials
    function startQuest(uint256 characterId, uint256 questId) external;
    // Complete your ritual
    function completeQuest(uint256 characterId, uint256 questId) external;
}
```

### The Grand Bazaar
```solidity
interface IMarketplace {
    // Display your wares
    function listItem(uint256 equipmentId, uint256 price, uint256 amount) external;
    // Acquire treasures
    function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external;
    // Withdraw from trade
    function cancelListing(uint256 equipmentId, uint256 listingId) external;
}
```

### The Forbidden Scrolls
```solidity
interface IGameErrors {
    // When access is denied by ancient wards
    error NotAuthorized();
    // When your coffers run dry
    error InsufficientBalance();
    // When the ritual is incorrectly performed
    error InvalidParameters();
    // When the quest scroll has faded
    error QuestNotActive();
    // When glory has already been claimed
    error QuestAlreadyCompleted();
    // When the item has vanished from the realm
    error ItemNotAvailable();
    // When more training is required
    error InsufficientLevel();
    // When ancient magic still recharges
    error CooldownActive();
}
```

May these sacred interfaces guide your path through the realms of code, brave builder! 🏗️✨ 