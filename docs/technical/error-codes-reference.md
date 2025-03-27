# 🚫 The Troubleshooter's Grimoire: Error Code Reference

*Within these ancient scrolls lie the secrets to understanding the mystical disruptions one may encounter in our realm, along with the sacred remedies to overcome them.*

## Basic Error Types 📜

Our realm uses two types of error mechanisms:

1. **Custom Errors** - Specific, gas-efficient errors defined in contracts
2. **Revert Strings** - Traditional text messages (in older contracts)

## Character Contract Errors 🧙‍♂️

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `NotCharacterOwner` | Attempted action by non-owner | Calling from wrong address | Connect with the correct wallet that owns the character |
| `InvalidCharacter` | Character doesn't exist | Invalid character ID | Verify character ID exists with `character.ownerOf()` |
| `CharacterLocked` | Character cannot perform action | Currently in quest/battle | Wait for current activity to complete |
| `InsufficientLevel` | Character level too low | Attempting advanced content | Complete level-appropriate quests first |
| `StatRequirementsNotMet` | Character stats too low | Insufficient attribute points | Upgrade character stats or equipment |

### Example Detection and Handling

```typescript
try {
    await character.equip(characterId, weaponId, armorId);
} catch (error) {
    if (error.message.includes("NotCharacterOwner")) {
        console.error("You are not the owner of this hero!");
        // Check ownership
        const owner = await character.ownerOf(characterId);
        console.log(`Character ${characterId} is owned by: ${owner}`);
    } else if (error.message.includes("CharacterLocked")) {
        console.error("Your hero is currently engaged in another activity!");
        // Check character state
        const {state} = await character.getCharacter(characterId);
        if (state.questId > 0) {
            console.log(`Hero is on quest ${state.questId} since ${new Date(state.questStartTime * 1000)}`);
        }
    } else {
        console.error("Unknown error:", error);
    }
}
```

## Equipment Contract Errors 🛡️

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `NotEquipmentOwner` | Attempted action by non-owner | Using wrong address | Use the wallet that owns the equipment |
| `InvalidEquipmentType` | Wrong equipment type | Trying to equip weapon as armor | Verify equipment type with `equipment.getEquipmentType()` |
| `EquipmentNotExists` | Equipment doesn't exist | Invalid ID or burned equipment | Check if equipment exists with `equipment.exists()` |
| `InvalidEquipmentState` | Equipment in invalid state | Equipment already equipped | Unequip from other character first |
| `UnauthorizedTransfer` | Transfer not authorized | Missing approval | Call `setApprovalForAll(operator, true)` |

### Example Detection and Handling

```typescript
try {
    await equipment.safeTransferFrom(walletAddress, recipient, equipmentId, amount, "0x");
} catch (error) {
    if (error.message.includes("UnauthorizedTransfer")) {
        console.error("Transfer not authorized!");
        // Set approval
        await equipment.setApprovalForAll(characterWallet.address, true);
        console.log("Approval granted, retry transfer");
    } else if (error.message.includes("InvalidEquipmentState")) {
        console.error("This equipment is currently in use!");
        // Check if equipped
        // First, find which character has it equipped
        // This requires an indexer or events query in a real implementation
        console.log("Unequip the item before transferring");
    } else {
        console.error("Unknown error:", error);
    }
}
```

## Quest Contract Errors 🗺️

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `QuestNotActive` | Quest is inactive | Trying inactive/expired quest | Choose an active quest |
| `QuestAlreadyCompleted` | Quest already done | Trying to complete again | Choose a new quest |
| `QuestNotStarted` | Quest not started | Completing unstarted quest | Start quest before completing |
| `QuestRequirementsNotMet` | Requirements not met | Character too weak | Level up or improve equipment |
| `QuestInProgress` | Quest still in progress | Not enough time elapsed | Wait for quest completion time |
| `QuestCompletionFailed` | Generic completion error | Various quest conditions | Check quest-specific requirements |

### Example Detection and Handling

```typescript
try {
    await quest.completeQuest(characterId, questId);
} catch (error) {
    if (error.message.includes("QuestNotStarted")) {
        console.error("You haven't started this quest yet!");
        // Start the quest
        await quest.startQuest(characterId, questId);
        console.log(`Quest ${questId} started, come back later to complete it`);
    } else if (error.message.includes("QuestInProgress")) {
        console.error("The quest is still in progress!");
        // Check quest timing
        const {state} = await character.getCharacter(characterId);
        const questStartTime = state.questStartTime;
        const now = Math.floor(Date.now() / 1000);
        const questTemplate = await quest.getQuestTemplate(questId);
        const requiredTime = questTemplate.duration;
        const timeLeft = (questStartTime + requiredTime) - now;
        console.log(`Time remaining: ${timeLeft} seconds`);
    } else if (error.message.includes("QuestAlreadyCompleted")) {
        console.error("You've already completed this quest!");
        // Suggest new quests
        const availableQuests = await quest.getAvailableQuests(characterId);
        console.log("Available quests:", availableQuests);
    } else {
        console.error("Unknown error:", error);
    }
}
```

## Marketplace Contract Errors 🏪

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `ItemNotListed` | Item not on market | Invalid listing ID | Verify listing exists with `marketplace.getListing()` |
| `InsufficientBalance` | Not enough GOLD | Trying to buy without funds | Acquire more GOLD tokens |
| `NotItemOwner` | Not the item owner | Listing someone else's item | Use correct owner wallet |
| `ListingCancelled` | Listing no longer active | Item was delisted | Find active listings |
| `PriceMismatch` | Price has changed | Front-end needs refresh | Get updated price from contract |
| `InvalidAmount` | Amount incorrect | Trying to buy too many | Reduce purchase quantity |

### Example Detection and Handling

```typescript
try {
    await marketplace.purchaseItem(equipmentId, listingId, amount);
} catch (error) {
    if (error.message.includes("InsufficientBalance")) {
        console.error("You don't have enough GOLD!");
        // Check balance
        const balance = await goldToken.balanceOf(walletAddress);
        const listing = await marketplace.getListing(equipmentId, listingId);
        const price = listing.price.mul(amount);
        const needed = price.sub(balance);
        console.log(`You need ${ethers.utils.formatEther(needed)} more GOLD`);
    } else if (error.message.includes("ListingCancelled")) {
        console.error("This item is no longer for sale!");
        // Find similar items
        const similarItems = await marketplace.findSimilarItems(equipmentId);
        console.log("Similar items available:", similarItems);
    } else if (error.message.includes("InvalidAmount")) {
        console.error("Invalid purchase amount!");
        // Get available amount
        const listing = await marketplace.getListing(equipmentId, listingId);
        console.log(`Available amount: ${listing.amount}`);
    } else {
        console.error("Unknown error:", error);
    }
}
```

## Social Quest Contract Errors 🤝

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `TeamNotFound` | Team doesn't exist | Invalid team ID | Verify team exists or create new team |
| `TeamFull` | Team at capacity | Maximum members reached | Create new team or wait for opening |
| `NotTeamMember` | Not on team | Contributing to wrong team | Join team before contributing |
| `InvalidContribution` | Bad contribution value | Zero or negative value | Contribute positive value |
| `TeamQuestCompleted` | Quest already done | Trying to contribute late | Join a new team quest |
| `NotTeamLeader` | Not team leader | Only leader can perform action | Request team leader to perform action |

### Example Detection and Handling

```typescript
try {
    await socialQuest.recordContribution(questId, characterId, contributionValue);
} catch (error) {
    if (error.message.includes("NotTeamMember")) {
        console.error("Your character is not on this team!");
        // Find character's teams
        const myTeams = await socialQuest.getCharacterTeams(characterId);
        console.log("Your teams:", myTeams);
    } else if (error.message.includes("TeamQuestCompleted")) {
        console.error("This team quest is already completed!");
        // Check available quests
        const availableTeamQuests = await socialQuest.getAvailableTeamQuests();
        console.log("Available team quests:", availableTeamQuests);
    } else if (error.message.includes("InvalidContribution")) {
        console.error("Invalid contribution value!");
        // Suggest proper contribution
        console.log("Contribution must be positive value");
    } else {
        console.error("Unknown error:", error);
    }
}
```

## ArcaneStaking Contract Errors 💰

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `PoolNotExists` | Pool doesn't exist | Invalid pool ID | Verify pool with `arcaneStaking.poolInfo()` |
| `InsufficientDeposit` | Not enough LP tokens | Withdrawing too much | Check balance with `arcaneStaking.userInfo()` |
| `MinStakingTimeNotMet` | Staking time too short | Early withdrawal attempt | Check `lastStakeTime` and `minStakingTime` |
| `RewardNotReady` | Reward not available | Too soon after deposit | Wait for rewards to accumulate |
| `EmergencyWithdrawalFailed` | Emergency failure | Contract issue | Contact support for assistance |
| `PoolPaused` | Pool operations paused | Maintenance or security | Wait for pool to resume or try different pool |

### Example Detection and Handling

```typescript
try {
    await arcaneStaking.withdraw(poolId, amount);
} catch (error) {
    if (error.message.includes("InsufficientDeposit")) {
        console.error("You don't have enough LP tokens staked!");
        // Check staked balance
        const userInfo = await arcaneStaking.userInfo(poolId, walletAddress);
        console.log(`You have ${userInfo.amount} LP tokens staked`);
    } else if (error.message.includes("MinStakingTimeNotMet")) {
        console.error("You need to stake for longer!");
        // Check timing
        const userInfo = await arcaneStaking.userInfo(poolId, walletAddress);
        const poolInfo = await arcaneStaking.poolInfo(poolId);
        const now = Math.floor(Date.now() / 1000);
        const timeStaked = now - userInfo.lastStakeTime;
        const timeRequired = poolInfo.minStakingTime;
        const timeLeft = timeRequired - timeStaked;
        console.log(`You need to wait ${timeLeft} more seconds`);
    } else if (error.message.includes("PoolPaused")) {
        console.error("This staking pool is currently paused!");
        // Check other pools
        const poolCount = await arcaneStaking.poolLength();
        console.log(`Try one of the other ${poolCount - 1} pools`);
    } else {
        console.error("Unknown error:", error);
    }
}
```

## ArcaneCrafting Contract Errors ⚒️

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `RecipeNotFound` | Recipe doesn't exist | Invalid recipe ID | Check available recipes |
| `InsufficientMaterials` | Missing materials | Not enough LP tokens | Acquire more tokens in required type |
| `RecipeLevelTooHigh` | Recipe level too high | Character level too low | Level up character first |
| `CraftingCooldown` | Crafting cooldown active | Crafting too frequently | Wait for cooldown to expire |
| `InvalidRecipeState` | Recipe state issue | Recipe disabled temporarily | Try different recipe |
| `RarityRollFailed` | Rarity roll failed | Random generation issue | Retry crafting operation |

### Example Detection and Handling

```typescript
try {
    await arcaneCrafting.craftItem(recipeId);
} catch (error) {
    if (error.message.includes("InsufficientMaterials")) {
        console.error("You don't have enough materials!");
        // Check required materials
        const recipe = await arcaneCrafting.getRecipe(recipeId);
        const requiredTokens = recipe.requiredTokens;
        console.log("Required materials:");
        for (const token of requiredTokens) {
            const balance = await IERC20.at(token.address).balanceOf(walletAddress);
            console.log(`- ${token.name}: Have ${balance}, Need ${token.amount}`);
        }
    } else if (error.message.includes("RecipeLevelTooHigh")) {
        console.error("Your character's level is too low for this recipe!");
        // Check level requirements
        const recipe = await arcaneCrafting.getRecipe(recipeId);
        const {state} = await character.getCharacter(characterId);
        console.log(`Recipe requires level ${recipe.requiredLevel}, your character is level ${state.level}`);
    } else if (error.message.includes("CraftingCooldown")) {
        console.error("Crafting cooldown active!");
        // Check cooldown time
        const cooldownEnd = await arcaneCrafting.getCooldownEnd(walletAddress);
        const now = Math.floor(Date.now() / 1000);
        const timeLeft = cooldownEnd - now;
        console.log(`Cooldown ends in ${timeLeft} seconds`);
    } else {
        console.error("Unknown error:", error);
    }
}
```

## Chain-Related Errors ⛓️

| Error Code | Description | Typical Cause | Solution |
|------------|-------------|---------------|----------|
| `EthUnsafeCall` | Reentrant call detected | Malicious contract | Use legitimate contracts only |
| `OutOfGas` | Transaction ran out of gas | Gas limit too low | Increase gas limit for complex operations |
| `NetworkCongested` | Network congestion | High blockchain activity | Retry during lower congestion period |
| `Underpriced` | Gas price too low | Gas price below network min | Increase gas price |
| `Nonce too low` | Incorrect nonce | Transaction ordering issue | Reset wallet connection or use proper nonce |
| `User rejected` | User cancelled | User denied in wallet | Confirm transaction in wallet |

### Example Detection and Handling

```typescript
try {
    const tx = await character.mintCharacter(
        walletAddress,
        stats,
        Types.Alignment.STRENGTH
    );
    await tx.wait();
} catch (error) {
    if (error.message.includes("gas required exceeds allowance")) {
        console.error("Transaction needs more gas!");
        // Retry with higher gas limit
        const gasEstimate = await character.estimateGas.mintCharacter(
            walletAddress,
            stats,
            Types.Alignment.STRENGTH
        );
        const higherGas = gasEstimate.mul(120).div(100); // 20% extra
        console.log(`Retrying with higher gas limit: ${higherGas.toString()}`);
    } else if (error.message.includes("nonce")) {
        console.error("Nonce issue detected!");
        // Reset connection
        console.log("Please disconnect and reconnect your wallet");
    } else if (error.message.includes("user rejected")) {
        console.error("You rejected the transaction!");
        console.log("Please approve the transaction in your wallet");
    } else {
        console.error("Unknown chain error:", error);
    }
}
```

## Error Decode Ritual 🔍

When encountering an unknown error, use this magical ritual to decode it:

```typescript
function decodeError(error) {
    // Extract error signature from message
    const errorMsg = error.message;
    
    // Check for custom error patterns
    if (errorMsg.includes("custom error")) {
        // Foundry/Hardhat style error
        const match = errorMsg.match(/execution reverted: (.*?)(?:\(.*\))?$/);
        if (match) {
            return {
                name: match[1].trim(),
                args: extractErrorArgs(errorMsg)
            };
        }
    }
    
    // Check for revert strings
    if (errorMsg.includes("reverted with reason string")) {
        const match = errorMsg.match(/'([^']*)'/);
        if (match) {
            return {
                name: "RevertString",
                message: match[1]
            };
        }
    }
    
    // Check for known error patterns
    const knownErrors = {
        "gas required exceeds": "OutOfGas",
        "nonce too low": "NonceTooLow",
        "already known": "TransactionAlreadyKnown",
        "always failing": "AlwaysFailingTransaction",
        "user rejected": "UserRejected"
    };
    
    for (const [pattern, errorName] of Object.entries(knownErrors)) {
        if (errorMsg.includes(pattern)) {
            return {
                name: errorName,
                message: errorMsg
            };
        }
    }
    
    // Unknown error
    return {
        name: "UnknownError",
        message: errorMsg
    };
}

function extractErrorArgs(errorMsg) {
    const argsMatch = errorMsg.match(/\((.*)\)/);
    if (!argsMatch) return [];
    
    // Split by comma but respect nested structures
    const args = [];
    let current = "";
    let depth = 0;
    
    for (const char of argsMatch[1]) {
        if (char === ',' && depth === 0) {
            args.push(current.trim());
            current = "";
        } else {
            if (char === '(' || char === '[' || char === '{') depth++;
            if (char === ')' || char === ']' || char === '}') depth--;
            current += char;
        }
    }
    
    if (current.trim()) {
        args.push(current.trim());
    }
    
    return args;
}

// Example usage:
try {
    await character.equip(characterId, weaponId, armorId);
} catch (error) {
    const decodedError = decodeError(error);
    console.log("Decoded error:", decodedError);
    
    // Handle based on error name
    switch (decodedError.name) {
        case "NotCharacterOwner":
            console.error("You don't own this character!");
            break;
        case "InvalidEquipmentType":
            console.error("Wrong equipment type!");
            break;
        default:
            console.error("Unknown error:", decodedError.message);
    }
}
```

May these ancient scrolls guide you through the mystical errors of our realm and help you continue your adventure without disruption! 📜✨ 