# 📊 The Master Artificer's Guide: Complex Examples

*These ancient scrolls contain powerful incantations for the most complex magical operations in our realm. Study them well, brave artificer!*

## Crafting a Complete Adventure 🌟

This comprehensive example demonstrates how to create a hero, equip them, embark on a quest, and claim rewards.

```typescript
// The Complete Hero's Journey
async function heroJourney() {
    // 1. Create a new character
    const characterId = await createCharacter();
    
    // 2. Get basic equipment
    const {weaponId, armorId} = await acquireBasicEquipment();
    
    // 3. Equip your character
    await equipHero(characterId, weaponId, armorId);
    
    // 4. Start a quest
    await beginQuest(characterId);
    
    // 5. Wait for quest completion (simplified)
    await simulateQuestCompletion();
    
    // 6. Claim rewards
    await claimQuestRewards(characterId);
}

// 1. Character Creation
async function createCharacter() {
    // Generate balanced stats
    const stats = {
        strength: 15,
        agility: 15,
        magic: 15
    };
    
    // Create the character
    const tx = await character.mintCharacter(
        walletAddress,
        stats,
        Types.Alignment.STRENGTH
    );
    
    // Wait for transaction confirmation
    const receipt = await tx.wait();
    
    // Extract character ID from event
    const event = receipt.events.find(e => e.event === 'CharacterCreated');
    const characterId = event.args.tokenId;
    
    console.log(`New hero created! ID: ${characterId}`);
    return characterId;
}

// 2. Get basic equipment
async function acquireBasicEquipment() {
    // For demonstration, we'll mint new equipment
    // In a real game, this might come from starter packs or initial quests
    
    // Mint a basic weapon
    const weaponTx = await equipment.mintEquipment(
        walletAddress,
        Types.EquipmentType.WEAPON,
        Types.Rarity.COMMON,
        1  // Amount
    );
    const weaponReceipt = await weaponTx.wait();
    const weaponEvent = weaponReceipt.events.find(e => e.event === 'EquipmentMinted');
    const weaponId = weaponEvent.args.tokenId;
    
    // Mint basic armor
    const armorTx = await equipment.mintEquipment(
        walletAddress,
        Types.EquipmentType.ARMOR,
        Types.Rarity.COMMON,
        1  // Amount
    );
    const armorReceipt = await armorTx.wait();
    const armorEvent = armorReceipt.events.find(e => e.event === 'EquipmentMinted');
    const armorId = armorEvent.args.tokenId;
    
    console.log(`Acquired basic equipment - Weapon: ${weaponId}, Armor: ${armorId}`);
    return {weaponId, armorId};
}

// 3. Equip the hero
async function equipHero(characterId, weaponId, armorId) {
    // Approve character contract to manage equipment
    await equipment.setApprovalForAll(character.address, true);
    
    // Equip the items
    const equipTx = await character.equip(characterId, weaponId, armorId);
    await equipTx.wait();
    
    // Verify equipment
    const characterData = await character.getCharacter(characterId);
    console.log("Character equipped!", characterData);
}

// 4. Start quest
async function beginQuest(characterId) {
    // Find an appropriate quest
    const questId = 1; // For demonstration, using a known quest ID
    
    // Verify quest requirements
    const questTemplate = await quest.getQuestTemplate(questId);
    console.log(`Starting quest: ${questTemplate.name}`);
    
    // Start the quest
    const startTx = await quest.startQuest(characterId, questId);
    await startTx.wait();
    
    console.log(`Quest ${questId} started!`);
}

// 5. Simulate quest completion (simplified)
async function simulateQuestCompletion() {
    // In a real game, this would involve gameplay
    // Here we just wait a bit to simulate gameplay
    console.log("Adventuring...");
    await new Promise(resolve => setTimeout(resolve, 5000));
    console.log("Adventure complete!");
}

// 6. Claim rewards
async function claimQuestRewards(characterId) {
    const questId = 1; // Same as started quest
    
    // Complete the quest
    const completeTx = await quest.completeQuest(characterId, questId);
    const receipt = await completeTx.wait();
    
    // Extract reward info from event
    const event = receipt.events.find(e => e.event === 'QuestCompleted');
    const reward = event.args.reward;
    
    console.log(`Quest completed! Received ${ethers.utils.formatEther(reward)} GOLD`);
}
```

## The Marketplace Merchant 🏪

Example of listing, browsing, and purchasing items in the marketplace:

```typescript
// List an item for sale
async function sellItem(equipmentId, price, amount) {
    // 1. Check if we own the equipment
    const balance = await equipment.balanceOf(walletAddress, equipmentId);
    if (balance.lt(amount)) {
        throw new Error("You don't have enough of this item to sell!");
    }
    
    // 2. Approve the marketplace to transfer items
    await equipment.setApprovalForAll(marketplace.address, true);
    
    // 3. List the item
    const tx = await marketplace.listItem(
        equipmentId,
        ethers.utils.parseEther(price.toString()),
        amount
    );
    
    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === 'ItemListed');
    const listingId = event.args.listingId;
    
    console.log(`Item listed! Listing ID: ${listingId}`);
    return listingId;
}

// Browse marketplace listings
async function browseMarketplace(equipmentType, page = 1, pageSize = 10) {
    // Get total listings count
    const totalListings = await marketplace.getTotalListings();
    
    // Calculate pagination
    const startIdx = (page - 1) * pageSize;
    const endIdx = Math.min(startIdx + pageSize, totalListings);
    
    const listings = [];
    
    // Fetch listings
    for (let i = startIdx; i < endIdx; i++) {
        try {
            const listing = await marketplace.getListingByIndex(i);
            
            // Filter by equipment type if specified
            if (equipmentType) {
                const itemType = await equipment.getEquipmentType(listing.equipmentId);
                if (itemType !== equipmentType) continue;
            }
            
            // Get equipment details
            const itemDetails = await equipment.getEquipmentDetails(listing.equipmentId);
            
            listings.push({
                listingId: listing.listingId,
                equipmentId: listing.equipmentId,
                seller: listing.seller,
                price: ethers.utils.formatEther(listing.price),
                amount: listing.amount,
                type: itemDetails.equipmentType,
                rarity: itemDetails.rarity,
                name: itemDetails.name
            });
        } catch (error) {
            console.error(`Error fetching listing ${i}:`, error);
        }
    }
    
    return {
        listings,
        pagination: {
            page,
            pageSize,
            totalListings,
            totalPages: Math.ceil(totalListings / pageSize)
        }
    };
}

// Purchase an item
async function purchaseItem(equipmentId, listingId, amount) {
    // 1. Get listing details
    const listing = await marketplace.getListing(equipmentId, listingId);
    if (!listing.active) {
        throw new Error("This listing is no longer active!");
    }
    
    // 2. Calculate total cost
    const totalCost = listing.price.mul(amount);
    
    // 3. Check if we have enough GOLD
    const goldBalance = await goldToken.balanceOf(walletAddress);
    if (goldBalance.lt(totalCost)) {
        throw new Error(`Not enough GOLD! Need ${ethers.utils.formatEther(totalCost)} but have ${ethers.utils.formatEther(goldBalance)}`);
    }
    
    // 4. Approve marketplace to spend GOLD
    await goldToken.approve(marketplace.address, totalCost);
    
    // 5. Make the purchase
    const tx = await marketplace.purchaseItem(equipmentId, listingId, amount);
    await tx.wait();
    
    console.log(`Successfully purchased ${amount} of item ${equipmentId}!`);
}
```

## The DeFi Questing System 💰

Example of integrating DeFi actions with gameplay:

```typescript
// Stake LP tokens and start quest
async function stakeAndQuest(characterId, lpTokenAmount, poolId) {
    // 1. Approve staking contract to spend LP tokens
    const lpToken = await arcaneStaking.poolInfo(poolId).then(info => IERC20.at(info.lpToken));
    await lpToken.approve(arcaneStaking.address, lpTokenAmount);
    
    // 2. Stake tokens
    const stakeTx = await arcaneStaking.deposit(poolId, lpTokenAmount);
    await stakeTx.wait();
    
    console.log(`Staked ${ethers.utils.formatEther(lpTokenAmount)} LP tokens in pool ${poolId}`);
    
    // 3. Find a protocol quest related to this pool
    const questId = await findProtocolQuest(poolId);
    
    // 4. Start the protocol quest
    const questTx = await arcaneQuestIntegration.startQuest(characterId, questId);
    await questTx.wait();
    
    console.log(`Started protocol quest ${questId} for character ${characterId}`);
    
    // 5. Set up monitoring for quest completion
    monitorQuestProgress(characterId, questId, poolId);
}

// Find a protocol quest for the given pool
async function findProtocolQuest(poolId) {
    // Get protocol address from pool
    const poolInfo = await arcaneStaking.poolInfo(poolId);
    const protocolAddress = poolInfo.protocol;
    
    // Find quests for this protocol
    // This implementation depends on your quest system structure
    const questCount = await arcaneQuestIntegration.getQuestCount();
    
    for (let i = 1; i <= questCount; i++) {
        const quest = await arcaneQuestIntegration.getQuestTemplate(i);
        if (quest.targetProtocol === protocolAddress && quest.active) {
            return i;
        }
    }
    
    throw new Error("No active protocol quest found for this pool");
}

// Monitor quest progress
async function monitorQuestProgress(characterId, questId, poolId) {
    // Set up interval to check progress
    const checkInterval = setInterval(async () => {
        try {
            // Get current staking amount
            const userInfo = await arcaneStaking.userInfo(poolId, walletAddress);
            
            // Get quest status
            const questStatus = await arcaneQuestIntegration.getQuestStatus(characterId, questId);
            
            console.log(`Quest progress: ${questStatus.progress}/${questStatus.target}`);
            
            // Check if quest can be completed
            if (questStatus.progress >= questStatus.target && !questStatus.completed) {
                console.log("Quest ready for completion!");
                await completeProtocolQuest(characterId, questId);
                clearInterval(checkInterval);
            }
        } catch (error) {
            console.error("Error checking quest progress:", error);
        }
    }, 60000); // Check every minute
}

// Complete protocol quest
async function completeProtocolQuest(characterId, questId) {
    try {
        const tx = await arcaneQuestIntegration.completeQuest(characterId, questId);
        const receipt = await tx.wait();
        
        // Find reward from event
        const event = receipt.events.find(e => e.event === 'QuestCompleted');
        const reward = event.args.reward;
        
        console.log(`Protocol quest completed! Received ${ethers.utils.formatEther(reward)} GOLD`);
        
        // Check if rare item was received
        const dropEvent = receipt.events.find(e => e.event === 'DropReceived');
        if (dropEvent) {
            const itemId = dropEvent.args.itemId;
            console.log(`Also received rare item with ID: ${itemId}!`);
        }
    } catch (error) {
        console.error("Failed to complete quest:", error);
    }
}
```

## Team Quest Coordination 🤝

Example of team quests with multiple characters:

```typescript
// Form a team for a social quest
async function formTeamQuest(teamLeaderId, memberIds, questId) {
    // 1. Form the team (must be called by team leader's owner)
    const fullTeam = [teamLeaderId, ...memberIds];
    const teamTx = await socialQuest.formTeam(questId, fullTeam);
    const receipt = await teamTx.wait();
    
    // Get team ID from event
    const event = receipt.events.find(e => e.event === 'TeamFormed');
    const teamId = event.args.teamId;
    
    console.log(`Team formed with ID: ${teamId}`);
    
    // 2. Set up team communication channel
    // In a real implementation, this might involve off-chain coordination
    const teamChannel = `team-${teamId}`;
    console.log(`Team coordination channel: ${teamChannel}`);
    
    return teamId;
}

// Record character contribution to team quest
async function contributeToQuest(questId, characterId, contributionAmount) {
    // This would typically be called after a character performs some action
    const tx = await socialQuest.recordContribution(
        questId,
        characterId,
        contributionAmount
    );
    await tx.wait();
    
    // Get updated team progress
    const teamProgress = await socialQuest.getTeamProgress(questId);
    
    console.log(`Contribution recorded! Team progress: ${teamProgress.currentValue}/${teamProgress.targetValue}`);
    
    // Check if quest is complete
    if (teamProgress.currentValue >= teamProgress.targetValue) {
        console.log("Team quest ready for completion!");
    }
    
    return teamProgress;
}

// Complete team quest (called by authorized address)
async function completeTeamQuest(questId, teamId) {
    try {
        const tx = await socialQuest.completeTeamQuest(questId, teamId);
        const receipt = await tx.wait();
        
        // Extract rewards information
        const event = receipt.events.find(e => e.event === 'TeamQuestCompleted');
        const teamReward = event.args.teamReward;
        const topContributor = event.args.topContributor;
        const topReward = event.args.topReward;
        
        console.log(`Team quest completed!`);
        console.log(`Team reward: ${ethers.utils.formatEther(teamReward)} GOLD`);
        console.log(`Top contributor: Character #${topContributor}`);
        console.log(`Top contributor bonus: ${ethers.utils.formatEther(topReward)} GOLD`);
        
        // Notify team members about quest completion
        // This would typically be handled by your frontend or event listeners
    } catch (error) {
        console.error("Failed to complete team quest:", error);
    }
}
```

May these complex examples illuminate your path through the arcane arts of code, brave artificer! ⚡✨ 