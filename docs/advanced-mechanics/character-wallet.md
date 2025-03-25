# The Sacred Vaults: Character Wallets 💰

Welcome, keeper of treasures! Here you'll learn about the mystical vaults that safeguard each hero's equipment.

## Overview 🌟

The `CharacterWallet` system is a unique feature that provides each character with their own secure vault for managing equipment. Each wallet is:
- Uniquely tied to a specific character
- Controlled by the character's owner
- Capable of managing equipment NFTs

## Wallet Creation 🏰

A new wallet is automatically forged when a character is created:

```solidity
CharacterWallet wallet = new CharacterWallet(
    address(equipmentContract),  // The equipment registry
    tokenId,                    // The character's ID
    address(this)               // The character contract
);
```

## Core Features 🛡️

### Equipment Management

1. **Equipping Items**
```solidity
function equip(uint256 weaponId, uint256 armorId) external
```
- Verifies ownership of items
- Checks for valid equipment types
- Updates equipped status
- Emits equipment change events

2. **Unequipping Items**
```solidity
function unequip(bool weapon, bool armor) external
```
- Selectively removes equipment
- Clears equipment slots
- Updates item status
- Emits equipment change events

### Equipment Status

1. **Viewing Equipped Items**
```solidity
function getEquippedItems() external view returns (Types.EquipmentSlots memory)
```
Returns currently equipped:
- Weapon ID (0 if none)
- Armor ID (0 if none)

## Security Model 🔒

The wallet implements several security measures:

1. **Ownership Control**
   - Only the character owner can initiate actions
   - Ownership transfers with character transfers
   - Equipment stays with the character

2. **Equipment Validation**
   - Verifies equipment ownership
   - Checks equipment type compatibility
   - Prevents duplicate equipment

3. **Access Control**
   - Character contract has special privileges
   - Direct wallet interactions are restricted
   - Equipment contract is trusted

## Usage Examples 📚

### Checking Equipment
```typescript
// Get the character's wallet
CharacterWallet wallet = character.characterWallets(characterId);

// View equipped items
Types.EquipmentSlots memory equipped = wallet.getEquippedItems();
console.log("Weapon:", equipped.weaponId);
console.log("Armor:", equipped.armorId);
```

### Managing Equipment
```typescript
// Through the character contract
await character.equip(characterId, weaponId, armorId);
await character.unequip(characterId, true, false); // Unequip weapon only

// Direct wallet interaction (not recommended)
CharacterWallet wallet = character.characterWallets(characterId);
await wallet.equip(weaponId, armorId);
```

## Error Handling 🚨

Common error scenarios and their solutions:

1. **Invalid Equipment**
```solidity
Error: "Invalid equipment type"
Solution: Ensure equipment IDs are valid and of correct type
```

2. **Ownership Issues**
```solidity
Error: "Not equipment owner"
Solution: Verify equipment ownership before equipping
```

3. **Already Equipped**
```solidity
Error: "Slot already equipped"
Solution: Unequip current item before equipping new one
```

## Best Practices 💡

1. **Equipment Management**
   - Always use character contract for equipment actions
   - Verify equipment ownership before actions
   - Handle all error cases gracefully

2. **Ownership Transfers**
   - Equipment stays with character during transfers
   - No manual wallet management needed
   - Ownership updates automatically

3. **Gas Optimization**
   - Batch equipment changes when possible
   - Check equipment status before actions
   - Use view functions for queries

## Future Enhancements 🔮

*These features are prophesied for future updates:*

- Multiple equipment slots
- Equipment set bonuses
- Equipment durability
- Equipment upgrading
- Equipment crafting

## Troubleshooting Guide 🔍

### Common Issues

1. **Equipment Not Showing**
```typescript
// Check wallet status
const wallet = await character.characterWallets(characterId);
const equipped = await wallet.getEquippedItems();
```

2. **Failed Equipment Changes**
```typescript
// Verify ownership and approval
const owner = await character.ownerOf(characterId);
const isApproved = await equipment.isApprovedForAll(owner, walletAddress);
```

3. **Wallet Access Issues**
```typescript
// Confirm wallet ownership
const walletOwner = await wallet.owner();
console.log("Wallet owned by:", walletOwner);
```

May your equipment be ever ready for battle! ⚔️✨ 