# DnD Blockchain Game

A decentralized role-playing game built on Ethereum that combines traditional RPG mechanics with DeFi elements. The game features character NFTs, equipment, quests, and a randomized loot system powered by Chainlink VRF.

## Core Components

### Character System
Characters are ERC-721 NFTs with the following attributes:

```solidity
struct Character {
    uint256 id;
    string name;
    uint8 strength;
    uint8 agility;
    uint8 magic;
    EquipmentSlots equipped;
    bool isActive;
}

struct EquipmentSlots {
    uint256 weaponId;
    uint256 armorId;
}
```

Example character creation:

```solidity
// Mint a new character
character.mint("Gandalf the Grey");

// Update character stats
character.updateStats(characterId, 10, 5, 15); // strength, agility, magic

// Equip items
character.equip(characterId, weaponId, armorId);
```

### Equipment System
Equipment items are ERC-1155 tokens with stats and special abilities:

```solidity
struct EquipmentStats {
    uint8 strengthBonus;
    uint8 agilityBonus;
    uint8 magicBonus;
    bool isActive;
    string name;
    string description;
}

struct SpecialAbility {
    string name;
    string description;
    TriggerCondition triggerCondition;
    uint256 triggerValue;
    EffectType effectType;
    uint256 effectValue;
    uint256 cooldown;
}
```

Example equipment creation and usage:

```solidity
// Create a powerful sword
equipment.createEquipment(
    1,                          // equipmentId
    "Flaming Sword",           // name
    "A sword imbued with fire", // description
    5,                         // strengthBonus
    2,                         // agilityBonus
    3                          // magicBonus
);

// Add a special ability
equipment.addSpecialAbility(
    1,                         // equipmentId
    "Flame Strike",           // name
    "Burns the target",       // description
    TriggerCondition.ON_HIT,  // when it triggers
    100,                      // trigger value
    EffectType.DAMAGE,        // what it does
    50,                       // effect value
    3600                      // cooldown in seconds
);
```

### Quest System
Players can undertake quests to earn rewards:

```solidity
struct Quest {
    uint256 id;
    string name;
    uint256 requiredStrength;
    uint256 requiredAgility;
    uint256 requiredMagic;
    uint256 rewardTokens;
    uint256 cooldownPeriod;
    bool isActive;
}
```

Example quest interaction:

```solidity
// Start a quest
quest.startQuest(characterId, questId);

// Complete a quest and receive rewards
quest.completeQuest(characterId, questId);
```

### Item Drop System
Random item drops powered by Chainlink VRF:

```solidity
struct DropTable {
    string name;
    uint16 totalWeight;
    bool active;
    DropEntry[] entries;
}

struct DropEntry {
    uint256 equipmentId;
    uint16 weight;  // Relative probability (1-1000)
}
```

Example drop table setup and usage:

```solidity
// Create a drop table
DropEntry[] memory entries = new DropEntry[](2);
entries[0] = DropEntry({
    equipmentId: 1,  // Common Sword
    weight: 800      // 80% chance
});
entries[1] = DropEntry({
    equipmentId: 2,  // Rare Sword
    weight: 200      // 20% chance
});

itemDrop.createDropTable(1, "Basic Sword Drop", entries);

// Request a random drop
uint256 requestId = itemDrop.requestDrop(1);
// VRF callback will automatically mint the item to the player
```

### Game Token
The in-game currency (ERC-20) used for:
- Quest rewards
- Marketplace transactions
- Future DeFi integrations

Example token usage:

```solidity
// Quest completion reward
gameToken.mint(player, 100);

// Spend tokens
gameToken.burn(player, 50);
```

## Getting Started

### Prerequisites
- Node.js v14+
- Foundry

### Installation
1. Clone the repository:

```bash
git clone https://github.com/yourusername/dnd.git
cd dnd
```

2. Install dependencies:

```bash
forge install
```

3. Run tests:

```bash
forge test
```

### Deployment
1. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your values
```

2. Deploy contracts:

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Testing
The project includes comprehensive tests for all components:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Character.t.sol

# Run with verbosity
forge test -vv
```

## Security
- All contracts use OpenZeppelin's battle-tested implementations
- Randomness is provided by Chainlink VRF
- Access control implemented using Ownable pattern
- Comprehensive test coverage

## Future Development
- Marketplace implementation
- DeFi integrations (AMM, Staking)
- Advanced character attributes (Titles, Pets, Mounts)
- Guild system
- Cross-chain functionality

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License
MIT License - see LICENSE.md

## Acknowledgments
- OpenZeppelin for secure contract implementations
- Chainlink for VRF functionality
- Foundry for development framework
