# 🔮 The Arcane Connection: DeFi & Gameplay Basics

*Within these sacred scrolls lies the knowledge of how our mystical realm interacts with decentralized finance. Here, brave adventurer, you'll learn the fundamentals of our DeFi features.*

## The Core Mechanism 🌉

Our game currently integrates with DeFi through a simple but powerful mechanism: LP token staking. This foundational feature allows you to:

1. Stake LP tokens in our ArcaneStaking pools
2. Earn GOLD token rewards over time
3. Use these rewards within the game ecosystem

## ArcaneStaking System 🏦

The primary DeFi feature currently implemented is our ArcaneStaking contract:

```solidity
struct PoolInfo {
    IERC20 lpToken;              // The LP token staked
    uint256 allocPoint;          // Allocation points for this pool
    uint256 lastRewardBlock;     // Last block rewards were calculated
    uint256 accRewardPerShare;   // Accumulated rewards per share
    uint256 totalStaked;         // Total LP tokens staked
    uint256 minStakingTime;      // Minimum staking period
}

struct UserInfo {
    uint256 amount;         // LP tokens staked by user
    uint256 rewardDebt;     // Reward debt calculation
    uint256 lastStakeTime;  // Timestamp of last stake
}
```

### Staking Your LP Tokens

To participate in our staking system:

```typescript
// Stake LP tokens in a pool
async function stakeLP(poolId, amount) {
    // Get LP token address for this pool
    const poolInfo = await arcaneStaking.poolInfo(poolId);
    const lpToken = new ethers.Contract(poolInfo.lpToken, IERC20ABI, signer);
    
    // Approve staking contract to spend LP tokens
    await lpToken.approve(arcaneStaking.address, amount);
    
    // Stake tokens
    await arcaneStaking.deposit(poolId, amount);
    
    console.log(`Staked ${ethers.utils.formatEther(amount)} LP tokens in pool ${poolId}`);
}
```

### Claiming Your Rewards

Harvest your earned GOLD tokens:

```typescript
// Claim staking rewards
async function harvestRewards(poolId) {
    // Call deposit with 0 amount to harvest rewards
    await arcaneStaking.deposit(poolId, 0);
    
    // Check new pending rewards
    const pendingReward = await arcaneStaking.pendingReward(poolId, walletAddress);
    console.log(`Rewards harvested. New pending rewards: ${ethers.utils.formatEther(pendingReward)} GOLD`);
}
```

### Withdrawing Your LP Tokens

When you're ready to withdraw:

```typescript
// Withdraw LP tokens from a pool
async function withdrawLP(poolId, amount) {
    // Check staking time requirements
    const userInfo = await arcaneStaking.userInfo(poolId, walletAddress);
    const poolInfo = await arcaneStaking.poolInfo(poolId);
    const now = Math.floor(Date.now() / 1000);
    const stakingTime = now - userInfo.lastStakeTime;
    
    if (stakingTime < poolInfo.minStakingTime) {
        console.error(`Cannot withdraw yet. Need to stake for ${poolInfo.minStakingTime} seconds. Currently staked for ${stakingTime} seconds.`);
        return;
    }
    
    // Withdraw tokens
    await arcaneStaking.withdraw(poolId, amount);
    console.log(`Withdrawn ${ethers.utils.formatEther(amount)} LP tokens from pool ${poolId}`);
}
```

## LP Token Crafting ⚒️

Our second DeFi feature allows you to use LP tokens to craft in-game equipment:

```solidity
struct Recipe {
    uint256 requiredLevel;      // Character level needed
    IERC20[] requiredTokens;    // LP tokens required
    uint256[] requiredAmounts;  // Amount of each token
    uint256 cooldown;           // Crafting cooldown period
    bool active;                // Whether recipe is active
}
```

### Crafting Equipment

```typescript
// Craft equipment using LP tokens
async function craftBasicEquipment(recipeId) {
    // Get recipe details
    const recipe = await arcaneCrafting.getRecipe(recipeId);
    
    // Check LP token requirements (simplified)
    const lpToken = new ethers.Contract(recipe.requiredTokens[0], IERC20ABI, signer);
    const balance = await lpToken.balanceOf(walletAddress);
    
    if (balance.lt(recipe.requiredAmounts[0])) {
        console.error(`Insufficient LP tokens! Have ${ethers.utils.formatEther(balance)}, need ${ethers.utils.formatEther(recipe.requiredAmounts[0])}`);
        return;
    }
    
    // Approve crafting contract
    await lpToken.approve(arcaneCrafting.address, recipe.requiredAmounts[0]);
    
    // Craft the item
    const tx = await arcaneCrafting.craftItem(recipeId);
    const receipt = await tx.wait();
    
    // Get equipment ID from event
    const event = receipt.events.find(e => e.event === 'ItemCrafted');
    const equipmentId = event.args.equipmentId;
    
    console.log(`Successfully crafted equipment! ID: ${equipmentId}`);
    return equipmentId;
}
```

## Current Pool Information 📊

We currently offer the following staking pools:

| Pool ID | LP Token | Reward Rate | Min Staking Time |
|---------|----------|-------------|------------------|
| 0 | WETH-GOLD | 1 GOLD/block | 1 day |
| 1 | USDC-GOLD | 0.5 GOLD/block | 12 hours |
| 2 | WBTC-GOLD | 0.75 GOLD/block | 2 days |

## Understanding Impermanent Loss ⚠️

When providing liquidity to get LP tokens, be aware of impermanent loss:

```
Impermanent Loss happens when the price of your tokens changes compared to when you deposited them in the pool.
```

A simplified explanation:

1. You deposit equal values of GOLD and ETH into a pool
2. If GOLD price rises compared to ETH, you'll have less GOLD and more ETH
3. If you had just held, you would have more total value
4. This difference is impermanent loss

## Risk Considerations 🛡️

Be aware of these risks when using our DeFi features:

1. **Smart Contract Risk**: Despite audits, contracts may have vulnerabilities
2. **Impermanent Loss**: As explained above
3. **Token Price Volatility**: GOLD token price may fluctuate
4. **Gas Costs**: Transaction fees can be significant during network congestion

## Upcoming Features 🔮

While our current DeFi integration is straightforward, we plan to expand with:

- Protocol quests for popular DeFi platforms
- DeFi action tracking for character abilities
- Cross-chain support
- Advanced LP token crafting recipes

Stay tuned for announcements as we develop these features!

May your staking be profitable and your crafted items powerful, brave adventurer! 💰✨ 