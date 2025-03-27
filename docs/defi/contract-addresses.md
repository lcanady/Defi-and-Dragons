# 📜 Contract Addresses & Technical Details

Welcome, technical adept! This scroll contains the arcane addresses and deployment details of our mystical contracts.

## Core Contract Addresses 🔮

| Contract | Address | Network | Deployment Date |
|----------|---------|---------|----------------|
| GameToken (GOLD) | `0xGOLD...` | Ethereum | TBD |
| ArcaneStaking | `0xStaking...` | Ethereum | TBD |
| ArcaneRouter | `0xRouter...` | Ethereum | TBD |
| ArcaneCrafting | `0xCrafting...` | Ethereum | TBD |
| ArcaneFactory | `0xFactory...` | Ethereum | TBD |
| Equipment | `0xEquip...` | Ethereum | TBD |
| Character | `0xChar...` | Ethereum | TBD |

## Blockchain Explorer Links 🔍

### Ethereum Mainnet
- [GameToken Contract](https://etherscan.io/address/0xGOLD...)
- [ArcaneStaking Contract](https://etherscan.io/address/0xStaking...)
- [ArcaneRouter Contract](https://etherscan.io/address/0xRouter...)
- [ArcaneCrafting Contract](https://etherscan.io/address/0xCrafting...)
- [ArcaneFactory Contract](https://etherscan.io/address/0xFactory...)
- [Equipment Contract](https://etherscan.io/address/0xEquip...)
- [Character Contract](https://etherscan.io/address/0xChar...)

### Test Networks
- Goerli Testnet: [GameToken](https://goerli.etherscan.io/address/0xTestGOLD...)
- Sepolia Testnet: [GameToken](https://sepolia.etherscan.io/address/0xTestGOLD...)

## Contract Interfaces 📋

### GameToken (GOLD)

```solidity
interface IGameToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setQuestContract(address questContract, bool authorized) external;
    function setMarketplaceContract(address marketplaceContract, bool authorized) external;
}
```

### ArcaneStaking

```solidity
struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 lastStakeTime;
}

struct PoolInfo {
    IERC20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accRewardPerShare;
    uint256 totalStaked;
    uint256 minStakingTime;
}

interface IArcaneStaking {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function emergencyWithdraw(uint256 _pid) external;
}
```

### ArcaneCrafting

```solidity
struct Recipe {
    uint256 recipeId;
    uint256 resultingItemId;
    address lpToken;
    uint256 lpTokenAmount;
    address[] resources;
    uint256[] resourceAmounts;
    uint256 cooldown;
    bool isActive;
}

interface IArcaneCrafting {
    function craftItem(uint256 _recipeId) external;
    function getRecipe(uint256 _recipeId) external view returns (Recipe memory);
}
```

## Deployment Configuration ⚙️

### Current Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| GOLD Emission Rate | 1.0 GOLD/block | Base emission rate |
| Pool 0 Allocation | 40 | 40% of emissions |
| Pool 1 Allocation | 30 | 30% of emissions |
| Pool 2 Allocation | 20 | 20% of emissions |
| Reserved Allocation | 10 | 10% for future pools |
| Min Stake Time Pool 0 | 86400 | 1 day in seconds |
| Min Stake Time Pool 1 | 43200 | 12 hours in seconds |
| Min Stake Time Pool 2 | 172800 | 2 days in seconds |

### Current Pool Details

| Pool ID | LP Token | Contract Address | Total Staked | APR |
|---------|----------|------------------|--------------|-----|
| 0 | WETH-GOLD | `0xWETHGOLD...` | TBD | ~45% |
| 1 | USDC-GOLD | `0xUSDCGOLD...` | TBD | ~35% |
| 2 | WBTC-GOLD | `0xWBTCGOLD...` | TBD | ~40% |

## Audit Status & Security 🔒

| Contract | Audit Status | Auditor | Report Link |
|----------|--------------|---------|-------------|
| GameToken | Pending | TBD | TBD |
| ArcaneStaking | Pending | TBD | TBD |
| ArcaneRouter | Pending | TBD | TBD |
| ArcaneCrafting | Pending | TBD | TBD |
| ArcaneFactory | Pending | TBD | TBD |
| Equipment | Pending | TBD | TBD |
| Character | Pending | TBD | TBD |

### Security Features

- Timelock for critical parameter changes: 24 hours
- Multi-signature requirement for admin functions: 2-of-3
- Emergency withdrawal functionality: Enabled
- Pause functionality: Enabled for all contracts

## Transaction Fee Structure 💸

| Action | Fee | Recipient |
|--------|-----|-----------|
| Swap | 0.3% | LP Providers |
| LP Token Withdrawal (before min time) | 1% | ArcaneStaking |
| Equipment Crafting | 0% | None |

## Gas Optimization Tips ⛽

- Use the "Claim All" function to harvest rewards from multiple pools in one transaction
- Craft equipment during low gas periods (usually weekends)
- Approve tokens with large allowances to save on future approval transactions
- Use the emergencyWithdraw function only in critical situations as it forfeits rewards

## Technical Support & Resources 🛠️

- GitHub Repository: [github.com/defi-dragons](https://github.com/your-repo-url)
- Developer Documentation: [docs.defi-dragons.io](https://docs.your-project.io)
- Technical Support: [tech@defi-dragons.io](mailto:tech@your-project.io)
- Discord Developer Channel: [#dev-support](https://discord.gg/your-discord)

May your code compile without errors and your gas fees be low, brave developer! 🧙‍♂️💻 