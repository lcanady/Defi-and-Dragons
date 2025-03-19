# Pet & Mount System Documentation

## Overview
The Pet & Mount System is an advanced companion and transportation framework that enriches gameplay through strategic bonuses and unique abilities. This system implements ERC721 tokens for unique pets and mounts, featuring dynamic bonding mechanics, evolution paths, and synergistic interactions with other game systems. Pets provide scalable passive benefits including resource yield enhancements and rare item discovery, while mounts offer sophisticated travel mechanics and staking advantages that integrate with the game's economic systems.

## Core Components

### Contract Architecture
The system is built on a modular architecture with the following key contracts:

```solidity
interface IPet {
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    enum PetType { COMPANION, UTILITY, COMBAT }
    
    struct PetAttributes {
        string name;
        string description;
        Rarity rarity;
        PetType petType;
        uint256 yieldBoost;
        uint256 dropRateBoost;
        uint256 requiredLevel;
        uint256 experience;
        uint256 level;
        bool isEvolved;
    }
}

interface IMount {
    enum MountType { GROUND, FLYING, AQUATIC, ETHEREAL }
    enum MountTier { BASIC, ADVANCED, ELITE, LEGENDARY }
    
    struct MountAttributes {
        string name;
        string description;
        MountType mountType;
        MountTier tier;
        uint256 questFeeReduction;
        uint256 travelTimeReduction;
        uint256 stakingBoost;
        uint256 lpLockReduction;
        uint256 requiredLevel;
        uint256 stamina;
        uint256 training;
    }
}
```

### Pet Contract Implementation
```solidity
contract ArcanePet is IPet, ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIds;
    mapping(uint256 => PetAttributes) public petAttributes;
    mapping(uint256 => uint256) public petBondedTo; // Pet ID => Character ID
    mapping(uint256 => uint256) public characterBondedPet; // Character ID => Pet ID
    
    event PetCreated(uint256 indexed petId, string name, Rarity rarity, PetType petType);
    event PetBonded(uint256 indexed petId, uint256 indexed characterId);
    event PetUnbonded(uint256 indexed petId, uint256 indexed characterId);
    event PetEvolved(uint256 indexed petId, uint256 newLevel);
    event ExperienceGained(uint256 indexed petId, uint256 amount);
    
    constructor() ERC721("ArcanePet", "APET") {}
    
    function createPet(
        string memory name,
        string memory description,
        Rarity rarity,
        PetType petType,
        uint256 yieldBoost,
        uint256 dropRateBoost,
        uint256 requiredLevel
    ) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newPetId = _tokenIds.current();
        
        petAttributes[newPetId] = PetAttributes({
            name: name,
            description: description,
            rarity: rarity,
            petType: petType,
            yieldBoost: yieldBoost,
            dropRateBoost: dropRateBoost,
            requiredLevel: requiredLevel,
            experience: 0,
            level: 1,
            isEvolved: false
        });
        
        _safeMint(msg.sender, newPetId);
        emit PetCreated(newPetId, name, rarity, petType);
        return newPetId;
    }
    
    function bondPet(uint256 petId, uint256 characterId) external {
        require(ownerOf(petId) == msg.sender, "Not pet owner");
        require(petBondedTo[petId] == 0, "Pet already bonded");
        require(characterBondedPet[characterId] == 0, "Character already has pet");
        
        // Verify character ownership and level requirement
        require(
            ICharacter(characterContract).ownerOf(characterId) == msg.sender,
            "Not character owner"
        );
        require(
            ICharacter(characterContract).getLevel(characterId) >= petAttributes[petId].requiredLevel,
            "Level requirement not met"
        );
        
        petBondedTo[petId] = characterId;
        characterBondedPet[characterId] = petId;
        
        emit PetBonded(petId, characterId);
    }
    
    function gainExperience(uint256 petId, uint256 amount) external {
        require(petBondedTo[petId] != 0, "Pet not bonded");
        
        PetAttributes storage pet = petAttributes[petId];
        pet.experience = pet.experience.add(amount);
        
        // Level up logic
        uint256 newLevel = calculateLevel(pet.experience);
        if (newLevel > pet.level) {
            pet.level = newLevel;
            updatePetBonuses(petId);
            emit PetEvolved(petId, newLevel);
        }
        
        emit ExperienceGained(petId, amount);
    }
    
    function getPetBenefits(uint256 characterId) external view returns (
        uint256 yieldBoost,
        uint256 dropRateBoost
    ) {
        uint256 petId = characterBondedPet[characterId];
        if (petId == 0) return (0, 0);
        
        PetAttributes memory pet = petAttributes[petId];
        return (
            calculateBoost(pet.yieldBoost, pet.level, pet.rarity),
            calculateBoost(pet.dropRateBoost, pet.level, pet.rarity)
        );
    }
    
    function calculateBoost(
        uint256 baseBoost,
        uint256 level,
        Rarity rarity
    ) internal pure returns (uint256) {
        uint256 rarityMultiplier = uint256(rarity) + 1;
        return baseBoost
            .mul(level)
            .mul(rarityMultiplier)
            .div(100);
    }
}
```

### Mount Contract Implementation
```solidity
contract ArcaneMount is IMount, ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIds;
    mapping(uint256 => MountAttributes) public mountAttributes;
    mapping(uint256 => uint256) public mountRider; // Mount ID => Character ID
    mapping(uint256 => uint256) public characterActiveMount; // Character ID => Mount ID
    
    event MountCreated(uint256 indexed mountId, string name, MountType mountType, MountTier tier);
    event MountMounted(uint256 indexed mountId, uint256 indexed characterId);
    event MountDismounted(uint256 indexed mountId, uint256 indexed characterId);
    event MountTrained(uint256 indexed mountId, uint256 newTraining);
    event StaminaUpdated(uint256 indexed mountId, uint256 newStamina);
    
    constructor() ERC721("ArcaneMount", "AMNT") {}
    
    function createMount(
        string memory name,
        string memory description,
        MountType mountType,
        MountTier tier,
        uint256 questFeeReduction,
        uint256 travelTimeReduction,
        uint256 stakingBoost,
        uint256 lpLockReduction,
        uint256 requiredLevel
    ) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newMountId = _tokenIds.current();
        
        mountAttributes[newMountId] = MountAttributes({
            name: name,
            description: description,
            mountType: mountType,
            tier: tier,
            questFeeReduction: questFeeReduction,
            travelTimeReduction: travelTimeReduction,
            stakingBoost: stakingBoost,
            lpLockReduction: lpLockReduction,
            requiredLevel: requiredLevel,
            stamina: 100,
            training: 0
        });
        
        _safeMint(msg.sender, newMountId);
        emit MountCreated(newMountId, name, mountType, tier);
        return newMountId;
    }
    
    function mount(uint256 mountId, uint256 characterId) external {
        require(ownerOf(mountId) == msg.sender, "Not mount owner");
        require(mountRider[mountId] == 0, "Mount already in use");
        require(characterActiveMount[characterId] == 0, "Character already mounted");
        
        // Verify character ownership and level requirement
        require(
            ICharacter(characterContract).ownerOf(characterId) == msg.sender,
            "Not character owner"
        );
        require(
            ICharacter(characterContract).getLevel(characterId) >= mountAttributes[mountId].requiredLevel,
            "Level requirement not met"
        );
        
        mountRider[mountId] = characterId;
        characterActiveMount[characterId] = mountId;
        
        emit MountMounted(mountId, characterId);
    }
    
    function trainMount(uint256 mountId) external {
        require(ownerOf(mountId) == msg.sender, "Not mount owner");
        
        MountAttributes storage mount = mountAttributes[mountId];
        require(mount.training < 100, "Training maxed");
        
        // Training logic
        mount.training = mount.training.add(1);
        updateMountBonuses(mountId);
        
        emit MountTrained(mountId, mount.training);
    }
    
    function getMountBenefits(uint256 characterId) external view returns (
        uint256 questFeeReduction,
        uint256 travelTimeReduction,
        uint256 stakingBoost,
        uint256 lpLockReduction
    ) {
        uint256 mountId = characterActiveMount[characterId];
        if (mountId == 0) return (0, 0, 0, 0);
        
        MountAttributes memory mount = mountAttributes[mountId];
        return (
            calculateBonus(mount.questFeeReduction, mount.training, mount.tier),
            calculateBonus(mount.travelTimeReduction, mount.training, mount.tier),
            calculateBonus(mount.stakingBoost, mount.training, mount.tier),
            calculateBonus(mount.lpLockReduction, mount.training, mount.tier)
        );
    }
    
    function calculateBonus(
        uint256 baseBonus,
        uint256 training,
        MountTier tier
    ) internal pure returns (uint256) {
        uint256 tierMultiplier = uint256(tier) + 1;
        return baseBonus
            .mul(100 + training)
            .mul(tierMultiplier)
            .div(10000);
    }
}
```

## Integration Examples

### Character System Integration
```solidity
contract ArcaneCharacter {
    IArcaneMount public mount;
    IArcanePet public pet;
    
    function calculateTotalBonuses(uint256 characterId) external view returns (
        uint256 totalYieldBoost,
        uint256 totalDropBoost,
        uint256 totalQuestDiscount,
        uint256 totalTravelReduction
    ) {
        // Get pet bonuses
        (uint256 petYield, uint256 petDrop) = pet.getPetBenefits(characterId);
        
        // Get mount bonuses
        (
            uint256 mountQuest,
            uint256 mountTravel,
            uint256 mountStaking,
            uint256 mountLock
        ) = mount.getMountBenefits(characterId);
        
        // Calculate total bonuses with synergy effects
        totalYieldBoost = petYield.add(mountStaking);
        totalDropBoost = petDrop;
        totalQuestDiscount = mountQuest;
        totalTravelReduction = mountTravel;
        
        // Apply synergy bonuses if both pet and mount are active
        if (pet.characterBondedPet(characterId) != 0 && mount.characterActiveMount(characterId) != 0) {
            totalYieldBoost = totalYieldBoost.mul(12).div(10); // 20% synergy bonus
            totalDropBoost = totalDropBoost.mul(12).div(10);
        }
    }
}
```

### Quest System Integration
```solidity
contract ArcaneQuests {
    IArcaneMount public mount;
    IArcanePet public pet;
    
    function calculateQuestRewards(
        uint256 characterId,
        uint256 questId
    ) external view returns (uint256 rewards, uint256 dropChance) {
        Quest memory quest = quests[questId];
        
        // Get pet and mount bonuses
        (uint256 petYield, uint256 petDrop) = pet.getPetBenefits(characterId);
        (uint256 questDiscount,,, uint256 lockReduction) = mount.getMountBenefits(characterId);
        
        // Calculate rewards with bonuses
        rewards = quest.baseReward.mul(100 + petYield).div(100);
        dropChance = quest.baseDropChance.mul(100 + petDrop).div(100);
        
        // Apply quest fee reduction
        uint256 fee = quest.fee.mul(100 - questDiscount).div(100);
        
        return (rewards, dropChance);
    }
}
```

## Advanced Features

### Evolution System
```solidity
contract PetEvolution {
    struct EvolutionRequirement {
        uint256 requiredLevel;
        uint256 requiredExperience;
        uint256[] requiredItems;
        uint256[] itemAmounts;
    }
    
    mapping(uint256 => EvolutionRequirement) public evolutionRequirements;
    
    function evolve(uint256 petId) external {
        PetAttributes storage pet = petAttributes[petId];
        require(!pet.isEvolved, "Already evolved");
        
        EvolutionRequirement memory req = evolutionRequirements[petId];
        require(pet.level >= req.requiredLevel, "Level too low");
        require(pet.experience >= req.requiredExperience, "Not enough experience");
        
        // Check and consume required items
        for (uint256 i = 0; i < req.requiredItems.length; i++) {
            uint256 itemId = req.requiredItems[i];
            uint256 amount = req.itemAmounts[i];
            require(
                IERC1155(itemContract).balanceOf(msg.sender, itemId) >= amount,
                "Insufficient items"
            );
            IERC1155(itemContract).burn(msg.sender, itemId, amount);
        }
        
        // Perform evolution
        pet.isEvolved = true;
        updatePetBonuses(petId);
        
        emit PetEvolved(petId);
    }
}
```

### Mount Training System
```solidity
contract MountTraining {
    struct TrainingSession {
        uint256 startTime;
        uint256 duration;
        uint256 difficulty;
        bool completed;
    }
    
    mapping(uint256 => TrainingSession) public activeTraining;
    
    function startTraining(uint256 mountId, uint256 difficulty) external {
        require(ownerOf(mountId) == msg.sender, "Not mount owner");
        require(activeTraining[mountId].startTime == 0, "Training in progress");
        
        uint256 duration = calculateTrainingDuration(difficulty);
        activeTraining[mountId] = TrainingSession({
            startTime: block.timestamp,
            duration: duration,
            difficulty: difficulty,
            completed: false
        });
        
        emit TrainingStarted(mountId, difficulty, duration);
    }
    
    function completeTraining(uint256 mountId) external {
        TrainingSession storage session = activeTraining[mountId];
        require(session.startTime > 0, "No active training");
        require(!session.completed, "Training already completed");
        require(
            block.timestamp >= session.startTime + session.duration,
            "Training not finished"
        );
        
        // Calculate training rewards
        uint256 experienceGained = calculateExperience(session.difficulty);
        uint256 trainingGained = calculateTrainingPoints(session.difficulty);
        
        // Update mount attributes
        MountAttributes storage mount = mountAttributes[mountId];
        mount.training = mount.training.add(trainingGained);
        
        session.completed = true;
        delete activeTraining[mountId];
        
        emit TrainingCompleted(mountId, trainingGained, experienceGained);
    }
}
```

## Gas Optimization Examples

### Efficient Storage Layout
```solidity
contract OptimizedPetMount {
    // Pack common variables into single storage slots
    struct PackedPetInfo {
        uint40 experience;      // Up to 1 trillion
        uint8 level;           // Up to 255
        uint8 rarity;          // Enum value
        uint8 petType;         // Enum value
        bool isEvolved;        // Boolean flag
        uint40 bondTimestamp;  // Unix timestamp
        uint40 lastFed;        // Unix timestamp
        uint8 happiness;       // 0-100
        uint8 energy;         // 0-100
    }
    
    struct PackedMountInfo {
        uint40 training;       // Up to 1 trillion
        uint8 tier;           // Enum value
        uint8 mountType;      // Enum value
        uint40 lastRidden;    // Unix timestamp
        uint8 stamina;        // 0-100
        uint8 loyalty;        // 0-100
        bool isStabled;       // Boolean flag
        uint40 restingUntil;  // Unix timestamp
    }
}
```

## Error Handling and Recovery

### Emergency System
```solidity
contract EmergencyHandler {
    // Emergency unbond all pets
    function emergencyUnbondAll() external onlyOwner {
        uint256 totalPets = _tokenIds.current();
        for (uint256 i = 1; i <= totalPets; i++) {
            if (petBondedTo[i] != 0) {
                uint256 characterId = petBondedTo[i];
                petBondedTo[i] = 0;
                characterBondedPet[characterId] = 0;
                emit PetUnbonded(i, characterId);
            }
        }
    }
    
    // Emergency dismount all mounts
    function emergencyDismountAll() external onlyOwner {
        uint256 totalMounts = _tokenIds.current();
        for (uint256 i = 1; i <= totalMounts; i++) {
            if (mountRider[i] != 0) {
                uint256 characterId = mountRider[i];
                mountRider[i] = 0;
                characterActiveMount[characterId] = 0;
                emit MountDismounted(i, characterId);
            }
        }
    }
}
```

## Analytics and Monitoring

### System Analytics
```solidity
contract PetMountAnalytics {
    struct SystemStats {
        uint256 totalPets;
        uint256 activePets;
        uint256 totalMounts;
        uint256 activeMounts;
        uint256 averagePetLevel;
        uint256 averageMountTraining;
        mapping(uint256 => uint256) rarityDistribution;
        mapping(uint256 => uint256) mountTypeDistribution;
    }
    
    SystemStats public stats;
    
    function updateSystemStats() external {
        // Update pet statistics
        uint256 totalPets = pet._tokenIds.current();
        uint256 totalPetLevels = 0;
        stats.totalPets = totalPets;
        
        for (uint256 i = 1; i <= totalPets; i++) {
            if (pet.petBondedTo(i) != 0) {
                stats.activePets++;
            }
            PetAttributes memory petAttr = pet.petAttributes(i);
            totalPetLevels += petAttr.level;
            stats.rarityDistribution[uint256(petAttr.rarity)]++;
        }
        
        // Update mount statistics
        uint256 totalMounts = mount._tokenIds.current();
        uint256 totalTraining = 0;
        stats.totalMounts = totalMounts;
        
        for (uint256 i = 1; i <= totalMounts; i++) {
            if (mount.mountRider(i) != 0) {
                stats.activeMounts++;
            }
            MountAttributes memory mountAttr = mount.mountAttributes(i);
            totalTraining += mountAttr.training;
            stats.mountTypeDistribution[uint256(mountAttr.mountType)]++;
        }
        
        // Calculate averages
        if (totalPets > 0) {
            stats.averagePetLevel = totalPetLevels / totalPets;
        }
        if (totalMounts > 0) {
            stats.averageMountTraining = totalTraining / totalMounts;
        }
        
        emit StatsUpdated(stats);
    }
}
```

## Future Enhancements
1. Advanced Evolution System
   - Multiple evolution paths
   - Unique evolved abilities
   - Evolution quests

2. Mount Breeding System
   - Genetic traits
   - Breeding cooldowns
   - Offspring inheritance

3. Pet Combat System
   - Pet battles
   - Team formations
   - Battle rewards

4. Mount Racing System
   - Race tracks
   - Speed training
   - Racing leagues

5. Companion Marketplace
   - Specialized trading
   - Rental system
   - Auction house 