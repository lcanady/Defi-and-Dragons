# 🔱 The GOLD Token

Welcome, adventurer! The GOLD token is the core ERC-20 currency fueling the DeFi & Dragons economy. This document details its properties and role within the game.

## Token Overview 🪙

| Attribute | Value |
|-----------|-------|
| Name | Game Token |
| Symbol | GOLD |
| Standard | ERC-20 |
| Supply | Mintable via authorized contracts |
| Primary Source | [ArcaneStaking Rewards](./defi-mechanics.md#arcanestaking-system-) |

## Core Utility 🛠️

GOLD serves multiple functions within the game ecosystem:

- **Staking Rewards**: The primary reward distributed for staking LP tokens in [ArcaneStaking](./defi-mechanics.md#arcanestaking-system-).
- **Crafting Ingredient**: May be required as a component in certain [ArcaneCrafting](./defi-mechanics.md#arcanecrafting-system-) recipes.
- **Marketplace Currency**: Used for buying and selling items on the [Marketplace](../api-reference/game-facade.md#marketplace-interactions). (*Note: Specific marketplace mechanics determine if GOLD is transferred or potentially burned.*)
- **Quest Rewards**: Distributed upon successful completion of certain [Quests](../api-reference/quest.md).
- **Character Actions**: Potentially used for specific character upgrades or actions (details TBC based on final implementation).

## Obtaining GOLD 💰

You can acquire GOLD tokens through several in-game activities:

1.  **LP Staking**: Stake eligible LP tokens in `ArcaneStaking` pools to earn GOLD emissions.
2.  **Quest Completion**: Successfully completing various quests often yields GOLD rewards.
3.  **Marketplace Sales**: Selling items or resources to other players on the marketplace.
4.  **Special Events**: Participating in limited-time game events may offer GOLD prizes.

## Tokenomics & Supply 📊

### Emission (Minting)

-   New GOLD tokens are primarily minted by the `ArcaneStaking` contract as rewards for liquidity providers.
-   The rate of emission is **dynamic** and depends on:
    -   The global `rewardPerBlock` configured in `ArcaneStaking`.
    -   The `allocPoint` (allocation points) assigned to each specific staking pool, determining its share of the global rewards.
-   Only contracts granted the `MINTER_ROLE` (like `ArcaneStaking`) can create new GOLD tokens.

### Burning

-   GOLD tokens may be removed from circulation (burned) through specific game mechanics to manage supply.
-   Potential burning mechanisms include:
    -   Fees for certain marketplace actions.
    -   Consumption during high-tier `ArcaneCrafting` recipes.
-   Contracts authorized with a `BURNER_ROLE` or similar permission handle the burning process.

### Total Supply

-   The total supply of GOLD is not fixed and changes based on the balance between minting (rewards) and burning (consumption/fees).

## Governance & Control 🏛️

The GOLD token contract uses OpenZeppelin's `AccessControl` for security:

-   **Owner/Admin**: Manages roles and authorized contract addresses.
-   **MINTER_ROLE**: Granted to contracts responsible for distributing GOLD (e.g., `ArcaneStaking`).
-   **BURNER_ROLE**: Granted to contracts responsible for removing GOLD from circulation (e.g., potentially `ArcaneCrafting`, `Marketplace`).
-   **Specific Permissions**: May grant limited permissions to quest or other system contracts for specific interactions if needed.

## GOLD in the Game Economy 🌍

GOLD facilitates a circular flow:

1.  Players engage in DeFi (staking) or gameplay (quests) to earn GOLD.
2.  GOLD is spent on gameplay progression (crafting, marketplace purchases).
3.  Improved gear/items potentially allow players to earn GOLD more effectively.
4.  Excess GOLD might be used to provide liquidity (creating LP tokens), restarting the cycle.

## Viewing Your Balance 👁️

You can check your GOLD balance using standard methods:

-   Connect your wallet to the game's UI.
-   Use a blockchain explorer (like Etherscan) by entering your wallet address on the GOLD token's contract page.
-   Query the `balanceOf(yourAddress)` function directly on the GOLD token contract using developer tools.

May your coffers overflow with GOLD! ✨💰 