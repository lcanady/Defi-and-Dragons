# Troubleshooting Guide 🛠️

Fear not, brave adventurer! Even the mightiest heroes encounter challenges. Here's how to overcome common obstacles in your journey.

## 🎭 Character Issues

### Character Creation Failed
```solidity
Error: InsufficientFunds
```
**Solution:**
1. Ensure you have enough ETH for gas
2. Check if you have approved the required $GOLD tokens
3. Verify your wallet is connected to the correct network

### Can't Equip Items
```solidity
Error: NotWeaponOwner or NotArmorOwner
```
**Solution:**
1. Verify item ownership in your inventory
2. Check character level requirements
3. Ensure items aren't locked in another contract

## ⚔️ Combat Problems

### Move Execution Failed
```solidity
Error: CooldownActive
```
**Solution:**
1. Wait for the cooldown period to end
2. Check your character's status effects
3. Verify combat eligibility

### Damage Not Registering
```solidity
Error: InvalidTarget
```
**Solution:**
1. Confirm target exists and is active
2. Check range requirements
3. Verify combat instance is still active

## 🎯 Quest Issues

### Can't Start Quest
```solidity
Error: InsufficientLevel
```
**Solution:**
1. Check quest level requirements
2. Verify stat requirements
3. Complete prerequisite quests if needed

### Quest Progress Not Updating
```solidity
Error: InvalidEvidence
```
**Solution:**
1. Ensure actions match quest requirements
2. Check transaction confirmation
3. Verify quest hasn't expired

## 🌊 DeFi Integration

### Staking Failed
```solidity
Error: InsufficientAllowance
```
**Solution:**
1. Approve token spending
2. Check token balance
3. Verify minimum staking amount

### Crafting Failed
```solidity
Error: InsufficientResources
```
**Solution:**
1. Check LP token balance
2. Verify resource availability
3. Ensure recipe is still active

## 🎮 Technical Issues

### Transaction Stuck
```
Pending Transaction...
```
**Solution:**
1. Check gas price
2. Consider speed up transaction
3. Wait for network congestion to clear

### Contract Interaction Failed
```solidity
Error: ContractNotInitialized
```
**Solution:**
1. Verify contract deployment
2. Check network connection
3. Ensure contracts are properly linked

## 🔮 Common Error Codes

### Error: INSUFFICIENT_BALANCE
```solidity
require(balance >= amount, "INSUFFICIENT_BALANCE")
```
**Solution:**
- Check token balance
- Verify transaction amount
- Account for fees

### Error: INVALID_SIGNATURE
```solidity
require(recoveredAddress == signer, "INVALID_SIGNATURE")
```
**Solution:**
- Reconnect wallet
- Clear browser cache
- Update wallet software

## 🆘 Emergency Procedures

### Stuck Funds
1. Use emergency withdrawal function
```solidity
await arcaneStaking.emergencyWithdraw(poolId);
```

### Compromised Account
1. Transfer items to safe wallet
2. Contact support immediately
3. Use timelock if available

## 🔍 Debugging Tools

### Check Character State
```solidity
const state = await character.getCharacter(characterId);
console.log('Character State:', state);
```

### Verify Quest Progress
```solidity
const progress = await quest.getProgress(questId);
console.log('Quest Progress:', progress);
```

### Monitor Events
```solidity
const filter = contract.filters.QuestCompleted(characterId);
const events = await contract.queryFilter(filter);
```

## 📞 Support Channels

If you're still stuck:

1. Join our [Discord](https://discord.gg/defi-dragons)
2. Check the [GitHub Issues](https://github.com/defi-dragons/issues)
3. Contact Support: support@defi-dragons.com

Remember: every hero faces challenges. It's how we overcome them that defines our legend! 🗡️✨ 