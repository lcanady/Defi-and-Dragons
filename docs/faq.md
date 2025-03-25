# Frequently Asked Questions 🤔

Welcome to the grand hall of knowledge! Here you'll find answers to the most common questions from fellow adventurers.

## 🎮 Getting Started

### Q: What is DeFi & Dragons?
A: DeFi & Dragons is an innovative GameFi protocol that combines the thrill of fantasy role-playing with blockchain technology. Create unique characters, equip them with magical NFT items, and prepare for epic adventures!

### Q: How do I start playing?
A: To begin your adventure:
1. Connect your Web3 wallet
2. Create a character by calling `mintCharacter`
3. Your character will receive random attributes based on your chosen alignment
4. Equip your hero with weapons and armor

### Q: What networks are supported?
A: Currently, we're testing on Ethereum test networks. Stay tuned for mainnet deployment announcements!

## 💰 Economics

### Q: What are the tokenomics?
A: Our ecosystem features:
- $GOLD: Main game currency
- $ARCANE: Governance token
- LP Tokens: Used for crafting and staking
- NFTs: Characters, Equipment, and Pets

### Q: How do I earn rewards?
Multiple ways:
1. Complete quests
2. Participate in DeFi activities
3. Win combat encounters
4. Stake LP tokens
5. Trade in the marketplace

### Q: What are the fees?
- Marketplace: 1% base fee
- Trading: 0.3% AMM fee
- Crafting: Variable resource costs
- Quest Entry: Some quests require stakes

## ⚔️ Characters & Equipment

### Q: How do character stats work?
A: Each character has three primary attributes:
- **Strength**: Physical might and combat prowess (5-18)
- **Agility**: Swiftness and dexterity (5-18)
- **Magic**: Command over arcane forces (5-18)

Total attribute points will always equal 45, distributed based on your chosen alignment.

### Q: What are alignments?
A: There are three sacred paths:
1. **Path of Strength**: Favors physical might
2. **Path of Agility**: Favors swiftness
3. **Path of Magic**: Favors arcane power

Your alignment influences how your initial stats are distributed.

### Q: How does equipment work?
A: Equipment consists of two slots:
- **Weapon**: Your primary tool of combat
- **Armor**: Your protective gear

Each piece of equipment is a unique NFT stored in your character's personal wallet.

## 🎯 Quests

### Q: What types of quests are available?
We offer various quest types:
- Daily quests
- Team quests
- Protocol quests
- Achievement quests
- Seasonal events

### Q: How do team quests work?
Team quests require:
1. Forming a party (2-5 players)
2. Coordinating actions
3. Meeting collective goals
4. Sharing rewards

### Q: What are bonus windows?
Special time periods where:
- Quest rewards are increased
- Drop rates are boosted
- Combat damage is enhanced
- Crafting costs are reduced

## 🌟 Items & Equipment

### Q: How do I get better equipment?
Acquire gear through:
1. Crafting with LP tokens
2. Marketplace purchases
3. Quest rewards
4. Boss drops
5. Special events

### Q: What are pets for?
Pets provide:
- Passive stat bonuses
- Special abilities
- Resource gathering
- Combat assistance

### Q: How does crafting work?
Crafting requires:
1. LP tokens as base material
2. Additional resources
3. Recipe knowledge
4. Character level requirements

## 🏦 DeFi Features

### Q: What's the relationship between DeFi and gameplay?
DeFi actions power gameplay:
- Trading affects combat
- Staking enables abilities
- LP tokens craft items
- Protocol usage triggers quests

### Q: How do I manage risk?
Risk management tools:
1. Slippage protection
2. Emergency withdrawals
3. Combat retreats
4. Insurance options

### Q: What's impermanent loss?
Explained in RPG terms:
- Like a temporary debuff
- Affects LP token value
- Can be mitigated with strategies
- Compensated by farming rewards

## 🔧 Technical

### Q: How do I manage my character's equipment?
A: Use these commands:
```solidity
// Equip items
await character.equip(characterId, weaponId, armorId);

// Unequip items
await character.unequip(characterId, true, false); // true for weapon, false for armor
```

### Q: How do I view my character's stats?
A: Use the `getCharacter` function:
```solidity
const {stats, equipment, state} = await character.getCharacter(characterId);
```

### Q: Are the contracts audited?
A: Our contracts are currently in active development. Security is our top priority, and we'll announce audit results before mainnet deployment.

## 🔮 Future Features

The following features are planned for future releases:
- Quest System
- Marketplace
- Social Adventures
- DeFi Integration
- Combat System

Stay tuned for updates on these exciting additions to our magical realm!

## 🤝 Community

### Q: How can I get involved?
Ways to join our fellowship:
1. Join our [Discord](https://discord.gg/defi-dragons)
2. Follow development on [GitHub](https://github.com/defi-dragons)
3. Share feedback and suggestions
4. Help test new features

May these answers light your path, brave adventurer! 🌟 