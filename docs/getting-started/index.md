# 🌟 The Beginning of Your Legend

Hail, brave soul! Your journey into the mystical realm of DeFi & Dragons begins here. Ready your weapons and prepare your spells!

## 🧙‍♂️ Forging Your Hero

Every great adventure begins with a hero. In DeFi & Dragons, your character's essence is shaped by three mystical forces:
- 💪 Strength: Your physical might and combat prowess
- 🏃 Agility: Your swiftness and dexterity
- 🔮 Magic: Your command over arcane forces

Choose your path wisely with one of three sacred alignments:
- ⚔️ Path of Strength
- 🏹 Path of Agility
- 📚 Path of Magic

```solidity
// Forge your champion's essence
const characterId = await character.mintCharacter(
    yourAddress,
    Types.Alignment.STRENGTH  // Choose your path: STRENGTH, AGILITY, or MAGIC
);

// Behold your hero's attributes
const {stats, equipment, state} = await character.getCharacter(characterId);
console.log("Your hero's essence:", stats);
```

Your hero begins with a total of 45 points distributed across their attributes, with each attribute ranging from 5 to 18. Your chosen alignment influences how these points are distributed!

## ⚔️ Arming for Battle

A hero needs proper equipment! Your character can wield both weapons and armor:

```solidity
// Don your equipment
await character.equip(
    characterId,
    weaponId,    // Your chosen blade
    armorId      // Your protective shell
);

// Change your battle gear
await character.unequip(
    characterId,
    true,   // Sheathe your weapon
    false   // Keep your armor
);
```

Each piece of equipment is a unique NFT, stored safely in your character's personal wallet. Choose wisely, for your equipment will aid you in your quests!

## 🎮 Managing Your Hero

Keep track of your hero's journey with these mystical commands:

```solidity
// Gaze upon your hero's essence
const {stats, equipment, state} = await character.getCharacter(characterId);

// View your equipped items
const wallet = await character.characterWallets(characterId);
const equipped = await wallet.getEquippedItems();
```

## 📜 The First Trials
Begin your legend with these quests:

```solidity
// Embark on your quest
await gameFacade.startQuest(characterId, questId);

// Claim your victory
await gameFacade.completeQuest(characterId, questId);
```

## 🎁 Divine Treasures
The gods may bless you with magical items:

```solidity
// Invoke the blessing of random drops
const requestId = await gameFacade.requestRandomDrop(dropRateBonus);
```

## 🏪 The Grand Bazaar
Trade your treasures with fellow adventurers:

```solidity
// Display your wares
await gameFacade.listItem(equipmentId, price, amount);

// Acquire new treasures
await gameFacade.purchaseItem(equipmentId, listingId, amount);
```

## 🤝 Fellowship of Heroes
Unite with other brave souls:

```solidity
// Form your fellowship
await socialQuest.formTeam(questId, [characterId1, characterId2, characterId3]);

// Record your valor
await socialQuest.recordContribution(questId, characterId, contributionValue);
```

## 📯 Call for Aid

- Join our [Fellowship Hall](https://discord.gg/defi-dragons)
- Consult the [Scroll of Knowledge](../faq.md)
- Seek guidance in the [Troubleshooter's Tome](../troubleshooting.md)

May the gods smile upon your journey, brave adventurer! 🗡️✨

> 🔮 **Coming Soon**
> - Epic Quests System
> - Magical Marketplace
> - Social Adventures
> - And much more!

##  Need Help?

- Join our [Discord](https://discord.gg/defi-dragons) for support
- Check the [FAQ](../faq.md)
- Consult the [Troubleshooting Guide](../troubleshooting.md)

May fortune favor your journey! 🍀 