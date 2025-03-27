# 💫 Acquiring LP Tokens

Welcome, aspiring liquidity provider! Before you can stake tokens in our sacred pools or craft mystical equipment, you must first obtain the necessary LP tokens. This guide will show you how.

## Understanding LP Tokens 🧠

LP (Liquidity Provider) tokens are special receipts you receive when you provide liquidity to a trading pair in our Arcane AMM. These tokens represent your share of the liquidity pool and can be:

1. Staked in our ArcaneStaking pools to earn GOLD rewards
2. Used as crafting materials for powerful equipment
3. Redeemed later to withdraw your original tokens (plus or minus trading fees and impermanent loss)

## Step-by-Step Guide to Providing Liquidity 🔄

### 1. Prepare Your Tokens

First, you need both tokens in the trading pair. For example, to get WETH-GOLD LP tokens:

```javascript
// Check your balances
const wethBalance = await weth.balanceOf(yourAddress);
const goldBalance = await gold.balanceOf(yourAddress);

// Make sure you have sufficient amounts of both tokens
console.log(`WETH Balance: ${ethers.utils.formatEther(wethBalance)}`);
console.log(`GOLD Balance: ${ethers.utils.formatEther(goldBalance)}`);
```

### 2. Approve the Router

Before adding liquidity, you need to approve the router to spend your tokens:

```javascript
// Approve router to spend your tokens
await weth.approve(arcaneRouter.address, amountWETH);
await gold.approve(arcaneRouter.address, amountGOLD);
```

### 3. Add Liquidity

Now you can provide liquidity and receive LP tokens:

```javascript
// Parameters
const tokenA = weth.address;
const tokenB = gold.address;
const amountADesired = ethers.utils.parseEther("1"); // 1 WETH
const amountBDesired = ethers.utils.parseEther("100"); // 100 GOLD
const amountAMin = ethers.utils.parseEther("0.95"); // 0.95 WETH minimum
const amountBMin = ethers.utils.parseEther("95"); // 95 GOLD minimum
const recipient = yourAddress;

// Add liquidity
const tx = await arcaneRouter.addLiquidity(
    tokenA,
    tokenB,
    amountADesired,
    amountBDesired,
    amountAMin,
    amountBMin,
    recipient
);

// Wait for transaction confirmation
const receipt = await tx.wait();
console.log("Liquidity added successfully!");
```

### 4. Check Your LP Tokens

After providing liquidity, you'll receive LP tokens that represent your share of the pool:

```javascript
// Get the LP token address
const pairAddress = await arcaneFactory.getPair(weth.address, gold.address);
const lpToken = new ethers.Contract(pairAddress, ArcaneABI, signer);

// Check your LP token balance
const lpBalance = await lpToken.balanceOf(yourAddress);
console.log(`LP Token Balance: ${ethers.utils.formatEther(lpBalance)}`);
```

## Available Trading Pairs 🏦

We currently support the following trading pairs for LP tokens:

| Pair | Tokens | Pool ID for Staking |
|------|--------|---------------------|
| WETH-GOLD | Wrapped ETH + GOLD | 0 |
| USDC-GOLD | USDC + GOLD | 1 |
| WBTC-GOLD | Wrapped BTC + GOLD | 2 |

## Understanding Impermanent Loss Risk ⚠️

When providing liquidity, be aware of impermanent loss:

- **What it is**: Potential loss compared to simply holding tokens when price ratio changes
- **Example**: If you deposit equal values of GOLD and ETH, and GOLD price rises significantly, you'll have less GOLD and more ETH compared to if you had just held both
- **When it matters**: The more volatile the pair and the greater the price change, the higher the impermanent loss

## Tips for New Liquidity Providers 💡

1. **Start small**: Begin with a small amount until you're comfortable with the process
2. **Choose your pair wisely**: Lower volatility pairs typically have less impermanent loss
3. **Monitor your position**: Check your LP tokens and pool status regularly
4. **Calculate returns**: Make sure staking rewards or crafting benefits outweigh potential impermanent loss

## Next Steps 👣

Now that you have LP tokens, you can:
- [Stake them for GOLD rewards](index.md#channeling-your-power)
- [Craft powerful equipment](index.md#the-mystic-forge)

May your liquidity pools be ever full and profitable! 🌊💰 