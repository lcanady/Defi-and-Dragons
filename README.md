# 🐉 Dungeons & DeFi

*Where Smart Contracts Meet Dragon Slaying*

A fantasy RPG framework for DeFi interactions, bringing gamification to decentralized finance through quests, combat, and epic adventures.

## 📥 Installation

You can install this package using either Forge or npm:

### Using Forge
```bash
forge install lcanady/defi-and-dragons
```

### Using npm
```bash
npm install @digibear/defi-and-dragons
# or
yarn add @digibear/defi-and-dragons
```

## 🎮 Features

- **Combat System**: Turn DeFi actions into epic battles
- **Quest System**: Complete daily and seasonal challenges
- **Social Features**: Form guilds and tackle group quests
- **Protocol Integration**: Interact with DeFi protocols through a fantasy RPG lens
- **Item & Equipment**: NFT-based items and equipment system
- **Marketplace**: Trade items with other adventurers

## 🛠️ Quick Start

1. Install the package using your preferred package manager:

Using Forge:
```bash
forge install lcanady/defi-and-dragons
```

Using npm:
```bash
npm install @digibear/defi-and-dragons
```

2. Import the contracts:

If installed via Forge:
```solidity
import "defi-and-dragons/src/CombatActions.sol";
import "defi-and-dragons/src/QuestSystem.sol";
```

If installed via npm:
```solidity
import "@digibear/defi-and-dragons/src/CombatActions.sol";
import "@digibear/defi-and-dragons/src/QuestSystem.sol";
```

3. Initialize your game components:
```solidity
contract MyGame {
    CombatActions combat;
    QuestSystem quests;

    constructor() {
        combat = new CombatActions();
        quests = new QuestSystem();
    }
}
```

## 📚 Documentation

Visit our [documentation](./docs) to learn more about:
- [Getting Started](./docs/getting-started/index.md)
- [Game Mechanics](./docs/gameplay/index.md)
- [Advanced Features](./docs/advanced-mechanics/index.md)
- [DeFi Integration](./docs/defi/index.md)

## 🧪 Testing

```bash
forge test
```

## 🤝 Contributing

We welcome contributions! Please check out our [Contributing Guide](CONTRIBUTING.md) for guidelines.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Acknowledgments

Built with [Foundry](https://github.com/foundry-rs/foundry) and powered by the spirit of adventure!
