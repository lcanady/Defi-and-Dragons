# Arcane Crafting System Guide

## Overview
The Arcane Crafting System is an innovative crafting mechanism that combines traditional resource-based crafting with DeFi elements. This system allows players to create powerful equipment and items using a combination of resources, LP tokens, and character abilities.

## Table of Contents
1. [Core Components](#core-components)
2. [Getting Started](#getting-started)
3. [Crafting Mechanics](#crafting-mechanics)
4. [Recipe System](#recipe-system)
5. [Success Rate Mechanics](#success-rate-mechanics)
6. [Advanced Crafting](#advanced-crafting)
7. [Integration Guide](#integration-guide)
8. [Troubleshooting](#troubleshooting)

## Core Components

### ArcaneCrafting Contract
The main contract managing all crafting operations:
```solidity
interface IArcaneCrafting {
    function craftItem(uint256 recipeId) external returns (bool success);
    function getRecipe(uint256 recipeId) external view returns (Recipe memory);
    function calculateSuccessRate(uint256 recipeId, address crafter) external view returns (uint256);
    function getCooldown(uint256 recipeId, address crafter) external view returns (uint256);
}
```

### Recipe System
Each recipe represents a craftable item:
```solidity
struct Recipe {
    uint256 recipeId;          // Unique identifier
    uint256 resultingItemId;   // ID of the item to be crafted
    address lpToken;           // Required LP token address
    uint256 lpTokenAmount;     // Required LP token amount
    address[] resources;       // Array of resource token addresses
    uint256[] resourceAmounts; // Array of required resource amounts
    uint256 cooldown;         // Crafting cooldown in seconds
    bool isActive;            // Recipe availability status
    uint256 difficulty;       // Base difficulty (affects success rate)
    uint256 minLevel;         // Minimum character level required
}
```

## Getting Started

### 1. Prerequisites
Before crafting, ensure you have:
- Required character level
- Sufficient resources
- Required LP tokens
- No active cooldowns

### 2. Basic Crafting Flow
```solidity
// 1. Check recipe requirements
Recipe memory recipe = crafting.getRecipe(recipeId);
require(character.getLevel(characterId) >= recipe.minLevel, "Level too low");

// 2. Approve resource transfers
for (uint i = 0; i < recipe.resources.length; i++) {
    IERC20(recipe.resources[i]).approve(address(crafting), recipe.resourceAmounts[i]);
}

// 3. Approve LP token
IERC20(recipe.lpToken).approve(address(crafting), recipe.lpTokenAmount);

// 4. Attempt crafting
bool success = crafting.craftItem(recipeId);
```

### 3. Resource Management
Example resource preparation:
```solidity
// Check resource balances
function checkResources(uint256 recipeId) external view returns (bool[] memory sufficient) {
    Recipe memory recipe = crafting.getRecipe(recipeId);
    sufficient = new bool[](recipe.resources.length);
    
    for (uint i = 0; i < recipe.resources.length; i++) {
        uint256 balance = IERC20(recipe.resources[i]).balanceOf(msg.sender);
        sufficient[i] = balance >= recipe.resourceAmounts[i];
    }
}
```

## Crafting Mechanics

### 1. Success Rate Calculation
The final success rate is determined by multiple factors:
```solidity
function calculateSuccessRate(
    uint256 recipeId,
    address crafter
) public view returns (uint256) {
    // Base success rate (40-80% depending on difficulty)
    uint256 baseRate = getBaseSuccessRate(recipeId);
    
    // Character level bonus (0-20%)
    uint256 levelBonus = calculateLevelBonus(crafter);
    
    // Equipment bonus (0-15%)
    uint256 equipmentBonus = calculateEquipmentBonus(crafter);
    
    // LP token bonus (0-25%)
    uint256 lpBonus = calculateLPBonus(crafter, recipeId);
    
    return baseRate + levelBonus + equipmentBonus + lpBonus;
}
```

### 2. Cooldown System
Cooldowns prevent excessive crafting:
```solidity
function getCooldownRemaining(uint256 recipeId, address crafter) public view returns (uint256) {
    uint256 lastCraft = craftingHistory[crafter][recipeId];
    Recipe memory recipe = recipes[recipeId];
    
    if (lastCraft == 0) return 0;
    if (block.timestamp < lastCraft + recipe.cooldown) {
        return lastCraft + recipe.cooldown - block.timestamp;
    }
    return 0;
}
```

### 3. Critical Success System
Special crafting outcomes:
```solidity
function determineCriticalSuccess(
    uint256 recipeId,
    address crafter
) internal view returns (bool) {
    uint256 critChance = calculateCriticalChance(crafter);
    uint256 rand = generateRandomNumber() % 100;
    return rand < critChance;
}
```

## Recipe System

### 1. Recipe Creation
Example of creating a powerful weapon recipe:
```solidity
// Create Legendary Sword recipe
function createLegendarySwordRecipe() external {
    address[] memory resources = new address[](3);
    resources[0] = address(etherealSteel);    // Rare metal
    resources[1] = address(dragonEssence);    // Magical essence
    resources[2] = address(ancientCore);      // Powerful core

    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 100 * 10**18;  // 100 Ethereal Steel
    amounts[1] = 50 * 10**18;   // 50 Dragon Essence
    amounts[2] = 1 * 10**18;    // 1 Ancient Core

    crafting.createRecipe(
        LEGENDARY_SWORD_RECIPE_ID,
        LEGENDARY_SWORD_ITEM_ID,
        address(lpToken),        // ETH-GOLD LP token
        1000 * 10**18,          // 1000 LP tokens required
        resources,
        amounts,
        24 hours,               // 24-hour cooldown
        80,                     // 80% difficulty (20% base success rate)
        50                      // Level 50 required
    );
}
```

### 2. Recipe Tiers
Different recipe difficulty levels:
```solidity
enum RecipeTier {
    COMMON,      // 80% base success rate
    UNCOMMON,    // 70% base success rate
    RARE,        // 60% base success rate
    EPIC,        // 50% base success rate
    LEGENDARY    // 40% base success rate
}
```

### 3. Recipe Management
Example of recipe modification:
```solidity
function adjustRecipeDifficulty(
    uint256 recipeId,
    uint256 newDifficulty
) external onlyAdmin {
    Recipe storage recipe = recipes[recipeId];
    require(recipe.isActive, "Recipe not active");
    
    uint256 oldDifficulty = recipe.difficulty;
    recipe.difficulty = newDifficulty;
    
    emit RecipeDifficultyAdjusted(recipeId, oldDifficulty, newDifficulty);
}
```

## Success Rate Mechanics

### 1. Base Success Rate
```solidity
function getBaseSuccessRate(uint256 recipeId) public view returns (uint256) {
    Recipe memory recipe = recipes[recipeId];
    // Higher difficulty = lower base success rate
    return 100 - recipe.difficulty;
}
```

### 2. Character Bonuses
```solidity
function calculateCharacterBonuses(address crafter) public view returns (uint256) {
    // Get character stats
    (uint256 intelligence, uint256 wisdom) = character.getStats(crafter);
    
    // Calculate crafting bonus
    uint256 craftingBonus = (intelligence + wisdom) / 10;
    
    // Cap at 25%
    return Math.min(craftingBonus, 25);
}
```

### 3. Equipment Bonuses
```solidity
function calculateEquipmentBonuses(address crafter) public view returns (uint256) {
    uint256 bonus = 0;
    
    // Check for crafting tools
    uint256 toolId = character.getEquippedTool(crafter);
    if (toolId != 0) {
        bonus += equipment.getCraftingBonus(toolId);
    }
    
    // Check for crafting gear
    uint256 gearId = character.getEquippedGear(crafter);
    if (gearId != 0) {
        bonus += equipment.getCraftingBonus(gearId);
    }
    
    // Cap at 15%
    return Math.min(bonus, 15);
}
```

## Advanced Crafting

### 1. Critical Success System
```solidity
struct CriticalSuccess {
    bool triggered;
    uint256 bonusItems;
    uint256 qualityBoost;
    bool perfectCraft;
}

function processCriticalSuccess(
    uint256 recipeId,
    address crafter
) internal returns (CriticalSuccess memory) {
    CriticalSuccess memory result;
    
    // Calculate crit chance (based on luck and equipment)
    uint256 critChance = calculateCriticalChance(crafter);
    
    // Random roll
    uint256 roll = generateRandomNumber() % 100;
    
    if (roll < critChance) {
        result.triggered = true;
        
        // Determine bonus effects
        if (roll < critChance / 4) {
            // 25% chance for perfect craft
            result.perfectCraft = true;
        } else if (roll < critChance / 2) {
            // 25% chance for bonus items
            result.bonusItems = 1 + (roll % 3); // 1-3 bonus items
        } else {
            // 50% chance for quality boost
            result.qualityBoost = 10 + (roll % 21); // 10-30% quality boost
        }
    }
    
    return result;
}
```

### 2. Quality System
```solidity
enum ItemQuality {
    POOR,       // -20% to stats
    NORMAL,     // Base stats
    SUPERIOR,   // +10% to stats
    EXCELLENT,  // +25% to stats
    PERFECT     // +50% to stats
}

function determineQuality(
    uint256 recipeId,
    address crafter,
    CriticalSuccess memory critResult
) internal view returns (ItemQuality) {
    // Base quality roll
    uint256 roll = generateRandomNumber() % 100;
    
    // Apply crafter's skill bonus
    roll += calculateSkillBonus(crafter);
    
    // Apply critical success bonus
    if (critResult.perfectCraft) return ItemQuality.PERFECT;
    if (critResult.qualityBoost > 0) roll += critResult.qualityBoost;
    
    // Determine quality
    if (roll < 20) return ItemQuality.POOR;
    if (roll < 70) return ItemQuality.NORMAL;
    if (roll < 90) return ItemQuality.SUPERIOR;
    if (roll < 99) return ItemQuality.EXCELLENT;
    return ItemQuality.PERFECT;
}
```

### 3. Crafting Specializations
```solidity
enum CraftingSpecialization {
    WEAPONSMITH,
    ARMORSMITH,
    JEWELCRAFTER,
    ALCHEMIST,
    ENCHANTER
}

function getSpecializationBonus(
    address crafter,
    uint256 recipeId
) internal view returns (uint256) {
    CraftingSpecialization spec = character.getCraftingSpecialization(crafter);
    Recipe memory recipe = recipes[recipeId];
    
    // Check if recipe matches specialization
    if (recipeCategories[recipe.resultingItemId] == spec) {
        uint256 specLevel = character.getSpecializationLevel(crafter, spec);
        return Math.min(specLevel * 2, 30); // Up to 30% bonus
    }
    
    return 0;
}
```

## Integration Guide

### 1. Contract Integration
```solidity
interface IArcaneCrafting {
    function initialize(
        address _character,
        address _equipment,
        address _calculator,
        address _vrf
    ) external;
    
    function setResourceProvider(address provider, bool status) external;
    function setRecipeManager(address manager, bool status) external;
    function setCooldownController(address controller, bool status) external;
}
```

### 2. Event Handling
```solidity
// Core crafting events
event CraftingAttempted(
    address indexed crafter,
    uint256 indexed recipeId,
    bool success,
    uint256 timestamp
);

event CriticalSuccess(
    address indexed crafter,
    uint256 indexed recipeId,
    bool perfectCraft,
    uint256 bonusItems,
    uint256 qualityBoost
);

event QualityDetermined(
    uint256 indexed itemId,
    ItemQuality quality,
    uint256 timestamp
);

// System events
event RecipeCreated(uint256 indexed recipeId, uint256 timestamp);
event RecipeModified(uint256 indexed recipeId, uint256 timestamp);
event RecipeDeactivated(uint256 indexed recipeId, uint256 timestamp);
```

### 3. Error Handling
```solidity
// Custom errors for gas optimization
error InsufficientResources(address resource, uint256 required, uint256 available);
error InsufficientLPTokens(uint256 required, uint256 available);
error CooldownActive(uint256 remaining);
error InvalidRecipe(uint256 recipeId);
error InsufficientLevel(uint256 required, uint256 current);
error UnauthorizedCrafter(address crafter);
```

## Troubleshooting

### 1. Common Issues
1. **Insufficient Resources**
   ```solidity
   function checkResourceRequirements(
       uint256 recipeId,
       address crafter
   ) public view returns (
       bool sufficient,
       address[] memory missingResources,
       uint256[] memory missingAmounts
   ) {
       Recipe memory recipe = recipes[recipeId];
       uint256 missingCount = 0;
       
       // Count missing resources
       for (uint i = 0; i < recipe.resources.length; i++) {
           uint256 balance = IERC20(recipe.resources[i]).balanceOf(crafter);
           if (balance < recipe.resourceAmounts[i]) {
               missingCount++;
           }
       }
       
       // Allocate arrays
       missingResources = new address[](missingCount);
       missingAmounts = new uint256[](missingCount);
       
       // Fill missing resource information
       uint256 j = 0;
       for (uint i = 0; i < recipe.resources.length; i++) {
           uint256 balance = IERC20(recipe.resources[i]).balanceOf(crafter);
           if (balance < recipe.resourceAmounts[i]) {
               missingResources[j] = recipe.resources[i];
               missingAmounts[j] = recipe.resourceAmounts[i] - balance;
               j++;
           }
       }
       
       sufficient = missingCount == 0;
   }
   ```

2. **Cooldown Management**
   ```solidity
   function getCooldownInfo(
       uint256 recipeId,
       address crafter
   ) public view returns (
       bool isActive,
       uint256 remainingTime,
       uint256 totalCooldown
   ) {
       Recipe memory recipe = recipes[recipeId];
       uint256 lastCraft = craftingHistory[crafter][recipeId];
       
       totalCooldown = recipe.cooldown;
       
       if (lastCraft == 0) {
           return (false, 0, totalCooldown);
       }
       
       uint256 endTime = lastCraft + recipe.cooldown;
       if (block.timestamp < endTime) {
           return (true, endTime - block.timestamp, totalCooldown);
       }
       
       return (false, 0, totalCooldown);
   }
   ```

3. **Success Rate Issues**
   ```solidity
   function debugSuccessRate(
       uint256 recipeId,
       address crafter
   ) public view returns (
       uint256 baseRate,
       uint256 levelBonus,
       uint256 equipmentBonus,
       uint256 lpBonus,
       uint256 specializationBonus,
       uint256 finalRate
   ) {
       baseRate = getBaseSuccessRate(recipeId);
       levelBonus = calculateLevelBonus(crafter);
       equipmentBonus = calculateEquipmentBonus(crafter);
       lpBonus = calculateLPBonus(crafter, recipeId);
       specializationBonus = getSpecializationBonus(crafter, recipeId);
       
       finalRate = baseRate + levelBonus + equipmentBonus + lpBonus + specializationBonus;
       finalRate = Math.min(finalRate, 95); // Cap at 95%
   }
   ```

### 2. Monitoring Tools
```solidity
function getSystemStats() external view returns (
    uint256 totalRecipes,
    uint256 activeRecipes,
    uint256 totalCrafts,
    uint256 successfulCrafts,
    uint256 criticalSuccesses
) {
    return (
        _recipeIds.length,
        _activeRecipeCount,
        _totalCrafts,
        _successfulCrafts,
        _criticalSuccesses
    );
}

function getCrafterStats(
    address crafter
) external view returns (
    uint256 totalAttempts,
    uint256 successfulAttempts,
    uint256 criticalSuccesses,
    uint256 highestQualityCreated,
    uint256 specializationLevel,
    uint256 craftingScore
) {
    CrafterStats storage stats = crafterStats[crafter];
    return (
        stats.totalAttempts,
        stats.successfulAttempts,
        stats.criticalSuccesses,
        stats.highestQualityCreated,
        character.getSpecializationLevel(crafter, stats.specialization),
        calculateCraftingScore(crafter)
    );
}
```

### 3. Recovery Procedures
```solidity
function emergencyRecovery(
    uint256 recipeId,
    address crafter
) external onlyAdmin {
    // Clear cooldown
    delete craftingHistory[crafter][recipeId];
    
    // Refund resources if stuck
    Recipe memory recipe = recipes[recipeId];
    for (uint i = 0; i < recipe.resources.length; i++) {
        if (stuckResources[crafter][recipe.resources[i]] > 0) {
            uint256 amount = stuckResources[crafter][recipe.resources[i]];
            delete stuckResources[crafter][recipe.resources[i]];
            IERC20(recipe.resources[i]).transfer(crafter, amount);
        }
    }
    
    emit EmergencyRecovery(recipeId, crafter);
}
```

## Best Practices

1. **Resource Management**
   - Always check balances before crafting
   - Implement proper approval flows
   - Handle failed transfers gracefully

2. **Gas Optimization**
   - Batch similar operations
   - Use efficient data structures
   - Implement view functions for queries

3. **Security**
   - Implement access controls
   - Use reentrancy guards
   - Validate all inputs

4. **Maintenance**
   - Monitor system metrics
   - Adjust parameters as needed
   - Maintain documentation 