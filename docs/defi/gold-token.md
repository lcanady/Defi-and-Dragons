# 🔱 The GOLD Token

Welcome, treasure seeker! The GOLD token is the lifeblood of our magical economy, flowing through every aspect of our game. This document unveils the mysteries of this precious resource.

## Token Overview 🪙

| Attribute | Value |
|-----------|-------|
| Name | Game Token |
| Symbol | GOLD |
| Standard | ERC-20 |
| Total Supply | Dynamic - minted as rewards |
| Contract | `GameToken.sol` |

## Core Functions & Utility 🛠️

GOLD serves as the primary in-game currency with multiple uses:

### Current Utility
- **Staking Rewards**: Earned from providing LP tokens to ArcaneStaking pools
- **Equipment Crafting**: Required for certain high-tier equipment recipes
- **Character Progression**: Used to enhance character abilities
- **Marketplace Currency**: The medium of exchange for in-game items

### Smart Contract Interface

```solidity
interface IGameToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setQuestContract(address questContract, bool authorized) external;
    function setMarketplaceContract(address marketplaceContract, bool authorized) external;
}
```

## Obtaining GOLD 💰

There are currently several ways to acquire GOLD tokens:

1. **LP Staking**: The primary source - stake LP tokens in ArcaneStaking pools
2. **Character Adventures**: Complete quests and battles (coming soon)
3. **Special Events**: Participate in limited-time events (coming soon)

### Example: Claiming Staking Rewards

```javascript
// Claiming GOLD from staking without withdrawing LP tokens
async function harvestRewards(poolId) {
    // Deposit 0 to harvest rewards
    const tx = await arcaneStaking.deposit(poolId, 0);
    const receipt = await tx.wait();
    
    // Get reward amount from event
    const event = receipt.events.find(e => e.event === 'RewardPaid');
    const rewardAmount = event.args.amount;
    
    console.log(`Harvested ${ethers.utils.formatEther(rewardAmount)} GOLD tokens!`);
    return rewardAmount;
}
```

## Tokenomics 📊

### Emission Schedule

GOLD is emitted as staking rewards at the following rates:

| Pool | LP Pair | Emission Rate |
|------|---------|---------------|
| 0 | WETH-GOLD | 1 GOLD per block |
| 1 | USDC-GOLD | 0.5 GOLD per block |
| 2 | WBTC-GOLD | 0.75 GOLD per block |

### Supply Mechanics

- **Minting**: New GOLD is minted through the staking contract as rewards
- **Burning**: GOLD is burned when used for crafting high-tier items or certain marketplace purchases
- **Allocation**: The protocol allocates new emissions based on pool allocation points

## Governance & Control 🏛️

The GOLD token smart contract implements the following security measures:

- **Access Control**: Only authorized addresses can mint or burn tokens
- **Role-Based Permissions**: Using OpenZeppelin's AccessControl
- **Quest Integration**: Special permissions for quest contracts
- **Marketplace Integration**: Designated permissions for marketplace interactions

### Access Structure

- **Owner**: Can configure authorized contracts and mint/burn permissions
- **MINTER_ROLE**: Allowed to mint new tokens (primarily the staking contract)
- **Quest Contracts**: Can trigger reward distribution
- **Marketplace**: Can facilitate transactions and burns

## GOLD in the Game Economy 🌍

GOLD forms the foundation of our in-game economy, creating circular flows:

1. Players provide liquidity to earn GOLD
2. GOLD is spent on crafting powerful items
3. These items enhance characters' abilities
4. More powerful characters can earn more GOLD through gameplay
5. Excess GOLD can be used to create LP tokens, completing the cycle

## Viewing Your Balance 👁️

```javascript
// Check your GOLD balance
async function checkGoldBalance(address) {
    const balance = await goldToken.balanceOf(address);
    console.log(`GOLD Balance: ${ethers.utils.formatEther(balance)}`);
    return balance;
}
```

May your coffers overflow with GOLD, brave adventurer! ✨💰 