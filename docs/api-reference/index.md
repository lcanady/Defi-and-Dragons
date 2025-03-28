# 📚 The Ancient Scrolls: API Reference

Welcome, developer-adventurer, to the collected knowledge of the DeFi & Dragons smart contracts! These scrolls detail the interfaces and functions that power our realm.

Use the `GameFacade` as your primary entry point for most interactions. Below are links to the detailed API references for each major system.

## Core Systems

*   **[Game Facade (`GameFacade.sol`)](./game-facade.md)**
    *   The central gateway providing simplified access to all major game functions, including character creation, equipment management, quest interactions, marketplace actions, and DeFi integrations.

*   **[Character (`Character.sol`)](./character.md)**
    *   Manages the Character NFTs (ERC721), their core stats (Strength, Agility, Magic), state (Level, Health), and the creation of dedicated `CharacterWallet` contracts.

*   **[Equipment (`Equipment.sol`)](./equipment.md)**
    *   Defines the properties and stats of equippable items (Weapons, Armor) as NFTs (ERC1155), including their stat affinities and special abilities.

## Gameplay Systems

*   **[Quest System](./quest.md)**
    *   A modular system covering various quest types:
        *   **`Quest.sol`**: Core logic for quest templates, objectives, and party/raid management.
        *   **`CombatQuest.sol`**: Manages monster hunts and boss fights.
        *   **`SocialQuest.sol`**: Handles team-based quests and player referrals.
        *   **`TimeQuest.sol`**: Governs daily and seasonal quests with time-based bonuses.
        *   **`ProtocolQuest.sol`**: Tracks quests involving interactions with specific DeFi protocols.

*   **[Combat System](./combat.md)**
    *   Manages battle mechanics:
        *   **`CombatDamageCalculator.sol`**: Calculates base damage from stats and equipment.
        *   **`CombatActions.sol`**: Handles specific combat moves triggered by actions, battle state, combos, and critical hits.
        *   **`CombatAbilities.sol`**: Defines elemental abilities, status effects, and elemental combos.

*   **Item Drop (`ItemDrop.sol`)** *(Covered within relevant sections like Quest and Combat)*
    *   Handles randomness (using `ProvableRandom`) for dropping equipment NFTs as rewards.

*   **Marketplace (`Marketplace.sol`)** *(Covered within Game Facade)*
    *   Allows players to list and purchase equipment NFTs using the game token.

*   **Pet (`Pet.sol`)** *(Covered within Game Facade)*
    *   Manages Pet NFTs that can be assigned to characters.

*   **Mount (`Mount.sol`)** *(Covered within Game Facade)*
    *   Manages Mount NFTs that can be assigned to characters.

*   **Title (`Title.sol`)** *(Covered within Game Facade)*
    *   Manages Title NFTs or attributes that can be awarded to characters.

## DeFi Integration (Arcane Contracts)

*(Interactions typically occur via the Game Facade)*

*   **Arcane Staking**: Handles staking of game tokens or LP tokens.
*   **Arcane Crafting**: Allows players to craft items using specific recipes and resources.
*   **Arcane AMM (Factory/Pair/Router)**: Powers the in-game decentralized exchange features.
*   **Arcane Quest Integration**: Links DeFi actions (staking, swapping, etc.) to specific quests (`ProtocolQuest`).

---

May these scrolls illuminate your path through the realms of code! 🏗️✨