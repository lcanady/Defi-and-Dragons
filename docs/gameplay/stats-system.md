# The Mystical Arts of Character Stats 🎲

Welcome, seeker of knowledge! Here you shall learn the ancient formulas that govern our heroes' abilities.

## The Three Pillars of Power 🏛️

Every hero in our realm is defined by three fundamental forces:

### Strength 💪
- The measure of physical might
- Governs combat power and carrying capacity
- Range: 5-18 points
- Favored by warriors and berserkers

### Agility 🏃‍♂️
- The essence of speed and precision
- Determines reaction time and dexterity
- Range: 5-18 points
- Favored by rogues and archers

### Magic 🔮
- The power of arcane knowledge
- Controls spell potency and mystical insight
- Range: 5-18 points
- Favored by mages and mystics

## The Balance of Power ⚖️

The distribution of these powers follows sacred rules:

- **Total Points**: Every hero begins with exactly 45 points
- **Minimum Power**: No attribute can fall below 5
- **Maximum Power**: No attribute can exceed 18
- **Dynamic Distribution**: Points are allocated based on alignment and random chance

## Paths of Destiny (Alignments) 🌟

When forging a new hero, they must choose one of three sacred paths:

### Path of Strength
```solidity
Types.Alignment.STRENGTH
```
- Favors higher strength allocation
- Bonus points prioritize strength stat
- Ideal for warrior-type characters

### Path of Agility
```solidity
Types.Alignment.AGILITY
```
- Favors higher agility allocation
- Bonus points prioritize agility stat
- Perfect for nimble characters

### Path of Magic
```solidity
Types.Alignment.MAGIC
```
- Favors higher magic allocation
- Bonus points prioritize magic stat
- Suited for spellcasting characters

## The Forging Process 🛠️

When a hero is created, their stats are determined through this mystical process:

1. **Initial Roll**
   - Three random numbers are generated
   - Each is scaled to the range of 5-18
   - The total is calculated

2. **Alignment Adjustment**
   - If total < 45: Extra points favor the chosen alignment
   - If total > 45: Points are reduced proportionally
   - If maximum stat (18) is reached, overflow distributes to other stats

3. **Final Balance**
   - Ensures total equals exactly 45
   - Maintains minimum of 5 per stat
   - Respects maximum of 18 per stat

## Examples of Stat Distribution 📊

### Strength-Aligned Hero
```typescript
// Possible stat distribution
{
    strength: 18,  // Maximum might
    agility: 14,   // Decent agility
    magic: 13     // Modest magical power
}
```

### Agility-Aligned Hero
```typescript
// Possible stat distribution
{
    strength: 13,  // Modest strength
    agility: 18,   // Maximum swiftness
    magic: 14     // Decent magical ability
}
```

### Magic-Aligned Hero
```typescript
// Possible stat distribution
{
    strength: 13,  // Modest physical power
    agility: 14,   // Decent agility
    magic: 18     // Maximum mystical might
}
```

## Viewing Your Hero's Stats 🔍

You can always gaze upon your hero's attributes using the sacred scrying function:

```typescript
const {stats, equipment, state} = await character.getCharacter(characterId);
console.log("Strength:", stats.strength);
console.log("Agility:", stats.agility);
console.log("Magic:", stats.magic);
```

## Future Enhancements 🔮

*These mystical improvements are prophesied for future updates:*

- Stat modification through equipment
- Temporary stat boosts from potions and spells
- Experience-based stat growth
- Alignment-specific special abilities

May these teachings guide you in forging legendary heroes! ⚔️✨ 