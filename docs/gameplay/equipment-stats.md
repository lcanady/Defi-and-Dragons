# ⚒️ Crafting & Equipment Guide

Welcome, master artisan! The ancient art of crafting powerful equipment using LP tokens awaits you. In this guide, you will learn how to forge magical items that will enhance your character's capabilities.

## Understanding Equipment Stats 📊

Each piece of equipment provides stat bonuses to your character:

```solidity
struct PackedEquipmentStats {
    uint8 strengthBonus;    // Bonus to strength (0-255)
    uint8 agilityBonus;     // Bonus to agility (0-255)
    uint8 magicBonus;       // Bonus to magic (0-255)
    bool isActive;          // Whether the equipment is active
    Types.Alignment statAffinity;  // Primary stat alignment
    string name;            // Equipment name
    string description;     // Equipment description
}
```

### Stat Bonuses

Equipment bonuses directly enhance your character's base stats:
- **Strength**: Increases physical damage and carrying capacity
- **Agility**: Improves dodge chance and attack speed
- **Magic**: Enhances spell power and mana regeneration

### Alignment Affinity

Equipment has an alignment that makes it more effective for certain character classes:
- **STRENGTH**: Ideal for warriors and barbarians
- **AGILITY**: Perfect for rogues and rangers
- **MAGIC**: Best suited for mages and clerics
- **BALANCED**: Equally effective for all character types

## LP Token Crafting Recipes 🧪

Our current crafting system requires LP tokens as the primary material. These mystical tokens contain the essence of liquidity, imbuing your equipment with special properties.

### Currently Available Equipment

| Equipment ID | Name | Description | Strength | Agility | Magic | Required LP Tokens | Pool |
|--------------|------|-------------|----------|---------|-------|-------------------|------|
| 1 | Ethereal Blade | A sword forged from the essence of liquidity | +5 | +2 | +0 | 50 WETH-GOLD LP | 0 |
| 2 | Stable Pendant | A necklace that protects against market volatility | +1 | +1 | +5 | 25 USDC-GOLD LP | 1 |
| 3 | Golden Gauntlets | Armored gloves infused with digital gold | +4 | +3 | +0 | 10 WBTC-GOLD LP | 2 |
| 4 | Liquidity Staff | A staff that channels the power of pooled assets | +0 | +1 | +7 | 40 USDC-GOLD LP | 1 |
| 5 | Trader's Helm | A helmet that grants market insight | +3 | +4 | +1 | 30 WETH-GOLD LP | 0 |

## Crafting Process 🛠️

To craft equipment using LP tokens:

### 1. Check Recipe Requirements

```javascript
async function checkRecipeRequirements(recipeId) {
    // Get recipe details
    const recipe = await arcaneCrafting.getRecipe(recipeId);
    
    // Display requirements
    console.log(`Recipe ${recipeId}: ${recipe.resultingItemId}`);
    console.log(`Required LP Token: ${recipe.lpToken}`);
    console.log(`LP Amount: ${ethers.utils.formatEther(recipe.lpTokenAmount)}`);
    
    // Check if user has enough LP tokens
    const lpToken = new ethers.Contract(recipe.lpToken, IERC20ABI, signer);
    const balance = await lpToken.balanceOf(walletAddress);
    
    console.log(`Your Balance: ${ethers.utils.formatEther(balance)}`);
    console.log(`Can Craft: ${balance.gte(recipe.lpTokenAmount)}`);
    
    return balance.gte(recipe.lpTokenAmount);
}
```

### 2. Approve Token Spending

```javascript
async function approveTokensForCrafting(recipeId) {
    const recipe = await arcaneCrafting.getRecipe(recipeId);
    const lpToken = new ethers.Contract(recipe.lpToken, IERC20ABI, signer);
    
    // Approve crafting contract to use LP tokens
    const tx = await lpToken.approve(arcaneCrafting.address, recipe.lpTokenAmount);
    await tx.wait();
    
    console.log(`Approved ${ethers.utils.formatEther(recipe.lpTokenAmount)} LP tokens for crafting`);
}
```

### 3. Craft the Item

```javascript
async function craftEquipment(recipeId) {
    // Craft the item
    const tx = await arcaneCrafting.craftItem(recipeId);
    const receipt = await tx.wait();
    
    // Get item ID from event
    const event = receipt.events.find(e => e.event === 'ItemCrafted');
    const equipmentId = event.args.itemId;
    
    console.log(`Successfully crafted item ${equipmentId}!`);
    return equipmentId;
}
```

## Equipment & Character Performance 🏆

The equipment you craft can significantly improve your character's performance:

### Combat Benefits

- **Higher Damage**: Strength-boosting equipment increases damage output
- **Better Survivability**: Balanced stats equipment improves overall resilience
- **Spell Effectiveness**: Magic-focused items enhance spell power
- **Attack Speed**: Agility items increase your attack frequency

### Comparison: Base vs. Equipped Character

| Stat | Base Character | With Ethereal Blade | With Full Equipment Set |
|------|----------------|---------------------|-------------------------|
| Strength | 10 | 15 (+50%) | 23 (+130%) |
| Agility | 10 | 12 (+20%) | 21 (+110%) |
| Magic | 10 | 10 (0%) | 23 (+130%) |
| DPS | 100 | 150 (+50%) | 275 (+175%) |
| Health | 100 | 110 (+10%) | 150 (+50%) |

## Cooldowns & Limitations ⏱️

Be aware of the following restrictions on crafting:

- Each recipe has a cooldown period (typically 1-24 hours)
- Some high-tier equipment requires additional rare materials
- Crafted equipment is bound to your account and cannot be transferred
- Equipment durability may decrease over time, requiring repairs

## Strategy Tips 💡

- **Match Alignment**: Craft equipment that matches your character's primary stat
- **Balance Stats**: Don't focus too much on one stat at the expense of others
- **Consider LP Value**: Calculate whether the LP tokens are worth more staking or crafting
- **Plan Ahead**: Some equipment requires LP tokens from different pools

May your crafting yield legendary items, brave adventurer! ⚔️✨ 