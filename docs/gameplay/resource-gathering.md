# Resource Gathering via Yield Farming

In DeFi & Dragons, traditional resource gathering (like mining ore or chopping wood) is reimagined through the lens of Decentralized Finance (DeFi). Instead of repetitive clicking, players utilize **Yield Farming** mechanics to generate essential resources.

## The Core Mechanic

1.  **Resource Nodes as Staking Pools:** Specific locations in the game world (e.g., The Iron Mine, The Whispering Woods) correspond to staking pools within the `ResourceFarm` smart contract.
2.  **Staking Requirement:** To "farm" a resource, players stake a designated ERC-20 token (often an LP token representing liquidity related to the resource, e.g., `IRON/USDC` LP for Iron Ore) into the corresponding pool in the `ResourceFarm` contract.
3.  **Yielding Resources:** While staked, players automatically accrue resource tokens (e.g., `IronOreToken`, `LumberToken`) based on:
    *   The amount of LP tokens they staked.
    *   Their share of the total LP tokens staked in that specific pool.
    *   The emission rate (`rewardPerBlock`) allocated to that pool.
4.  **Harvesting:** Players can claim (harvest) their accumulated resource tokens at any time by interacting with the `ResourceFarm` contract.
5.  **Unstaking:** Players can withdraw their staked LP tokens whenever they choose.

This system represents putting your capital (liquidity) to work to extract value (resources) from the game world.

## Example: Farming Iron Ore

1.  **Acquire LP Tokens:** Obtain `IRON/USDC` LP tokens by providing liquidity to an IRON/USDC pool on a supported Decentralized Exchange (DEX).
2.  **Travel to the Node:** Navigate your character to the entrance of "The Iron Mine" on the game map.
3.  **Interact & Stake:** Interact with the mine interface. Choose the amount of `IRON/USDC` LP tokens to stake.
4.  **Approve & Deposit:** Approve the `ResourceFarm` contract to spend your LP tokens, then confirm the deposit transaction in your wallet.
5.  **Accrue Rewards:** Your staked LP tokens now passively generate `IronOreToken` based on the farm's parameters.
6.  **Harvest:** Return to the mine interface (or use a global farm UI) periodically to claim your `IronOreToken` by sending a harvest transaction.
7.  **Utilize Resources:** Use the harvested `IronOreToken` in crafting recipes (e.g., forging swords, armor).
8.  **Unstake (Optional):** When you no longer wish to farm Iron Ore, withdraw your `IRON/USDC` LP tokens.

## Smart Contract Interaction

The primary contract involved is `src/ResourceFarm.sol`.

*   **Pools:** Managed by the contract owner. Each pool has:
    *   `lpToken`: The token required for staking (e.g., `IRON/USDC` LP).
    *   `rewardToken`: The resource token minted as yield (e.g., `IronOreToken`).
    *   `allocPoint`: Weight determining the share of total rewards allocated to this pool.
*   **Key Functions for Players:**
    *   `deposit(pid, amount)`: Stake `amount` of `lpToken` into pool `pid`.
    *   `withdraw(pid, amount)`: Unstake `amount` of `lpToken` from pool `pid` (also harvests pending rewards).
    *   `harvest(pid)`: Claim pending `rewardToken` from pool `pid`.
    *   `pendingReward(pid, user)`: View function to check claimable rewards.
    *   `emergencyWithdraw(pid, amount)`: Withdraw `lpToken` without claiming rewards (use with caution).

## Resource Tokens

*   `src/tokens/IronOreToken.sol` (IRON)
*   `src/tokens/LumberToken.sol` (LMBR)
*   *(Add others as created)*

These are standard ERC-20 tokens minted exclusively by the `ResourceFarm` contract upon harvesting.

## Risks and Considerations

*   **Impermanent Loss (IL):** Staking LP tokens involves exposure to IL, just like in standard DeFi yield farming. The value of your deposited LP tokens can fluctuate based on the relative price movement of the underlying assets (e.g., IRON vs. USDC). *The game does not compensate for IL.*
*   **Smart Contract Risk:** Interact with the `ResourceFarm` contract at your own risk. While audited (assume it will be), vulnerabilities could exist.
*   **Gas Fees:** Staking, withdrawing, and harvesting all require blockchain transactions and incur gas fees.
*   **Balancing:** Reward rates are determined by the game administrators (`owner` of `ResourceFarm`) and may be adjusted to manage the in-game economy.

## Related Links

*   [Item System](./item-system.md) (Crafting Materials)
*   [DeFi Mechanics](../defi/index.md) 