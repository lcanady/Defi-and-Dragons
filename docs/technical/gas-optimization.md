# ⚡ The Alchemist's Guide: Gas Optimization

*These ancient scrolls contain the mystical knowledge to minimize the ethereal costs of interacting with our realm.*

## Understanding the Arcane Costs 🔮

Every interaction with our magical realm requires ethereal energy known as "gas." A wise adventurer masters the art of conserving this precious resource.

### The Ethereal Economy

```
Transaction Cost = Gas Used × Gas Price
```

- **Gas Used:** The amount of computational steps required
- **Gas Price:** The cost per unit of gas (in gwei)

## Optimizing Transaction Sequences 📊

### The Art of Batching

When performing multiple related actions, use our batched functions to save gas:

```typescript
// ❌ EXPENSIVE: Separate calls consume more gas
await gameFacade.equipItems(characterId, weaponId, armorId);
await gameFacade.startQuest(characterId, questId);

// ✅ OPTIMAL: Single batched call saves ~40% gas
await gameFacade.batchEquipAndStartQuest(characterId, weaponId, armorId, questId);
```

### Costs of Common Operations

| Operation | Approx. Gas Cost | Optimization Tips |
|-----------|------------------|-------------------|
| Character Creation | 250,000 - 350,000 | Create during low network congestion |
| Equip Items | 100,000 - 150,000 | Batch equipment changes |
| Start Quest | 80,000 - 120,000 | Use batched quest operations |
| Complete Quest | 120,000 - 200,000 | No direct optimization possible |
| List Marketplace Item | 100,000 - 150,000 | Set approval once for all items |
| Purchase Item | 150,000 - 250,000 | Use approval methods optimally |

## The Arcane Approvals 🧙‍♂️

### ERC20 Token Approvals

When interacting with GOLD or LP tokens, optimize your approvals:

```typescript
// ❌ WASTEFUL: Multiple separate approvals
await goldToken.approve(marketplace.address, amount1);
// Later...
await goldToken.approve(marketplace.address, amount2);

// ✅ EFFICIENT: Single large approval
// Set a large allowance once, then use it for multiple transactions
await goldToken.approve(marketplace.address, MAX_UINT256);
```

### ERC1155 Equipment Approvals

For equipment management, optimize authorizations:

```typescript
// ❌ EXPENSIVE: Approving each equipment individually
await equipment.approve(characterWallet.address, equipmentId1);
await equipment.approve(characterWallet.address, equipmentId2);

// ✅ ECONOMICAL: Approve all at once (~60% gas savings)
await equipment.setApprovalForAll(characterWallet.address, true);
```

## Reading vs. Writing ⚖️

### Free Magical Readings

Remember that reading from contracts costs no gas (when called locally):

```typescript
// These are FREE when called from your client
const characterData = await character.getCharacter(characterId);
const questTemplate = await quest.getQuestTemplate(questId);
const equipmentDetails = await equipment.getEquipmentDetails(equipmentId);
```

### Minimizing State Changes

Every state change costs gas. Optimize by using view functions to check conditions before making changes:

```typescript
// ❌ WASTEFUL: Attempting operations that will fail wastes gas
try {
    await quest.completeQuest(characterId, questId);
} catch (error) {
    console.error("Quest completion failed");
}

// ✅ EFFICIENT: Check conditions first (free), then execute
const {isCompleted, progress, target} = await quest.getQuestStatus(characterId, questId);
if (!isCompleted && progress >= target) {
    await quest.completeQuest(characterId, questId);
} else {
    console.log("Quest not ready for completion");
}
```

## Storage Optimization Patterns 📦

Our contracts use these patterns to save gas, and you can leverage them:

### Understanding Slot Packing

Character stats are packed into a single storage slot:

```solidity
// Stats packed into a single 256-bit slot
struct Stats {
    uint8 strength;   // 8 bits
    uint8 agility;    // 8 bits
    uint8 magic;      // 8 bits
    // 232 bits remaining in the slot
}
```

When setting stats, consider that modifying all three at once costs nearly the same as modifying one.

### Character Wallet Pattern

Each character has its own wallet contract. Leverage this pattern:

```typescript
// ❌ SUB-OPTIMAL: Interacting directly with wallets
const walletAddress = await character.characterWallets(characterId);
const wallet = await CharacterWallet.at(walletAddress);
await wallet.equip(weaponId, armorId);

// ✅ OPTIMAL: Use the character interface (~15-20% gas savings)
await character.equip(characterId, weaponId, armorId);
```

## Protocol-Specific Optimizations 🧪

### Marketplace Efficiency

When selling multiple items:

```typescript
// ❌ COSTLY: Separate listings for similar items
await marketplace.listItem(equipmentId, price, 1);
await marketplace.listItem(equipmentId, price, 1);

// ✅ ECONOMICAL: Batch listings of same item (~50% gas savings)
await marketplace.listItem(equipmentId, price, 2);
```

### Quest Optimization

For quest management:

```typescript
// ❌ INEFFICIENT: Starting multiple similar quests
await quest.startQuest(characterId, questId1);
await quest.startQuest(characterId, questId2);

// ✅ EFFICIENT: Focus on one quest at a time, complete before starting new
await quest.startQuest(characterId, questId1);
// Complete first quest before starting another
await quest.completeQuest(characterId, questId1);
await quest.startQuest(characterId, questId2);
```

## Transaction Timing ⏱️

### The Art of Gas Price Selection

Gas prices fluctuate based on network congestion:

```typescript
// Check current network gas prices
const gasPrices = await provider.getFeeData();
console.log(`Current gas price: ${ethers.utils.formatUnits(gasPrices.gasPrice, 'gwei')} gwei`);

// Set optimal gas price based on priority
const tx = await character.mintCharacter(
    walletAddress,
    stats,
    Types.Alignment.STRENGTH,
    {
        gasPrice: gasPrices.gasPrice.mul(85).div(100) // 85% of current price for less urgent tx
    }
);
```

### Day/Night Cycles

Ethereum gas prices often follow patterns:
- Lower prices: Weekends, late night/early morning UTC
- Higher prices: Weekdays during US/EU business hours

Plan non-urgent operations during lower-cost periods.

## Advanced Techniques 🔥

### Event Filtering

When querying for events, use specific filters to reduce RPC data load:

```typescript
// ❌ INEFFICIENT: Querying all events
const allEvents = await character.queryFilter(character.filters.CharacterCreated());

// ✅ EFFICIENT: Specific filters reduce data and cost
const myCharacters = await character.queryFilter(
    character.filters.CharacterCreated(null, walletAddress)
);
```

### Multicall Pattern

For reading multiple values in a single call:

```typescript
// ❌ SLOW: Multiple separate calls
const char1 = await character.getCharacter(id1);
const char2 = await character.getCharacter(id2);
const char3 = await character.getCharacter(id3);

// ✅ FAST: Use multicall utility (requires separate contract or library)
const [char1, char2, char3] = await multicall.aggregate([
    character.populateTransaction.getCharacter(id1),
    character.populateTransaction.getCharacter(id2),
    character.populateTransaction.getCharacter(id3)
]);
```

## Gas Estimation 📈

Before sending transactions, estimate gas costs:

```typescript
// Estimate gas for character creation
const gasEstimate = await character.estimateGas.mintCharacter(
    walletAddress,
    stats,
    Types.Alignment.STRENGTH
);

// Calculate cost in ETH
const gasPrice = await provider.getGasPrice();
const costInWei = gasEstimate.mul(gasPrice);
const costInEth = ethers.utils.formatEther(costInWei);

console.log(`Estimated transaction cost: ${costInEth} ETH`);
```

## The Wallet's Enchantment 💼

Different wallet providers have different gas estimation algorithms:

| Wallet | Gas Estimation | Recommendation |
|--------|----------------|----------------|
| MetaMask | Tends to overestimate | Manually adjust gas limit down by 5-10% |
| WalletConnect | Generally accurate | Use default estimation |
| Coinbase Wallet | Sometimes underestimates | Add 10% buffer to estimates |

## Ritual Debugging 🔍

When a transaction costs more gas than expected, investigate:

1. Check transaction on Etherscan
2. Look for nested contract calls
3. Check for loops processing large data sets
4. Verify quest or combat complexity

```typescript
// Analyze transaction receipt for gas usage
const receipt = await tx.wait();
console.log(`Gas used: ${receipt.gasUsed.toString()}`);

// Compare with estimate
console.log(`Estimate vs Actual: ${gasEstimate.toString()} / ${receipt.gasUsed.toString()}`);
console.log(`Efficiency: ${(gasEstimate.mul(100).div(receipt.gasUsed))}%`);
```

May these sacred gas optimization techniques serve you well on your journey through our mystical realm, brave artificer! Save your eth for potions and equipment, not unnecessary gas! ⚡✨ 