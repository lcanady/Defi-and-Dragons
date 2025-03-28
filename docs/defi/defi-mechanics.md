# 🔮 The Arcane Connection: DeFi & Gameplay Mechanics

This document details *how* the core DeFi integrations - Staking, Crafting, and the AMM - function and connect to the gameplay systems of DeFi & Dragons.

*(For a high-level overview, see [DeFi Integration Index](./index.md). For specific contract functions, see the [GameFacade API Reference](../api-reference/game-facade.md).)*

## ArcaneStaking System 🏦

The `ArcaneStaking` contract allows players to earn rewards by staking specific tokens, typically Liquidity Provider (LP) tokens obtained from the in-game [Automated Market Maker (AMM)](./lp-token-acquisition.md).

### Staking & Earning Rewards

1.  **Acquire LP Tokens:** Provide liquidity to a supported pair (e.g., GAME_TOKEN-ETH) in the AMM to receive LP tokens representing your share of the pool. (See [LP Token Acquisition](./lp-token-acquisition.md)).
2.  **Approve Staking Contract:** Before staking, you must approve the `ArcaneStaking` contract to spend your LP tokens.
3.  **Stake (Deposit):** Call the staking function (likely `stakeArcane` via `GameFacade`) specifying the pool ID and the amount of LP tokens you wish to stake.
4.  **Earn Rewards:** While your tokens are staked, you continuously accrue reward tokens (e.g., the primary game token) based on the pool's allocation points, the total amount staked in the pool, and the global reward rate.
5.  **Harvest Rewards:** You can claim your accrued rewards. This often happens automatically when you deposit more tokens or withdraw existing ones. Some contracts also have a dedicated claim function or allow depositing `0` amount to trigger a harvest.

### Withdrawing

1.  **Check Minimum Duration:** Pools may have a minimum staking period. Ensure this duration has passed since your last deposit before attempting to withdraw.
2.  **Withdraw:** Call the unstaking function (likely `unstakeArcane` via `GameFacade`) specifying the pool ID and the amount of LP tokens to remove. This action typically also harvests any pending rewards.

### Reward Calculation

Rewards are generally calculated per block based on:

-   **Global Reward Rate:** How many reward tokens are distributed across *all* pools per block.
-   **Pool Allocation Points:** Each pool has points determining its share of the global rewards.
-   **Your Share:** Your portion of the total LP tokens staked in that specific pool.

The contract tracks rewards internally using concepts like `accumulatedRewardPerShare`. You can usually check your estimated pending rewards via a view function before claiming.

### Pool Information

Active staking pools, their required LP tokens, reward rates (derived from allocation points), and minimum staking times are **dynamically managed** by the contract owner. This information is *not* hardcoded. To find current pools:

-   Consult the game's official User Interface (UI).
-   Query the `poolInfo` (or similar) array/mapping directly on the blockchain using explorers or developer tools.

### Gameplay Integration

-   **Protocol Quests:** Staking actions (depositing, maintaining a staked amount) can fulfill objectives in certain [Protocol Quests](../api-reference/quest.md#protocol-quests-protocolquestsol).
-   **Combat Actions:** The act of staking or harvesting might trigger specific [Combat Actions](../api-reference/combat.md#combat-actions-sol-), granting combat bonuses or effects.

## ArcaneCrafting System ⚒️

The `ArcaneCrafting` contract allows players to transform specific input tokens (like LP tokens or other resources) into Equipment NFTs based on defined recipes.

### Crafting Process

1.  **Obtain Recipe Info:** Identify the `recipeId` for the desired item. Recipes define:
    *   The resulting Equipment item ID.
    *   The required input tokens (e.g., a specific LP token, resource tokens).
    *   The required amounts of each input token.
    *   A potential cooldown period after crafting.
2.  **Acquire Inputs:** Gather the necessary LP tokens and any other required resource tokens.
3.  **Approve Crafting Contract:** Approve the `ArcaneCrafting` contract to spend the required amounts of *all* input tokens.
4.  **Craft:** Call the crafting function (likely `craftArcane` via `GameFacade`), providing the `recipeId`.
5.  **Receive Item:** If successful, the required input tokens are burned/transferred, and the resulting Equipment NFT is minted to your character's wallet or your address.

### AMM-Required Gear

Some crafting recipes might produce special gear flagged as "AMM Required." This flag (`ammRequiredGear` in the contract) indicates that the item's full potential or specific abilities might only be active when the player is actively providing liquidity in a related AMM pool. Check item descriptions or the UI for specifics.

### Gameplay Integration

-   **Resource Sink:** Crafting provides a valuable way to use accumulated tokens and resources.
-   **Gear Progression:** Allows players to create powerful items beyond relying solely on random drops.
-   **Protocol Quests:** Crafting specific items might be an objective in certain [Protocol Quests](../api-reference/quest.md#protocol-quests-protocolquestsol).

## AMM Integration (Swapping & Liquidity)

The in-game Automated Market Maker (AMM), powered by contracts like `ArcaneRouter`, `ArcanePair`, and `ArcaneFactory`, facilitates token swaps and liquidity provision.

### Swapping Tokens

-   Players can swap between different game-related tokens (e.g., Game Token <> Resource Token, Game Token <> ETH) via the `ArcaneRouter` (likely accessed through `swapTokens` on the `GameFacade`). Standard swap parameters like amounts, slippage tolerance, and deadlines apply.

### Providing Liquidity

-   Players can deposit pairs of tokens into liquidity pools via the `ArcaneRouter` (likely accessed through `addLiquidity`/`removeLiquidity` on the `GameFacade`) to receive LP tokens.
-   LP tokens represent a share of the pool and earn trading fees.
-   These LP tokens are often the required input for `ArcaneStaking` pools or `ArcaneCrafting` recipes.
-   See: [LP Token Acquisition Guide](./lp-token-acquisition.md).

### Gameplay Integration

-   **Economy:** The AMM is crucial for price discovery and enabling players to exchange different types of game resources and currency.
-   **Staking/Crafting:** Necessary for obtaining the LP tokens often required for staking and crafting.
-   **Protocol Quests:** Actions like swapping or adding/removing liquidity can fulfill objectives in [Protocol Quests](../api-reference/quest.md#protocol-quests-protocolquestsol).
-   **Combat Actions:** Swapping or liquidity provision might trigger specific [Combat Actions](../api-reference/combat.md#combat-actions-sol-).

## Risk Considerations 🛡️

Engaging with these DeFi mechanics carries inherent risks:

1.  **Smart Contract Risk:** Bugs or vulnerabilities could exist, potentially leading to loss of funds. Interact at your own risk.
2.  **Impermanent Loss:** Providing liquidity to the AMM means the value of your assets might be lower upon withdrawal compared to simply holding them if prices diverge.
3.  **Token Price Volatility:** The value of game tokens, reward tokens, and LP tokens can fluctuate significantly.
4.  **Gas Costs:** Blockchain transaction fees can impact the profitability of DeFi actions.
5.  **Staking Risks:** Minimum staking times lock funds. Reward rates can change if pool parameters (like allocation points) are adjusted by the owner.

*Always understand the mechanics and risks before participating in DeFi activities.* 💰✨ 