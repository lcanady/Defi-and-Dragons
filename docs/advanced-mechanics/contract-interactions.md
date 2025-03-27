# 🔄 The Mystical Weave: Contract Interactions

*Within these magical scrolls lies the knowledge of how our realm's components intertwine, forming the tapestry of our adventure.*

## The Primary Rituals 🔮

### Character Creation Ritual

The process of breathing life into a new hero involves multiple contracts working in harmony:

```solidity
// 1. The front-end or user script initiates the ritual
async function createHero(alignment) {
    // 2. Generate initial stats (client-side option)
    const stats = {
        strength: 10,
        agility: 10,
        magic: 10
    };
    
    // 3. Invoke the sacred ritual via GameFacade
    const tx = await gameFacade.createCharacter(
        stats,
        Types.Alignment[alignment] // STRENGTH, AGILITY, or MAGIC
    );
    
    // 4. Wait for the mystical energies to settle
    const receipt = await tx.wait();
    
    // 5. Extract the newly forged character's ID from event logs
    const event = receipt.events.find(e => e.event === 'CharacterCreated');
    const characterId = event.args.tokenId;
    
    return characterId;
}
```

Behind the scenes, this invokes a sequence of contract interactions:

```
GameFacade.createCharacter()
  ├─▶ Character.mintCharacter()
  │     ├─▶ ProvableRandom.generateNumbers() (if using on-chain stats)
  │     ├─▶ _safeMint() (ERC721 function)
  │     └─▶ _deployWallet() (creates CharacterWallet)
  │           └─▶ CharacterWallet.initialize()
  └─▶ emits CharacterCreated event
```

### Equipment & Questing Dance

When a hero dons equipment and embarks on a quest, these mystical forces align:

```solidity
// Prepare for adventure with equipment and quest
async function prepareForAdventure(characterId, weaponId, armorId, questId) {
    // 1. Equip your hero with magical items
    await gameFacade.equipItems(characterId, weaponId, armorId);
    
    // 2. Embark on your epic quest
    await gameFacade.startQuest(characterId, questId);
    
    // 3. Alternative: Use the batched operation for efficiency
    // await gameFacade.batchEquipAndStartQuest(characterId, weaponId, armorId, questId);
}
```

The mystical flow behind this sequence:

```
GameFacade.equipItems()
  └─▶ Character.equip()
        ├─▶ Verify character ownership
        └─▶ CharacterWallet.equip()
              ├─▶ Equipment.balanceOf() (verifies ownership)
              ├─▶ Equipment.verifyType() (checks equipment types)
              └─▶ Updates equipment slots

GameFacade.startQuest()
  └─▶ Quest.startQuest()
        ├─▶ Verify quest requirements
        ├─▶ Character.getCharacter() (checks stats & equipment)
        └─▶ Records quest start time
```

## Advanced Interactions 🧙‍♂️

### The DeFi & Combat Fusion

Our unique system allows DeFi actions to trigger combat moves:

```solidity
// Perform DeFi action that triggers combat abilities
async function defiFightingMagic(characterId, moveId, actionType, actionValue) {
    // 1. Record the DeFi action
    await gameFacade.recordAction(characterId, actionType, actionValue);
    
    // 2. This automatically checks for combat triggers
    // If the action meets conditions, combat move is activated
    
    // 3. Check if combat bonus was awarded
    const combatState = await combatActions.getBattleState(characterId);
    console.log("Combo count:", combatState.comboCount);
    console.log("Active effects:", combatState.activeEffects);
}
```

The magical sequence within:

```
GameFacade.recordAction()
  └─▶ ActionTracker.recordAction()
        └─▶ CombatActions.checkTriggers()
              ├─▶ If triggered, CombatActions.executeMove()
              └─▶ Updates battle state with effects
```

### The Fellowship Quest System

For brave heroes seeking to join forces:

```solidity
// Form a team and tackle challenges together
async function formFellowship(questId, characterIds) {
    // 1. Form your heroic team
    const teamId = await socialQuest.formTeam(questId, characterIds);
    
    // 2. Each member contributes to the quest
    for (const characterId of characterIds) {
        // Simulate contribution from quest activity
        await socialQuest.recordContribution(
            questId, 
            characterId,
            ethers.utils.parseEther("10") // Contribution value
        );
    }
    
    // 3. When complete, distribute rewards (called by authorized address)
    await socialQuest.completeTeamQuest(questId, teamId);
}
```

Behind the scenes:

```
SocialQuest.formTeam()
  ├─▶ Verify quest is active
  ├─▶ Check character ownership
  ├─▶ Create team record
  └─▶ emits TeamFormed event

SocialQuest.recordContribution()
  ├─▶ Verify character in team
  ├─▶ Update contribution records
  └─▶ Check for quest completion

SocialQuest.completeTeamQuest()
  ├─▶ Calculate member rewards
  ├─▶ Distribute rewards to members
  └─▶ emits TeamQuestCompleted event
```

## Complex Rituals 🔮

### Marketplace Transactions

The grand bazaar where heroes trade magical items:

```solidity
// Sell your magical treasures
async function sellTreasure(equipmentId, price, amount) {
    // 1. Approve the marketplace to transfer your item
    await equipment.setApprovalForAll(MARKETPLACE_ADDRESS, true);
    
    // 2. List your item for sale
    await marketplace.listItem(equipmentId, price, amount);
}

// Purchase magical items
async function buyTreasure(equipmentId, listingId, amount) {
    // 1. Check the price
    const listing = await marketplace.getListing(equipmentId, listingId);
    const totalCost = listing.price.mul(amount);
    
    // 2. Ensure you have enough gold
    const goldBalance = await goldToken.balanceOf(walletAddress);
    if (goldBalance.lt(totalCost)) {
        throw new Error("Not enough gold for this treasure!");
    }
    
    // 3. Approve the marketplace to spend your gold
    await goldToken.approve(MARKETPLACE_ADDRESS, totalCost);
    
    // 4. Make the purchase
    await marketplace.purchaseItem(equipmentId, listingId, amount);
}
```

The marketplace magic:

```
Marketplace.listItem()
  ├─▶ Verify item ownership
  ├─▶ Create listing record
  └─▶ Transfer item to escrow (optional design)

Marketplace.purchaseItem()
  ├─▶ Verify listing exists and is active
  ├─▶ Transfer gold from buyer to seller (with fee)
  ├─▶ Transfer item from escrow/seller to buyer
  └─▶ Update listing records
```

### Random Loot Drops

The system for distributing magical rewards:

```solidity
// Request a random drop with bonus chance
async function seekMagicalTreasure(dropRateBonus) {
    // 1. Request the random drop
    const requestId = await gameFacade.requestRandomDrop(dropRateBonus);
    
    // 2. Listen for the DropReceived event
    const filter = gameFacade.filters.DropReceived(null, walletAddress);
    gameFacade.once(filter, (requestId, recipient, itemId) => {
        console.log(`You found a mystical item! Item ID: ${itemId}`);
    });
}
```

The mystical sequence:

```
GameFacade.requestRandomDrop()
  ├─▶ ProvableRandom.generateNumbers()
  ├─▶ DropSystem.processRandomDrop()
  │     ├─▶ Determine item type and rarity
  │     └─▶ Equipment.mintEquipment() (creates new NFT)
  └─▶ emits DropReceived event
```

## Error Handling Magic 🧪

When rituals fail, understanding the mystical errors is crucial:

```solidity
// Safe character creation with error handling
async function safeCreateCharacter(alignment) {
    try {
        const characterId = await gameFacade.createCharacter(
            {strength: 10, agility: 10, magic: 10},
            Types.Alignment[alignment]
        );
        
        console.log(`New hero forged! ID: ${characterId}`);
        return characterId;
    } catch (error) {
        // Decode the error
        if (error.message.includes("NotAuthorized")) {
            console.error("The mystical forces reject your authority!");
        } else if (error.message.includes("InvalidParameters")) {
            console.error("The magical formula is incorrect!");
        } else {
            console.error("An unknown magical disruption occurred:", error);
        }
        
        return null;
    }
}
```

Common magical disruptions:

| Error Code | Mystical Meaning | Solution |
|------------|------------------|----------|
| `NotAuthorized` | You lack permission | Connect correct wallet |
| `InsufficientBalance` | Not enough tokens | Acquire more gold |
| `InvalidParameters` | Incorrect spell components | Check function arguments |
| `QuestNotActive` | The quest scroll has faded | Select active quest |
| `QuestAlreadyCompleted` | Glory already claimed | Choose new quest |
| `ItemNotAvailable` | The item has vanished | Check item exists and is for sale |
| `InsufficientLevel` | More training required | Level up character |
| `CooldownActive` | Magic still recharging | Wait for cooldown |

## Event Listening Incantations 📣

Listen for mystical events to track the state of the realm:

```solidity
// Listen for Character events
function watchCharacterEvents(characterId) {
    // Filter for specific character events
    const filter = character.filters.EquipmentChanged(characterId);
    
    // Listen for equipment changes
    character.on(filter, (tokenId, weaponId, armorId) => {
        console.log(`Character ${tokenId} changed equipment!`);
        console.log(`New weapon: ${weaponId}, New armor: ${armorId}`);
    });
    
    // Listen for quest events
    const questFilter = quest.filters.QuestStarted(characterId);
    quest.on(questFilter, (characterId, questId, startTime) => {
        console.log(`Character ${characterId} started quest ${questId}!`);
        console.log(`Quest began at ${new Date(startTime * 1000)}`);
    });
}
```

Important events to monitor:

| Contract | Event | Description |
|----------|-------|-------------|
| Character | CharacterCreated | New hero forged |
| Character | EquipmentChanged | Hero changed gear |
| Quest | QuestStarted | New adventure begun |
| Quest | QuestCompleted | Victory achieved |
| SocialQuest | TeamFormed | Fellowship created |
| SocialQuest | ContributionRecorded | Hero's deeds noted |
| Marketplace | ItemListed | New treasure available |
| Marketplace | ItemSold | Treasure changed hands |
| DropSystem | DropReceived | Random item discovered |

May these interaction patterns guide your journey through our magical realm, brave coder! 🧙‍♂️✨ 