# Smart Contract API Reference

## Overview

This document provides a comprehensive reference for all smart contract interfaces in the Dungeons & DeFi ecosystem. Each contract's functions are categorized by their mutability (view/pure vs state-changing) and access level (public, external, etc.).

## Table of Contents

1. [Core Contracts](#core-contracts)
   - [Character](#character)
   - [Equipment](#equipment)
   - [GameToken](#gametoken)
2. [Game Systems](#game-systems)
   - [Quest System](#quest-system)
   - [Crafting System](#crafting-system)
   - [Pet System](#pet-system)
   - [Mount System](#mount-system)
3. [DeFi Components](#defi-components)
   - [Marketplace](#marketplace)
   - [AMM Router](#amm-router)
4. [Data Structures](#data-structures)
5. [Events](#events)
6. [Errors](#errors)

## Core Contracts

### Character
**Contract**: `Character.sol`  
**Standard**: ERC-721  
**Description**: Manages player characters as NFTs with stats, equipment, and state.

#### View Functions

```solidity
function getCharacter(uint256 tokenId) 
    external 
    view 
    returns (Types.Stats, Types.EquipmentSlots, Types.CharacterState)
```
Returns complete character information.
- **Parameters**:
  - `tokenId`: Character's unique identifier
- **Returns**: Tuple of character stats, equipment, and state
- **Access**: Public
- **Events**: None
- **Errors**: 
  - `CharacterNotFound(uint256 tokenId)`

```solidity
function characterStats(uint256 tokenId) 
    external 
    view 
    returns (Types.Stats)
```
Returns character's base stats.
- **Parameters**:
  - `tokenId`: Character's unique identifier
- **Returns**: Character's strength, agility, and magic stats
- **Access**: Public
- **Errors**: 
  - `CharacterNotFound(uint256 tokenId)`

#### State-Changing Functions

```solidity
function mintCharacter(
    address to,
    Types.Stats calldata initialStats,
    Types.Alignment alignment
) external returns (uint256)
```
Creates a new character NFT.
- **Parameters**:
  - `to`: Owner's address
  - `initialStats`: Initial character stats
  - `alignment`: Character's alignment
- **Returns**: New character's token ID
- **Access**: Public
- **Events**: 
  - `CharacterCreated(uint256 indexed id, address indexed owner)`
- **Errors**:
  - `InvalidStats(Types.Stats stats)`
  - `InvalidAlignment(Types.Alignment alignment)`

### Equipment
**Contract**: `Equipment.sol`  
**Standard**: ERC-1155  
**Description**: Multi-token system for weapons, armor, and items.

#### View Functions

```solidity
function equipmentStats(uint256 id) 
    external 
    view 
    returns (Types.EquipmentStats)
```
Returns equipment type stats.
- **Parameters**:
  - `id`: Equipment type identifier
- **Returns**: Equipment's stat bonuses and properties
- **Access**: Public
- **Errors**:
  - `InvalidEquipment(uint256 id)`

#### State-Changing Functions

```solidity
function createEquipment(
    uint256 equipmentId,
    string calldata name,
    string calldata description,
    Types.EquipmentStats calldata stats
) external
```
Creates new equipment type.
- **Parameters**:
  - `equipmentId`: Unique identifier
  - `name`: Equipment name
  - `description`: Equipment description
  - `stats`: Equipment stats
- **Access**: Admin
- **Events**:
  - `EquipmentCreated(uint256 indexed id, string name)`
- **Errors**:
  - `EquipmentExists(uint256 id)`
  - `InvalidStats(Types.EquipmentStats stats)`

### GameToken
**Contract**: `GameToken.sol`  
**Standard**: ERC-20  
**Description**: Native token for game economy and rewards.

[Additional contracts follow same format...]

## Data Structures

### Character Types
```solidity
struct Stats {
    uint8 strength;    // Base strength (1-100)
    uint8 agility;     // Base agility (1-100)
    uint8 magic;       // Base magic (1-100)
}

struct CharacterState {
    uint256 health;    // Current health
    uint256 mana;      // Current mana
    bool inCombat;     // Combat status
    uint256 lastAction; // Timestamp of last action
}

enum Alignment {
    GOOD,
    NEUTRAL,
    EVIL
}
```

### Equipment Types
```solidity
struct EquipmentStats {
    uint8 strengthBonus;
    uint8 agilityBonus;
    uint8 magicBonus;
    uint256 durability;
    bool consumable;
    Types.Rarity rarity;
}

enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
}
```

## Events

### Character Events
```solidity
event CharacterCreated(
    uint256 indexed id,
    address indexed owner,
    Types.Stats stats,
    Types.Alignment alignment
);

event CharacterLevelUp(
    uint256 indexed id,
    uint256 newLevel,
    Types.Stats newStats
);
```

### Equipment Events
```solidity
event EquipmentCreated(
    uint256 indexed id,
    string name,
    Types.Rarity rarity
);

event EquipmentEquipped(
    uint256 indexed characterId,
    uint256 indexed equipmentId
);
```

## Errors

### Character Errors
```solidity
error CharacterNotFound(uint256 tokenId);
error InvalidStats(Types.Stats stats);
error InvalidAlignment(Types.Alignment alignment);
error CharacterInCombat(uint256 tokenId);
```

### Equipment Errors
```solidity
error InvalidEquipment(uint256 id);
error EquipmentExists(uint256 id);
error InsufficientDurability(uint256 id, uint256 required, uint256 current);
error InvalidEquipmentType(uint256 id, Types.EquipmentSlot slot);
``` 