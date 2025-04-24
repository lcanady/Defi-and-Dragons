# Ho there, brave Traveler! 🗡️

Welcome to the mystical realm of DeFi & Dragons, where the ancient arts of decentralized finance meet the thrill of fantasy role-playing. Forge your hero, embark on epic quests, battle monsters, team up with allies, and engage with integrated DeFi mechanics in a unique on-chain adventure.

## 📜 Explore the Chronicles

Navigate through the collected knowledge of our realm:

- **[Getting Started](./getting-started/index.md)**
  - Your first steps: setting up your environment and interacting with the core contracts.
- **[Gameplay Guide](./gameplay/index.md)**
  - Understand the core loop, character progression, combat, quests, and social features.
- **[DeFi Mechanics](./defi/index.md)**
  - Learn how staking, crafting, and the AMM integrate into the game.
- **[Advanced Mechanics](./advanced-mechanics/index.md)**
  - Delve deeper into specific systems (details may vary).
- **[API Reference](./api-reference/index.md)**
  - Detailed documentation for all smart contracts.
- **[Game Design Document](#game-design-document-gdd---implemented-features-v02)** - Overview based on current code.

## 🎮 Quick Setup for Developers

To set up the project locally for development or testing:

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/lcanady/defi-and-dragons.git
    cd defi-and-dragons
    ```
2.  **Install Dependencies:** (Assuming Foundry is used)
    ```bash
    forge install
    ```
3.  **Build Contracts:**
    ```bash
    forge build
    ```
4.  **Run Tests:**
    ```bash
    forge test
    ```

*(Refer to the project's main README for more detailed setup and deployment instructions.)*

## 🤝 Join the Fellowship

Connect with other adventurers and the development team:

- [GitHub Repository](https://github.com/lcanady/defi-and-dragons) (Replace with actual repo URL)

May your quests be bountiful and your yields ever high! 🐉✨

## Game Design Document (GDD) - Implemented Features (v0.2)

This GDD reflects the features and mechanics observed from the codebase review.

### 1. Introduction & Vision

*   **Title:** DeFi & Dragons
*   **Concept:** A blockchain-based RPG where player characters (NFTs) engage in quests and combat, with core gameplay mechanics driven by the player's real DeFi actions on associated protocols. Progress involves acquiring better NFT equipment, completing quests tied to combat or DeFi activity, and earning token rewards.
*   **Genre:** RPG, GameFi, Action-Triggered Combat.
*   **Platform:** Web Browser (implied by documentation examples).
*   **Target Chain:** EVM-compatible (likely L2/Sidechain due to gas optimization focus).
*   **Core Pillars:** NFT Characters & Equipment, DeFi Action-Driven Combat, Questing System, On-Chain Rewards.

### 2. Gameplay Mechanics

*   **Core Loop:**
    1.  **Mint/Acquire:** Obtain a Character NFT (`Character.sol`).
    2.  **Quest:** Accept quests (`Quest.sol`, `CombatQuest.sol`, `ProtocolQuest.sol`) which may involve defeating monsters or performing DeFi actions.
    3.  **DeFi Action / Combat:** Perform actions on integrated DeFi protocols (e.g., trading, providing liquidity). These actions are validated (`ActionCombatManager.sol`) and trigger combat "Moves" (`CombatActions.sol`) that deal damage to quest targets, influenced by character stats and equipment. Direct combat (e.g., Boss Fights in `CombatQuest.sol`) involves using abilities (`CombatAbilities.sol`) and calculating damage (`CombatDamageCalculator.sol`).
    4.  **Reward:** Complete quests or defeat monsters to earn token rewards (`GameToken`) and potentially Equipment NFTs (`ItemDrop.sol`).
    5.  **Farm/Stake:** Stake tokens in `ResourceFarm.sol` to earn resource tokens.
    6.  **Equip/Trade:** Equip better gear (`Equipment.sol`) obtained via drops or purchased on the `Marketplace.sol` to improve combat effectiveness.
    7.  **Repeat:** Take on harder quests and engage further with DeFi protocols.
*   **RPG Elements:**
    *   **Character:** ERC721 NFTs (`Character.sol`) with randomized base stats (Strength, Agility, Magic) determined at mint using `ProvableRandom.sol`. Characters have a Level and Alignment. Each character has an associated `CharacterWallet.sol` for managing items. *Note: Base stats appear fixed after minting in current contracts; $GOLD training mentioned in docs is not implemented.*
    *   **Combat System:** Primarily driven by off-chain DeFi actions triggering on-chain combat moves (`ActionCombatManager`, `CombatActions`). Damage scales with the DeFi `actionValue` and character/weapon stats (`CombatDamageCalculator`). A separate system (`CombatAbilities`) handles elemental damage, status effects, and combos, used within specific `CombatQuest` encounters (e.g., Boss Fights). Critical hits are possible (`