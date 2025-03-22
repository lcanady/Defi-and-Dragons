# The Fellowship Guide 🤝

Welcome to the social realm of DeFi & Dragons! Here you'll learn how to forge alliances, join guilds, and tackle epic team challenges.

## 🏰 Guilds

### Team Formation
```solidity
// Form a team for a quest
const teamId = await socialQuest.formTeam(
    questId,
    [characterId1, characterId2, characterId3],
    {
        minTeamSize: 3,
        maxTeamSize: 5
    }
);

// Record team contribution
await socialQuest.recordContribution(
    questId,
    characterId,
    contributionValue
);
```

### Team Features
- Collaborative quest completion
- Shared quest rewards
- Top contributor bonuses
- Enhanced drop rates for team activities
- Team progress tracking

### Creating a Guild
```solidity
// Found a new guild
const guildId = await socialSystem.createGuild(
    name,
    description,
    {
        minLevel: 10,
        entryFee: ethers.parseEther("100"),
        maxMembers: 50
    }
);

// Set guild roles
await socialSystem.setGuildRoles(
    guildId,
    [
        "Guildmaster",
        "Officer",
        "Veteran",
        "Member",
        "Initiate"
    ]
);
```

### Guild Features
- Shared quest rewards
- Guild bank system
- Internal marketplace
- Guild achievements
- Special guild quests

## ⚔️ Team Quests

### Forming a Party
```solidity
// Create a party for team quest
const teamId = await socialQuest.formTeam(
    questId,
    [characterId1, characterId2, characterId3],
    {
        requiredRoles: ["Tank", "DPS", "Support"],
        minLevel: 5
    }
);

// Coordinate team actions
await socialQuest.synchronizeActions(
    teamId,
    actionType,
    timestamp
);
```

### Team Synergies
```solidity
// Calculate team composition bonus
const bonus = await socialQuest.calculateTeamBonus(
    teamId,
    {
        checkAttributes: true,
        checkEquipment: true,
        checkPets: true
    }
);

// Apply team buffs
await socialQuest.applyTeamBuffs(
    teamId,
    buffType,
    duration
);
```

## 🤝 Social Features

### Referral System
```solidity
// Refer a new player
const referralId = await socialQuest.createReferral(
    newPlayerAddress,
    {
        bonusType: "STARTER_PACK",
        duration: 30 * 24 * 3600 // 30 days
    }
);

// Claim referral rewards
await socialQuest.claimReferralReward(
    referralId,
    characterId
);
```

### Trading System
```solidity
// Create a trade offer
const tradeId = await socialSystem.createTrade(
    {
        offeredItems: [itemId1, itemId2],
        requestedItems: [itemId3],
        duration: 3600 // 1 hour
    }
);

// Accept trade
await socialSystem.acceptTrade(tradeId);
```

## 🎯 Cooperative Missions

### Raid Bosses
```solidity
// Initiate raid
const raidId = await combatQuest.startRaid(
    bossId,
    {
        minParticipants: 5,
        maxParticipants: 10,
        preparationTime: 300 // 5 minutes
    }
);

// Join raid
await combatQuest.joinRaid(
    raidId,
    characterId,
    preferredRole
);
```

### Territory Control
```solidity
// Claim territory
const territoryId = await socialSystem.claimTerritory(
    guildId,
    location,
    {
        defenderCount: 3,
        stakeAmount: ethers.parseEther("1000")
    }
);

// Defend territory
await socialSystem.assignDefenders(
    territoryId,
    [characterId1, characterId2, characterId3]
);
```

## 📊 Social Rankings

### Leaderboards
```solidity
// Get guild rankings
const guildRankings = await analytics.getGuildRankings(
    {
        sortBy: "QUEST_COMPLETION",
        timeframe: "SEASON",
        limit: 10
    }
);

// Get player rankings
const playerRankings = await analytics.getPlayerRankings(
    {
        category: "PVP_WINS",
        season: currentSeason
    }
);
```

### Achievements
```solidity
// Track guild achievements
const guildProgress = await achievementQuest.getGuildProgress(
    guildId,
    achievementId
);

// Claim guild rewards
await achievementQuest.claimGuildReward(
    guildId,
    achievementId
);
```

## 🎮 Social Events

### Guild Wars
```solidity
// Declare guild war
const warId = await socialSystem.declareWar(
    attackingGuildId,
    defendingGuildId,
    {
        duration: 7 * 24 * 3600, // 1 week
        stakingRequired: true,
        warChest: ethers.parseEther("10000")
    }
);

// Record war contribution
await socialSystem.recordWarContribution(
    warId,
    characterId,
    contributionType,
    amount
);
```

### Seasonal Events
```solidity
// Join seasonal event
const eventId = await socialQuest.joinSeasonalEvent(
    characterId,
    eventType,
    {
        team: teamId,
        contribution: ethers.parseEther("100")
    }
);

// Track event progress
const progress = await socialQuest.getEventProgress(
    eventId,
    characterId
);
```

## 🤖 Communication Tools

### Chat System
```solidity
// Send guild message
await socialSystem.sendGuildMessage(
    guildId,
    message,
    {
        channel: "STRATEGY",
        priority: "HIGH"
    }
);

// Create party chat
const chatId = await socialSystem.createPartyChat(
    teamId,
    {
        voice: true,
        persistent: false
    }
);
```

### Coordination Tools
```solidity
// Set raid markers
await socialSystem.setRaidMarkers(
    raidId,
    positions,
    {
        markerType: "STRATEGY",
        visibility: "RAID_MEMBERS"
    }
);

// Schedule guild event
await socialSystem.scheduleGuildEvent(
    guildId,
    eventType,
    timestamp,
    {
        reminder: true,
        requiredRoles: ["Officer", "Member"]
    }
);
```

Remember, brave adventurer: in unity lies strength! The greatest challenges and rewards await those who dare to band together! 🗡️✨ 