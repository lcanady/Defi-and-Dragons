# Character System Tutorial

## Overview
The Character System is the foundation of the game, managing character creation, stats, equipment, and progression. Each character is a unique NFT with its own attributes and equipment loadout. This system integrates with multiple other game systems to provide a rich, interactive gaming experience.

## Core Components

### Character Contract
- Manages character creation and base stats
- Handles character progression and leveling
- Tracks character state and alignment
- Integrates with equipment and abilities
- Emits events for important state changes
- Implements access control for admin functions

### Character Wallet
- Manages character's equipment loadout
- Handles equipping/unequipping items
- Stores character-specific items
- Implements ERC1155 receiver for NFT items
- Provides inventory management functions
- Tracks equipment history and durability

## Key Features

### Character Creation
```solidity
function mintCharacter(
    address to,
    Types.Stats memory baseStats,
    Types.Alignment alignment
) external returns (uint256)
```

Creates a new character with:
- Base stats (strength, agility, magic)
- Alignment (determines bonus calculations)
- Unique character ID
- Equipment slots

Example usage with validation:
```solidity
// Input validation
require(baseStats.strength + baseStats.agility + baseStats.magic <= MAX_TOTAL_STATS, 
    "Total stats exceed maximum");
require(baseStats.strength >= MIN_STAT && baseStats.strength <= MAX_STAT, 
    "Invalid strength value");

// Create character with balanced stats
Types.Stats memory stats = Types.Stats({
    strength: 10,
    agility: 10,
    magic: 10
});

// Mint character with strength alignment for tank build
uint256 characterId = character.mintCharacter(
    playerAddress,
    stats,
    Types.Alignment.STRENGTH
);

// Emit event for tracking
emit CharacterCreated(characterId, playerAddress, stats, Types.Alignment.STRENGTH);
```

### Equipment Management
```solidity
function equip(uint256 weaponId, uint256 armorId) external
function unequip(bool weapon, bool armor) external
```

Equipment system features:
- Characters can equip one weapon and one armor piece
- Equipment provides stat bonuses
- Equipment can be swapped or unequipped
- Equipment has durability and level requirements
- Some equipment has alignment restrictions
- Equipment can provide special abilities or effects

Example equipment workflow:
```solidity
// Check equipment requirements
require(character.getLevel(characterId) >= equipment.getRequiredLevel(weaponId), 
    "Level too low for weapon");

// Verify equipment ownership
require(equipment.ownerOf(weaponId) == msg.sender, "Not weapon owner");

// Check equipment compatibility
require(equipment.getAlignment(weaponId) == character.getAlignment(characterId) ||
    equipment.getAlignment(weaponId) == Types.Alignment.NEUTRAL,
    "Incompatible alignment");

// Equip items
CharacterWallet wallet = character.getWallet(characterId);
wallet.equip(weaponId, armorId);

// Calculate and apply bonuses
calculator.updateEquipmentBonuses(characterId);
```

### Character Stats
```solidity
struct Stats {
    uint8 strength;
    uint8 agility;
    uint8 magic;
}
```

Stats system details:
- Base stats affect various game mechanics:
  - Strength: Melee damage, carrying capacity, physical resistance
  - Agility: Attack speed, dodge chance, movement speed
  - Magic: Spell power, mana pool, magical resistance

Stats can be modified by:
- Equipment bonuses
  ```solidity
  // Example equipment bonus calculation
  function calculateEquipmentBonus(uint256 characterId) public view returns (Stats memory) {
      Stats memory bonus;
      uint256 weaponId = getEquippedWeapon(characterId);
      uint256 armorId = getEquippedArmor(characterId);
      
      if (weaponId != 0) {
          Stats memory weaponBonus = equipment.getBonusStats(weaponId);
          bonus.strength += weaponBonus.strength;
          bonus.agility += weaponBonus.agility;
          bonus.magic += weaponBonus.magic;
      }
      
      // Similar for armor...
      return bonus;
  }
  ```
- Pet bonuses
  - Passive stat increases based on pet type and level
  - Active bonuses during pet abilities
- Mount bonuses
  - Movement speed increases
  - Carrying capacity bonuses
  - Combat stat modifications
- Ability effects
  - Temporary stat boosts from buffs
  - Stat reductions from debuffs
  - Permanent stat increases from achievements

### Character State
```solidity
struct State {
    uint256 level;
    uint256 experience;
    bool isActive;
    uint256 lastActionTime;
    uint256 statusEffects;
    mapping(uint256 => uint256) cooldowns;
}
```

State management features:
- Tracks character progression
  - Experience gain from actions
  - Level-up requirements and rewards
  - Achievement tracking
- Manages cooldowns and timers
  - Ability cooldowns
  - Rest periods
  - Daily/weekly action limits
- Controls character availability
  - Active/inactive status
  - Staking status
  - PvP availability

Example state management:
```solidity
// Level up character
function levelUp(uint256 characterId) external {
    State storage state = characters[characterId];
    require(state.experience >= getRequiredExperience(state.level), "Insufficient XP");
    
    state.level++;
    emit LevelUp(characterId, state.level);
    
    // Grant level-up rewards
    if (state.level % 5 == 0) {
        grantStatPoint(characterId);
    }
    
    // Update derived attributes
    calculator.updateCharacterAttributes(characterId);
}

// Cooldown management
function startCooldown(uint256 characterId, uint256 actionType) internal {
    State storage state = characters[characterId];
    uint256 cooldownDuration = getCooldownDuration(actionType);
    state.cooldowns[actionType] = block.timestamp + cooldownDuration;
}

function isOnCooldown(uint256 characterId, uint256 actionType) public view returns (bool) {
    return characters[characterId].cooldowns[actionType] > block.timestamp;
}
```

## Integration Points

### Equipment System
Detailed equipment integration:
```solidity
interface IEquipment {
    function getStats(uint256 equipmentId) external view returns (Stats memory);
    function getDurability(uint256 equipmentId) external view returns (uint256);
    function getRequirements(uint256 equipmentId) external view 
        returns (uint256 level, Types.Alignment alignment);
    function useEquipment(uint256 equipmentId) external;
}

// Equipment usage example
function useWeapon(uint256 characterId, uint256 targetId) external {
    uint256 weaponId = getEquippedWeapon(characterId);
    require(weaponId != 0, "No weapon equipped");
    
    // Check durability
    require(equipment.getDurability(weaponId) > 0, "Weapon broken");
    
    // Use weapon
    equipment.useEquipment(weaponId);
    
    // Calculate and apply damage
    uint256 damage = calculator.calculateWeaponDamage(characterId, targetId);
    applyDamage(targetId, damage);
}
```

### Pet System
- Characters can own and bond with pets
- Pets provide passive bonuses
- Pet abilities complement character stats

Detailed pet integration:
```solidity
interface IPet {
    function bond(uint256 petId, uint256 characterId) external;
    function getBonuses(uint256 petId) external view returns (Stats memory);
    function useAbility(uint256 petId, uint256 targetId) external;
    function getPetLevel(uint256 petId) external view returns (uint256);
}

// Example pet bonding and usage
function bondWithPet(uint256 characterId, uint256 petId) external {
    // Verify ownership
    require(pets.ownerOf(petId) == msg.sender, "Not pet owner");
    
    // Check character requirements
    require(character.getLevel(characterId) >= pets.getRequiredLevel(petId),
        "Character level too low");
    
    // Bond pet
    pets.bond(petId, characterId);
    
    // Update character bonuses
    calculator.updatePetBonuses(characterId);
    
    emit PetBonded(characterId, petId);
}

// Using pet abilities
function usePetAbility(uint256 characterId, uint256 targetId) external {
    uint256 petId = getBondedPet(characterId);
    require(petId != 0, "No bonded pet");
    require(!isOnCooldown(characterId, ABILITY_PET), "Pet ability on cooldown");
    
    // Use pet ability
    pets.useAbility(petId, targetId);
    
    // Start cooldown
    startCooldown(characterId, ABILITY_PET);
}
```

### Mount System
- Characters can own and ride mounts
- Mounts provide travel benefits
- Mount bonuses affect gameplay mechanics

Mount system implementation:
```solidity
interface IMount {
    function mount(uint256 mountId, uint256 characterId) external;
    function dismount(uint256 mountId) external;
    function getSpeedBonus(uint256 mountId) external view returns (uint256);
    function getCarryingCapacity(uint256 mountId) external view returns (uint256);
}

// Mount management example
function mountCreature(uint256 characterId, uint256 mountId) external {
    // Check ownership and requirements
    require(mounts.ownerOf(mountId) == msg.sender, "Not mount owner");
    require(character.getLevel(characterId) >= mounts.getRequiredLevel(mountId),
        "Level too low for mount");
    
    // Check character state
    require(!isInCombat(characterId), "Cannot mount during combat");
    require(!isMounted(characterId), "Already mounted");
    
    // Mount the creature
    mounts.mount(mountId, characterId);
    
    // Apply mount bonuses
    uint256 speedBonus = mounts.getSpeedBonus(mountId);
    uint256 capacityBonus = mounts.getCarryingCapacity(mountId);
    
    updateCharacterMovementSpeed(characterId, speedBonus);
    updateCharacterCapacity(characterId, capacityBonus);
    
    emit CharacterMounted(characterId, mountId);
}
```

### Ability System
- Characters can learn and use abilities
- Abilities provide active and passive effects
- Ability cooldowns are tracked per character

Comprehensive ability system:
```solidity
struct Ability {
    uint256 id;
    string name;
    uint256 manaCost;
    uint256 cooldown;
    Types.DamageType damageType;
    uint256 baseEffect;
    bool isPassive;
}

interface IAbility {
    function learnAbility(uint256 characterId, uint256 abilityId) external;
    function useAbility(uint256 characterId, uint256 targetId, uint256 abilityId) external;
    function getAbilityEffect(uint256 characterId, uint256 abilityId) external view 
        returns (uint256);
}

// Ability usage example
function castAbility(uint256 characterId, uint256 targetId, uint256 abilityId) external {
    // Verify ability ownership
    require(hasLearnedAbility(characterId, abilityId), "Ability not learned");
    
    // Check requirements
    require(!isOnCooldown(characterId, abilityId), "Ability on cooldown");
    require(character.getMana(characterId) >= abilities.getManaCost(abilityId),
        "Insufficient mana");
    
    // Calculate ability effect
    uint256 effect = abilities.getAbilityEffect(characterId, abilityId);
    
    // Apply stat modifiers
    Stats memory stats = calculator.getTotalStats(characterId);
    if (abilities.getDamageType(abilityId) == Types.DamageType.MAGICAL) {
        effect = effect * (100 + stats.magic) / 100;
    }
    
    // Use ability
    abilities.useAbility(characterId, targetId, abilityId);
    
    // Apply costs and cooldown
    character.useMana(characterId, abilities.getManaCost(abilityId));
    startCooldown(characterId, abilityId);
    
    emit AbilityUsed(characterId, targetId, abilityId, effect);
}
```

## Usage Examples

### Creating a New Character
```solidity
// Create base stats
Types.Stats memory stats = Types.Stats({
    strength: 10,
    agility: 8,
    magic: 6
});

// Mint character
uint256 characterId = character.mintCharacter(
    playerAddress,
    stats,
    Types.Alignment.STRENGTH
);
```

### Equipping Items
```solidity
// Get character's wallet
CharacterWallet wallet = character.getWallet(characterId);

// Equip items
wallet.equip(weaponId, armorId);
```

### Checking Character Stats
```solidity
// Get total stats including equipment
(Types.Stats memory totalStats,) = calculator.calculateTotalAttributes(characterId);

// Access individual stats
uint8 strength = totalStats.strength;
uint8 agility = totalStats.agility;
uint8 magic = totalStats.magic;
```

## Best Practices

1. **State Management**
   - Always check character state before actions
   - Update state after significant changes
   - Handle cooldowns appropriately

2. **Equipment Handling**
   - Verify equipment ownership before equipping
   - Check equipment compatibility
   - Handle equipment bonuses correctly

3. **Integration**
   - Use events to track important changes
   - Maintain proper access control
   - Follow the checks-effects-interactions pattern

4. **Gas Optimization**
   - Batch operations when possible
   - Use efficient storage patterns
   - Minimize state changes

## Common Pitfalls

1. **Equipment Validation**
   - Not checking equipment ownership
   - Ignoring equipment requirements
   - Incorrect bonus calculations

2. **State Updates**
   - Missing state updates after actions
   - Incorrect cooldown management
   - Race conditions in state changes

3. **Integration Issues**
   - Incorrect permission handling
   - Missing event emissions
   - Improper error handling

## Security Considerations

1. **Access Control**
   - Use proper modifiers for restricted functions
   - Validate caller permissions
   - Implement reentrancy guards

2. **State Protection**
   - Prevent unauthorized state changes
   - Protect against manipulation
   - Validate all inputs

3. **Asset Safety**
   - Secure equipment transfers
   - Protect against unauthorized equips
   - Handle edge cases safely 

## Advanced Features

### Character Progression System
```solidity
struct ProgressionData {
    uint256 experience;
    uint256 level;
    uint256 skillPoints;
    mapping(uint256 => uint256) skillLevels;
    Achievement[] completedAchievements;
}

// Experience and leveling
function gainExperience(uint256 characterId, uint256 amount) external {
    require(isActive(characterId), "Character inactive");
    
    ProgressionData storage data = progression[characterId];
    data.experience += amount;
    
    // Check for level up
    while (data.experience >= getRequiredExperience(data.level)) {
        levelUp(characterId);
    }
    
    emit ExperienceGained(characterId, amount);
}

// Skill system
function allocateSkillPoints(uint256 characterId, uint256 skillId, uint256 points) external {
    ProgressionData storage data = progression[characterId];
    require(data.skillPoints >= points, "Insufficient skill points");
    require(data.skillLevels[skillId] + points <= MAX_SKILL_LEVEL, 
        "Exceeds max skill level");
    
    data.skillPoints -= points;
    data.skillLevels[skillId] += points;
    
    // Update character attributes
    calculator.updateSkillBonuses(characterId);
    
    emit SkillPointsAllocated(characterId, skillId, points);
}
```

### Achievement System
```solidity
struct Achievement {
    uint256 id;
    string name;
    uint256 rewardExp;
    Stats rewardStats;
    bool completed;
}

function completeAchievement(uint256 characterId, uint256 achievementId) internal {
    Achievement storage achievement = achievements[achievementId];
    require(!achievement.completed, "Achievement already completed");
    
    // Grant rewards
    gainExperience(characterId, achievement.rewardExp);
    addPermanentStats(characterId, achievement.rewardStats);
    
    // Mark completed
    achievement.completed = true;
    
    emit AchievementCompleted(characterId, achievementId);
}
```

## Testing Guidelines

### Unit Testing
```solidity
contract CharacterSystemTest is Test {
    Character character;
    Equipment equipment;
    Calculator calculator;
    
    function setUp() public {
        character = new Character();
        equipment = new Equipment();
        calculator = new Calculator();
    }
    
    function testCharacterCreation() public {
        // Test basic character creation
        Stats memory stats = Stats({
            strength: 10,
            agility: 10,
            magic: 10
        });
        
        uint256 characterId = character.mintCharacter(
            address(this),
            stats,
            Types.Alignment.STRENGTH
        );
        
        assertTrue(character.exists(characterId));
        
        // Verify initial state
        (Stats memory charStats,) = calculator.calculateTotalAttributes(characterId);
        assertEq(charStats.strength, stats.strength);
        assertEq(charStats.agility, stats.agility);
        assertEq(charStats.magic, stats.magic);
    }
    
    function testEquipmentIntegration() public {
        // Test equipment equipping and stat calculations
        uint256 characterId = createTestCharacter();
        uint256 weaponId = createTestWeapon();
        
        character.getWallet(characterId).equip(weaponId, 0);
        
        // Verify equipment bonuses
        (Stats memory totalStats,) = calculator.calculateTotalAttributes(characterId);
        assertTrue(totalStats.strength > 10, "Equipment bonus not applied");
    }
}
```

### Integration Testing
```solidity
contract CharacterIntegrationTest is Test {
    function testFullGameplayLoop() public {
        // Create character
        uint256 characterId = createCharacter();
        
        // Level up
        grantExperience(characterId, 1000);
        assertTrue(character.getLevel(characterId) > 1);
        
        // Equip items
        equipGear(characterId);
        
        // Use abilities
        useAbilities(characterId);
        
        // Verify state
        validateCharacterState(characterId);
    }
}
```

## Deployment and Upgrades

### Deployment Script
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Character} from "../src/Character.sol";
import {Equipment} from "../src/Equipment.sol";
import {Calculator} from "../src/Calculator.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Character character = new Character();
        Equipment equipment = new Equipment();
        Calculator calculator = new Calculator();
        
        // Initialize contracts
        character.initialize(address(equipment), address(calculator));
        equipment.initialize(address(character));
        calculator.initialize(address(character), address(equipment));
        
        vm.stopBroadcast();
    }
}
```

### Upgrade Process
```solidity
// Example upgrade function
function upgradeCharacterSystem(address newImplementation) external onlyAdmin {
    // Verify new implementation
    require(ICharacter(newImplementation).supportsInterface(type(ICharacter).interfaceId),
        "Invalid implementation");
    
    // Pause system
    _pause();
    
    // Upgrade implementation
    _upgradeToAndCall(newImplementation, "");
    
    // Unpause system
    _unpause();
    
    emit SystemUpgraded(newImplementation);
}
```

## Error Handling and Recovery

### State Recovery
```solidity
function recoverCharacterState(uint256 characterId) external onlyAdmin {
    // Verify character exists
    require(exists(characterId), "Character does not exist");
    
    // Reset cooldowns
    clearCooldowns(characterId);
    
    // Unequip all items
    unequipAll(characterId);
    
    // Reset combat state
    resetCombatState(characterId);
    
    // Emit recovery event
    emit CharacterStateRecovered(characterId);
}
```

### Emergency Shutdown
```solidity
function emergencyShutdown() external onlyAdmin {
    // Pause all character actions
    _pause();
    
    // End all active combat
    endAllCombat();
    
    // Dismount all characters
    dismountAll();
    
    emit EmergencyShutdown(block.timestamp);
}
```

## Events and Logging

```solidity
// Core events
event CharacterCreated(uint256 indexed characterId, address owner, Stats baseStats, Types.Alignment alignment);
event LevelUp(uint256 indexed characterId, uint256 newLevel);
event ExperienceGained(uint256 indexed characterId, uint256 amount);
event StatUpdate(uint256 indexed characterId, Stats newStats);

// Equipment events
event ItemEquipped(uint256 indexed characterId, uint256 itemId, Types.EquipmentSlot slot);
event ItemUnequipped(uint256 indexed characterId, Types.EquipmentSlot slot);

// Combat events
event AbilityUsed(uint256 indexed characterId, uint256 targetId, uint256 abilityId, uint256 effect);
event DamageTaken(uint256 indexed characterId, uint256 amount, Types.DamageType damageType);
event CharacterDefeated(uint256 indexed characterId, uint256 indexed defeatedBy);

// System events
event EmergencyShutdown(uint256 timestamp);
event CharacterStateRecovered(uint256 indexed characterId);
```

## Troubleshooting Guide

### Common Issues
1. Character state inconsistencies
   - Check event logs for unexpected state changes
   - Verify all modifiers and requirements are working
   - Ensure proper error handling in state transitions

2. Equipment bonuses not applying
   - Verify equipment ownership and requirements
   - Check calculator contract integration
   - Confirm proper event emission and handling

3. Cooldown synchronization
   - Validate timestamp handling
   - Check for proper cooldown clearing
   - Verify cooldown calculations

### Debug Tools
```solidity
function debugCharacterState(uint256 characterId) external view returns (
    State memory state,
    Stats memory stats,
    uint256[] memory equipment,
    uint256[] memory cooldowns
) {
    // Get full character state for debugging
    state = characters[characterId];
    stats = calculator.getTotalStats(characterId);
    equipment = getEquippedItems(characterId);
    cooldowns = getActiveCooldowns(characterId);
}
```

### Monitoring
```solidity
function getSystemStats() external view returns (
    uint256 totalCharacters,
    uint256 activeCharacters,
    uint256 totalEquipment,
    uint256 totalAbilities
) {
    totalCharacters = _characterIds.length;
    activeCharacters = _getActiveCharacterCount();
    totalEquipment = equipment.totalSupply();
    totalAbilities = abilities.totalAbilities();
}
```

## Performance Optimization Tips

1. **Storage Optimization**
   - Pack related storage variables
   - Use appropriate data types
   - Minimize storage writes
   - Use events for historical data

2. **Gas Efficiency**
   - Batch operations when possible
   - Use memory for temporary calculations
   - Implement efficient loops
   - Cache frequently accessed values

3. **Network Load**
   - Use view functions for queries
   - Implement pagination for large datasets
   - Cache results off-chain when possible
   - Use events for off-chain tracking

## Security Checklist

1. **Access Control**
   - [ ] Implement role-based access control
   - [ ] Use proper modifiers for restricted functions
   - [ ] Validate all caller permissions
   - [ ] Implement timelock for sensitive operations

2. **State Protection**
   - [ ] Use reentrancy guards
   - [ ] Validate all state transitions
   - [ ] Implement circuit breakers
   - [ ] Handle edge cases safely

3. **Asset Safety**
   - [ ] Secure all value transfers
   - [ ] Implement withdrawal patterns
   - [ ] Validate equipment ownership
   - [ ] Handle NFT transfers safely

4. **System Integrity**
   - [ ] Maintain proper state synchronization
   - [ ] Implement proper error handling
   - [ ] Use safe math operations
   - [ ] Handle upgrades safely

## Future Considerations

1. **Scalability**
   - Layer 2 integration for reduced gas costs
   - Sharding support for improved performance
   - Off-chain computation for complex calculations
   - State channel integration for rapid actions

2. **Extensibility**
   - Plugin system for new features
   - Modular ability system
   - Customizable progression paths
   - Dynamic content updates

3. **Interoperability**
   - Cross-game asset support
   - Multi-chain deployment options
   - Standard interface compliance
   - External protocol integration

## Contributing Guidelines

1. **Code Style**
   - Follow Solidity style guide
   - Use proper NatSpec comments
   - Maintain consistent naming conventions
   - Document all public interfaces

2. **Testing Requirements**
   - Write comprehensive unit tests
   - Include integration tests
   - Test edge cases
   - Maintain high coverage

3. **Review Process**
   - Submit detailed PR descriptions
   - Include test results
   - Document breaking changes
   - Update documentation

## Support and Resources

1. **Documentation**
   - Technical specifications
   - API documentation
   - Integration guides
   - Troubleshooting guides

2. **Community**
   - Discord server
   - Developer forum
   - Bug reporting system
   - Feature request process

3. **Tools and SDKs**
   - Development tools
   - Testing frameworks
   - Deployment scripts
   - Monitoring tools 