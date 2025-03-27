# Troubleshooting Guide 🛠️

Fear not, brave adventurer! Even the mightiest heroes encounter challenges. Here's how to overcome common obstacles in your journey.

## 🎭 Character Issues

### Character Creation Failed
```solidity
Error: Transaction Failed
```
**Solution:**
1. Ensure you have enough ETH for gas
2. Verify your wallet is connected to the correct network
3. Check that you're using a valid alignment value (STRENGTH, AGILITY, or MAGIC)

Example of proper character creation:
```solidity
try {
    const tx = await character.mintCharacter(
        yourAddress,
        stats, // Your hero's base attributes
        Types.Alignment.STRENGTH
    );
    await tx.wait();
} catch (error) {
    console.error("Failed to create character:", error);
}
```

### Can't Equip Items
```solidity
Error: NotCharacterOwner
```
**Solution:**
1. Verify you own the character (check `ownerOf(characterId)`)
2. Ensure the character exists
3. Confirm you're using the correct character ID

Example of checking ownership:
```solidity
const owner = await character.ownerOf(characterId);
console.log("Character owner:", owner);
```

## ⚔️ Equipment Problems

### Equipment Not Showing
```solidity
Error: InvalidEquipment
```
**Solution:**
1. Verify the equipment IDs exist
2. Check if equipment is already equipped
3. Ensure equipment ownership in character wallet

Example of checking equipped items:
```solidity
const wallet = await character.characterWallets(characterId);
const equipped = await wallet.getEquippedItems();
console.log("Equipped items:", equipped);
```

### Unequip Failed
```solidity
Error: NotCharacterOwner
```
**Solution:**
1. Verify character ownership
2. Check which slots you're trying to unequip
3. Ensure the equipment is currently equipped

Example of proper unequipping:
```solidity
await character.unequip(
    characterId,
    true,  // Unequip weapon
    false  // Keep armor
);
```

## 🔍 Debugging Tools

### Check Character State
```solidity
// View complete character info
const {stats, equipment, state} = await character.getCharacter(characterId);
console.log('Character Stats:', stats);
console.log('Equipment:', equipment);
console.log('State:', state);

// Check specific stats
console.log('Strength:', stats.strength);
console.log('Agility:', stats.agility);
console.log('Magic:', stats.magic);
```

### Monitor Events
```solidity
// Listen for character creation
character.on("CharacterCreated", (tokenId, owner, wallet) => {
    console.log(`New character created! ID: ${tokenId}`);
    console.log(`Owner: ${owner}`);
    console.log(`Wallet: ${wallet}`);
});

// Listen for equipment changes
character.on("EquipmentChanged", (tokenId, weaponId, armorId) => {
    console.log(`Equipment changed for character ${tokenId}`);
    console.log(`New weapon: ${weaponId}`);
    console.log(`New armor: ${armorId}`);
});
```

## 📞 Support Channels

If you're still stuck:

1. Join our [Discord](https://discord.gg/defi-dragons)
2. Check the [GitHub Issues](https://github.com/defi-dragons/issues)
3. Contact Support: support@defi-dragons.com

Remember: every hero faces challenges. It's how we overcome them that defines our legend! 🗡️✨ 