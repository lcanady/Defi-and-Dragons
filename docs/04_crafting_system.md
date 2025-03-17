# Crafting System Tutorial

## Overview
The Crafting System allows players to create equipment and items using resources and LP tokens. It features a unique AMM-driven crafting mechanism where success rates and requirements are tied to liquidity provision and market activity.

## Core Components

### ArcaneCrafting Contract
- Manages crafting recipes
- Handles crafting attempts
- Controls success rates
- Integrates with AMM system

### Recipe System
```solidity
struct Recipe {
    uint256 recipeId;
    uint256 resultingItemId;
    address lpToken;
    uint256 lpTokenAmount;
    address[] resources;
    uint256[] resourceAmounts;
    uint256 cooldown;
    bool isActive;
}
```

## Key Features

### Recipe Creation
```solidity
function createRecipe(
    uint256 recipeId,
    uint256 resultingItemId,
    address lpToken,
    uint256 lpTokenAmount,
    address[] memory resources,
    uint256[] memory resourceAmounts,
    uint256 cooldown
) external
```

Creates new recipes with:
- Required resources
- LP token requirements
- Success rate parameters
- Cooldown periods

### Crafting Mechanics
```solidity
function craftItem(uint256 recipeId) external
```

- Check resource requirements
- Verify LP token holdings
- Calculate success chance
- Handle crafting results

### Success Rate Calculation
```solidity
function calculateSuccessRate(
    uint256 recipeId,
    address crafter
) public view returns (uint256)
```

- Base success rate
- LP token multipliers
- Character bonuses
- Equipment modifiers

## Integration Points

### AMM System
- LP token requirements
- Market activity effects
- Liquidity-based bonuses

### Equipment System
- Crafted item creation
- Equipment requirements
- Bonus calculations

### Character System
- Character level requirements
- Skill bonuses
- Cooldown management

## Usage Examples

### Creating a Recipe
```solidity
// Define resource requirements
address[] memory resources = new address[](2);
resources[0] = address(resource1);
resources[1] = address(resource2);

uint256[] memory amounts = new uint256[](2);
amounts[0] = 100;
amounts[1] = 50;

// Create recipe
crafting.createRecipe(
    1, // recipeId
    1, // resultingItemId
    address(lpToken),
    1000, // lpTokenAmount
    resources,
    amounts,
    1 hours // cooldown
);
```

### Attempting to Craft
```solidity
// Approve resources and LP tokens
resource1.approve(address(crafting), 100);
resource2.approve(address(crafting), 50);
lpToken.approve(address(crafting), 1000);

// Attempt crafting
crafting.craftItem(1); // recipeId
```

### Checking Success Rate
```solidity
// Get base success rate
uint256 baseRate = crafting.getBaseSuccessRate(recipeId);

// Calculate final success rate
uint256 finalRate = crafting.calculateSuccessRate(
    recipeId,
    msg.sender
);
```

## Best Practices

1. **Recipe Design**
   - Balance resource requirements
   - Set appropriate cooldowns
   - Consider market dynamics

2. **Resource Management**
   - Track resource consumption
   - Handle failed attempts
   - Monitor market impact

3. **Integration**
   - Handle all failure cases
   - Emit detailed events
   - Maintain state consistency

4. **Gas Optimization**
   - Batch resource checks
   - Optimize success calculations
   - Handle refunds efficiently

## Common Pitfalls

1. **Resource Handling**
   - Insufficient approvals
   - Resource lock-up
   - Failed transfers

2. **Success Rate**
   - Incorrect calculations
   - Missing modifiers
   - Unhandled edge cases

3. **Integration Issues**
   - Incorrect permissions
   - Missing state updates
   - Improper error handling

## Security Considerations

1. **Resource Safety**
   - Secure resource transfers
   - Handle failed transfers
   - Protect against manipulation

2. **Access Control**
   - Recipe management
   - Admin functions
   - Emergency controls

3. **State Protection**
   - Cooldown enforcement
   - Rate limiting
   - Reentrancy protection

## Advanced Features

### Recipe Tiers
- Different difficulty levels
- Tier-specific requirements
- Scaled rewards

### Crafting Bonuses
- Character skill bonuses
- Equipment modifiers
- Time-based bonuses

### Critical Success
- Bonus item creation
- Quality improvements
- Special effects

## Testing Guidelines

1. **Unit Tests**
   - Test recipe creation
   - Verify success rates
   - Check resource handling

2. **Integration Tests**
   - Test AMM integration
   - Verify equipment creation
   - Check system interactions

3. **Edge Cases**
   - Test resource limits
   - Verify cooldowns
   - Check failure modes

## Performance Optimization

1. **Gas Usage**
   - Optimize resource checks
   - Batch operations
   - Minimize state changes

2. **Memory Management**
   - Efficient array handling
   - Optimize struct usage
   - Minimize storage operations

3. **Computation**
   - Cache calculations
   - Use efficient math
   - Optimize loops

## Monitoring and Maintenance

1. **Recipe Health**
   - Monitor success rates
   - Track resource usage
   - Check market impact

2. **System Status**
   - Track failed attempts
   - Monitor cooldowns
   - Check integration health

3. **Economic Balance**
   - Monitor resource sinks
   - Track item creation
   - Check market effects
</rewritten_file> 