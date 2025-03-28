# 💫 Acquiring LP Tokens via the AMM

Welcome, liquidity provider! To participate in [Staking](./defi-mechanics.md#arcanestaking-system-) or certain [Crafting Recipes](./defi-mechanics.md#arcanecrafting-system-), you often need Liquidity Provider (LP) tokens. This guide explains how to obtain them using the in-game Automated Market Maker (AMM).

## Understanding LP Tokens 🧠

LP tokens represent your share in an AMM liquidity pool (e.g., a pool containing the Game Token and ETH). When you deposit a pair of tokens into a pool, you receive LP tokens back.

These LP tokens can then be:

1.  Staked in `ArcaneStaking` pools to earn rewards.
2.  Used as ingredients in `ArcaneCrafting` recipes.
3.  Redeemed later by removing your liquidity from the AMM pool (receiving back the underlying tokens plus earned trading fees, minus any [Impermanent Loss](./defi-mechanics.md#risk-considerations-)).

## Providing Liquidity (Recommended: via GameFacade) 🔄

The easiest and recommended way to add liquidity is through the `GameFacade` contract, which interacts with the `ArcaneRouter` on your behalf.

### 1. Prepare Your Tokens

Ensure you have sufficient balances of *both* tokens required for the liquidity pair you want to join (e.g., Game Token and WETH).

```typescript
// Conceptual Example (Check balances)
const gameTokenBalance = await gameToken.balanceOf(yourAddress);
const wethBalance = await weth.balanceOf(yourAddress);
console.log(`Game Token: ${ethers.utils.formatEther(gameTokenBalance)}`);
console.log(`WETH: ${ethers.utils.formatEther(wethBalance)}`);
```

### 2. Approve the Router (via Facade Interaction)

When using the `GameFacade`'s liquidity functions, you still need to approve the underlying `ArcaneRouter` contract to spend your tokens. The `GameFacade` address itself typically does *not* need approval, but the router *does*. Get the router address from the `GameFacade` or configuration.

```typescript
// Conceptual Example (Approve Router)
const routerAddress = await gameFacade.arcaneRouter(); // Get router address

// Approve the ROUTER to spend your tokens
await gameToken.approve(routerAddress, amountGameTokenToProvide);
await weth.approve(routerAddress, amountWethToProvide);
```

### 3. Add Liquidity via Facade

Call the `addLiquidity` function on the `GameFacade`, providing the necessary details.

```typescript
// Conceptual Example (Add Liquidity via GameFacade)

// Parameters needed for the facade's addLiquidity function
const tokenA_Address = gameToken.address;
const tokenB_Address = weth.address;
const amountA_Desired = ethers.utils.parseEther("1000"); // e.g., 1000 Game Tokens
const amountB_Desired = ethers.utils.parseEther("1");    // e.g., 1 WETH
const amountA_Min = ethers.utils.parseEther("990");   // Slippage protection
const amountB_Min = ethers.utils.parseEther("0.99");  // Slippage protection
const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10 minutes from now

console.log("Adding liquidity via GameFacade...");
const tx = await gameFacade.addLiquidity(
    tokenA_Address,
    tokenB_Address,
    amountA_Desired,
    amountB_Desired,
    amountA_Min,
    amountB_Min,
    deadline
    // The Facade likely handles the 'to' address internally (msg.sender)
);

const receipt = await tx.wait();
console.log("Liquidity added successfully! TX:", receipt.transactionHash);
// Note: You'll need to find the LP token address separately (see below)
// and check your balance of that LP token.
```

### 4. Finding & Checking LP Tokens

After successfully adding liquidity, LP tokens for that pair's pool will be sent to your address. To find the address of the LP token contract:

-   **Use the UI:** The game interface should display your LP token balances and potentially the addresses.
-   **Query the Factory:** Use the `ArcaneFactory` address (available from `GameFacade`) and call its `getPair(tokenA, tokenB)` function to get the LP token (pair) contract address.

```typescript
// Conceptual Example (Find Pair and Check Balance)
const factoryAddress = await gameFacade.arcaneFactory();
const factory = new ethers.Contract(factoryAddress, ArcaneFactoryABI, signer);

const pairAddress = await factory.getPair(gameToken.address, weth.address);
console.log("LP Token (Pair) Address:", pairAddress);

if (pairAddress !== ethers.constants.AddressZero) {
    const lpTokenContract = new ethers.Contract(pairAddress, UniswapV2PairABI, signer); // Use appropriate Pair ABI
    const lpBalance = await lpTokenContract.balanceOf(yourAddress);
    console.log(`Your LP Token Balance: ${ethers.utils.formatEther(lpBalance)}`);
}
```

## Removing Liquidity

To redeem your LP tokens for the underlying assets:

1.  **Approve Router for LP Tokens:** Approve the `ArcaneRouter` address to spend your LP tokens.
2.  **Call Facade:** Use the `removeLiquidity` function on the `GameFacade`, specifying the token pair, the amount of LP tokens to burn, minimum amounts of underlying tokens expected back (for slippage), and a deadline.

## Discovering Available Pairs 🏦

The specific liquidity pairs available (e.g., GAME_TOKEN-WETH, GAME_TOKEN-USDC) and any associated staking pools are managed dynamically.

-   **Check the Game UI:** The official interface is the best place to see currently supported pairs and staking opportunities.
-   **Query the Factory:** Advanced users can query the `ArcaneFactory` contract's `allPairsLength()` and `allPairs(index)` functions to enumerate all created pairs.

## Tips for Liquidity Providers 💡

1.  **Understand Impermanent Loss:** Be aware of the risk associated with price divergence (see [DeFi Mechanics](./defi-mechanics.md#risk-considerations-)).
2.  **Start Small:** If new, provide a smaller amount of liquidity first.
3.  **Monitor:** Keep an eye on the pool's performance and your position.
4.  **Evaluate Rewards:** Ensure potential staking rewards or crafting benefits justify the risks (IL, gas costs).

## Next Steps 👣

With your acquired LP tokens, you can now:

-   [Stake them in ArcaneStaking](./defi-mechanics.md#arcanestaking-system-)
-   [Use them in ArcaneCrafting recipes](./defi-mechanics.md#arcanecrafting-system-)

May your liquidity pools be ever full and profitable! 🌊💰 