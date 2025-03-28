# 🔧 DeFi Troubleshooting Guide

Even the greatest mages encounter magical mishaps. Here's how to overcome common challenges in your DeFi adventures.

## Common Issues & Solutions 🧩

### Transaction Failures

#### "Insufficient Allowance" Error
```
Error: execution reverted: ERC20: insufficient allowance
```

**Solution:**
1. You need to approve the contract to spend your tokens first:
```javascript
// For staking LP tokens
const lpToken = new ethers.Contract(lpTokenAddress, IERC20ABI, signer);
await lpToken.approve(arcaneStaking.address, ethers.constants.MaxUint256);

// For adding liquidity
await token0.approve(arcaneRouter.address, amount0);
await token1.approve(arcaneRouter.address, amount1);
```

#### "Insufficient Balance" Error
```
Error: execution reverted: ERC20: transfer amount exceeds balance
```

**Solution:**
1. Check your actual token balance:
```javascript
const balance = await token.balanceOf(yourAddress);
console.log(`Balance: ${ethers.utils.formatEther(balance)}`);
```
2. Ensure you're not trying to use more than you have (remember to account for gas)

#### "Minimum Amount" Error
```
Error: execution reverted: InsufficientAAmount or InsufficientBAmount
```

**Solution:**
When adding liquidity, your slippage tolerance may be too low:
```javascript
// Increase your slippage tolerance by lowering minimum amounts
const amountAMin = amountA.mul(95).div(100); // 5% slippage
const amountBMin = amountB.mul(95).div(100); // 5% slippage
```

### Staking Issues

#### "Minimum Staking Time Not Met" Error
```
Error: execution reverted: Minimum staking time not met
```

**Solution:**
1. Check the minimum staking time for your pool:
```javascript
const poolInfo = await arcaneStaking.poolInfo(poolId);
const minTime = poolInfo.minStakingTime.toNumber();
console.log(`Minimum staking time: ${minTime} seconds`);
```
2. Wait until the minimum time has passed:
```javascript
const userInfo = await arcaneStaking.userInfo(poolId, yourAddress);
const stakeTime = userInfo.lastStakeTime.toNumber();
const currentTime = Math.floor(Date.now() / 1000);
const timeLeft = (stakeTime + minTime) - currentTime;
console.log(`Time left: ${timeLeft > 0 ? timeLeft : 0} seconds`);
```

#### "No Rewards Received" Issue

**Problem:** You staked tokens but aren't seeing rewards

**Solution:**
1. Check if you've accrued enough rewards (they may be very small at first):
```javascript
// Get your pending rewards
const pending = await arcaneStaking.pendingReward(poolId, yourAddress);
console.log(`Pending rewards: ${ethers.utils.formatEther(pending)} GOLD`);
```
2. Verify the reward distribution is active:
```javascript
const poolInfo = await arcaneStaking.poolInfo(poolId);
console.log(`Last reward block: ${poolInfo.lastRewardBlock.toString()}`);
console.log(`Current block: ${await provider.getBlockNumber()}`);
```

### Crafting Problems

#### "Crafting Cooldown" Error
```
Error: execution reverted: CraftingCooldown
```

**Solution:**
1. Check when you last crafted this recipe:
```javascript
const lastCraftTime = await arcaneCrafting.lastCraftTime(yourAddress, recipeId);
const recipe = await arcaneCrafting.getRecipe(recipeId);
const cooldownEnds = lastCraftTime.toNumber() + recipe.cooldown.toNumber();
const currentTime = Math.floor(Date.now() / 1000);
const timeLeft = cooldownEnds - currentTime;
console.log(`Cooldown ends in: ${timeLeft > 0 ? timeLeft : 0} seconds`);
```

#### "Invalid Recipe" Error
```
Error: execution reverted: InvalidRecipe
```

**Solution:**
1. Verify the recipe exists and is active:
```javascript
const recipe = await arcaneCrafting.getRecipe(recipeId);
console.log(`Recipe active: ${recipe.isActive}`);
```

## Connection & Wallet Issues 🔌

### MetaMask Not Connecting

**Solutions:**
1. Refresh the page and try again
2. Ensure you're on the correct network
3. Reset your MetaMask account:
   - In MetaMask, go to Settings → Advanced → Reset Account

### Wrong Network

**Solution:**
```javascript
// Request network switch
await window.ethereum.request({
  method: 'wallet_switchEthereumChain',
  params: [{ chainId: '0x1' }], // For Ethereum mainnet
});
```

### High Gas Costs

**Solution:**
1. Consider timing your transactions during low network activity
2. For non-urgent transactions, set a lower gas price:
```javascript
const tx = await contract.function(params, {
  gasPrice: ethers.utils.parseUnits('50', 'gwei') // Lower gas price
});
```

## Impermanent Loss Calculator 📊

If you're experiencing value loss in your LP positions, use this formula to estimate impermanent loss:

```javascript
function calculateImpermanentLoss(priceRatio) {
  // priceRatio = currentPrice / initialPrice
  const sqrt = Math.sqrt(priceRatio);
  const il = 2 * sqrt / (1 + priceRatio) - 1;
  return il * 100; // Return as percentage
}

// Example usage
const initialGoldPrice = 10; // GOLD price when you added liquidity
const currentGoldPrice = 15; // Current GOLD price
const priceRatio = currentGoldPrice / initialGoldPrice;
const loss = calculateImpermanentLoss(priceRatio);
console.log(`Impermanent loss: ${loss.toFixed(2)}%`);
```

## Contract Addresses & Resources 📚

### Main Contracts
- ArcaneStaking: `0x...` (address will be provided at launch)
- ArcaneRouter: `0x...`
- ArcaneCrafting: `0x...`
- GOLD Token: `0x...`

### Block Explorers
- [Etherscan](https://etherscan.io/)
- [Polygonscan](https://polygonscan.com/)

### Support Channels
- [Discord](https://discord.gg/yourdiscord)
- [Telegram](https://t.me/yourtelegram)
- [Forum](https://forum.yourdomain.com)

May your transactions always succeed and your rewards be plentiful! 🧙‍♂️✨ 