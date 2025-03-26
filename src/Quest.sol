// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./Party.sol";

contract Quest is AccessControl {
    bytes32 public constant QUEST_MANAGER_ROLE = keccak256("QUEST_MANAGER_ROLE");
    
    ICharacter public immutable character;
    IGameToken public gameToken;
    Party public immutable partyContract;

    struct QuestTemplate {
        uint8 requiredLevel;
        uint8 requiredStrength;
        uint8 requiredAgility;
        uint8 requiredMagic;
        uint256 rewardAmount;
        uint256 cooldown;
        bool supportsParty;        // Whether quest can be done by parties
        uint256 maxPartySize;     // Maximum party size (0 for solo only)
        uint256 partyBonusPercent; // Bonus reward % for full party (e.g. 50 = 50% bonus)
        bool isRaid;              // Whether this is a raid quest that supports multiple parties
        uint256 maxParties;       // Maximum number of parties for raid (0 for non-raid)
    }

    struct ActiveQuest {
        bool isActive;
        bytes32[] activeParties;  // Array of party IDs participating
        mapping(address => bool) participatingWallets; // Track participating wallets
    }

    mapping(uint256 => QuestTemplate) public questTemplates;
    mapping(uint256 => mapping(uint256 => uint256)) public lastQuestCompletionTime;
    mapping(uint256 => ActiveQuest) public activeQuests;

    event QuestStarted(uint256 indexed questId, bytes32[] parties);
    event PartyJoinedQuest(uint256 indexed questId, bytes32 indexed partyId);
    event QuestCompleted(uint256 indexed questId, bytes32[] parties, uint256 reward);
    event RaidReward(address indexed wallet, uint256 indexed questId, uint256 reward);

    constructor(address characterContract, address partyContract_) {
        character = ICharacter(characterContract);
        partyContract = Party(partyContract_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialize(address _gameToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(gameToken) == address(0), "Already initialized");
        gameToken = IGameToken(_gameToken);
    }

    modifier onlyCharacterOwnerOrManager(uint256 characterId) {
        require(
            character.ownerOf(characterId) == msg.sender || hasRole(QUEST_MANAGER_ROLE, msg.sender),
            "Not character owner or quest manager"
        );
        _;
    }

    function createQuest(
        uint8 requiredLevel,
        uint8 requiredStrength,
        uint8 requiredAgility,
        uint8 requiredMagic,
        uint256 rewardAmount,
        uint256 cooldown,
        bool supportsParty,
        uint256 maxPartySize,
        uint256 partyBonusPercent,
        bool isRaid,
        uint256 maxParties
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 questId) {
        require(maxPartySize <= 10, "Party size too large");
        require(partyBonusPercent <= 100, "Bonus too high");
        if (isRaid) {
            require(maxParties > 1 && maxParties <= 10, "Invalid raid size");
            require(supportsParty, "Raids must support parties");
        }
        
        questId = uint256(
            keccak256(
                abi.encodePacked(
                    requiredLevel,
                    requiredStrength,
                    requiredAgility,
                    requiredMagic,
                    rewardAmount,
                    cooldown,
                    supportsParty,
                    maxPartySize,
                    partyBonusPercent,
                    isRaid,
                    maxParties,
                    block.timestamp
                )
            )
        );

        questTemplates[questId] = QuestTemplate({
            requiredLevel: requiredLevel,
            requiredStrength: requiredStrength,
            requiredAgility: requiredAgility,
            requiredMagic: requiredMagic,
            rewardAmount: rewardAmount,
            cooldown: cooldown,
            supportsParty: supportsParty,
            maxPartySize: maxPartySize,
            partyBonusPercent: partyBonusPercent,
            isRaid: isRaid,
            maxParties: maxParties
        });
    }

    function startQuest(uint256 characterId, uint256 questId, bytes32 partyId) external onlyCharacterOwnerOrManager(characterId) {
        QuestTemplate storage quest = questTemplates[questId];
        require(quest.requiredLevel > 0, "Quest does not exist");
        
        ActiveQuest storage activeQuest = activeQuests[questId];
        if (quest.isRaid) {
            require(partyId != bytes32(0), "Raids require party");
            require(activeQuest.activeParties.length < quest.maxParties, "Raid full");
        } else {
            require(!activeQuest.isActive, "Quest already active");
        }

        // Handle party validation if party ID provided
        if (partyId != bytes32(0)) {
            require(quest.supportsParty, "Quest doesn't support parties");
            
            // Verify party exists and caller owns it
            (string memory name, uint256[] memory memberIds, address owner, bool active, uint256 maxSize) = partyContract.getPartyInfo(partyId);
            require(active, "Party not active");
            require(owner == msg.sender, "Not party owner");
            require(memberIds.length <= quest.maxPartySize, "Party too large");
            require(!activeQuest.participatingWallets[msg.sender], "Wallet already participating");
            
            // Verify all party members meet requirements
            for (uint256 i = 0; i < memberIds.length; i++) {
                uint256 memberId = memberIds[i];
                require(character.ownerOf(memberId) == msg.sender, "Not all characters owned");
                
                // Check cooldowns
                uint256 lastCompletion = lastQuestCompletionTime[memberId][questId];
                if (lastCompletion > 0) {
                    require(block.timestamp >= lastCompletion + quest.cooldown, "Character on cooldown");
                }
                
                // Check stats
                (Types.Stats memory stats,,) = character.getCharacter(memberId);
                require(stats.strength >= quest.requiredStrength, "Insufficient strength");
                require(stats.agility >= quest.requiredAgility, "Insufficient agility");
                require(stats.magic >= quest.requiredMagic, "Insufficient magic");
            }
            
            activeQuest.activeParties.push(partyId);
            activeQuest.participatingWallets[msg.sender] = true;
            emit PartyJoinedQuest(questId, partyId);
        } else {
            // Solo quest checks
            uint256 lastCompletion = lastQuestCompletionTime[characterId][questId];
            if (lastCompletion > 0) {
                require(block.timestamp >= lastCompletion + quest.cooldown, "Quest on cooldown");
            }

            (Types.Stats memory stats,,) = character.getCharacter(characterId);
            require(stats.strength >= quest.requiredStrength, "Insufficient strength");
            require(stats.agility >= quest.requiredAgility, "Insufficient agility");
            require(stats.magic >= quest.requiredMagic, "Insufficient magic");
        }

        activeQuest.isActive = true;
        
        if (!quest.isRaid || activeQuest.activeParties.length == quest.maxParties) {
            emit QuestStarted(questId, activeQuest.activeParties);
        }
    }

    function completeQuest(uint256 characterId, uint256 questId) external onlyCharacterOwnerOrManager(characterId) {
        ActiveQuest storage activeQuest = activeQuests[questId];
        require(activeQuest.isActive, "Quest not active");
        QuestTemplate storage quest = questTemplates[questId];

        if (quest.isRaid) {
            require(activeQuest.activeParties.length > 0, "No parties in raid");
            // For raids, any participating party member can complete it
            bool isParticipant = false;
            for (uint256 i = 0; i < activeQuest.activeParties.length; i++) {
                (,uint256[] memory memberIds, address owner,,) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
                for (uint256 j = 0; j < memberIds.length; j++) {
                    if (memberIds[j] == characterId) {
                        isParticipant = true;
                        break;
                    }
                }
                if (isParticipant) break;
            }
            require(isParticipant, "Not raid participant");

            // Calculate and distribute rewards for each participating wallet
            uint256 baseReward = quest.rewardAmount;
            uint256 raidBonus = (baseReward * quest.partyBonusPercent * activeQuest.activeParties.length) / 100;
            uint256 totalReward = baseReward + raidBonus;

            // Each wallet gets full reward + bonus
            for (uint256 i = 0; i < activeQuest.activeParties.length; i++) {
                (,, address owner,,) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
                gameToken.mint(owner, totalReward);
                emit RaidReward(owner, questId, totalReward);
            }
        } else {
            if (activeQuest.activeParties.length > 0) {
                // Party quest
                bytes32 partyId = activeQuest.activeParties[0];
                (,uint256[] memory memberIds, address owner, bool active,) = partyContract.getPartyInfo(partyId);
                require(active && owner == msg.sender, "Not party owner");

                // Calculate reward with party bonus
                uint256 baseReward = quest.rewardAmount;
                uint256 partyBonus = memberIds.length == quest.maxPartySize ? 
                    (baseReward * quest.partyBonusPercent) / 100 : 0;
                
                // Full reward goes to wallet since all characters belong to same owner
                gameToken.mint(msg.sender, baseReward + partyBonus);
            } else {
                // Solo quest completion
                lastQuestCompletionTime[characterId][questId] = block.timestamp;
                gameToken.mint(msg.sender, quest.rewardAmount);
            }
        }

        // Update completion times for all participating characters
        for (uint256 i = 0; i < activeQuest.activeParties.length; i++) {
            (,uint256[] memory memberIds,,, ) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
            for (uint256 j = 0; j < memberIds.length; j++) {
                lastQuestCompletionTime[memberIds[j]][questId] = block.timestamp;
            }
        }

        // Clean up quest state
        emit QuestCompleted(questId, activeQuest.activeParties, quest.rewardAmount);
        delete activeQuests[questId];
    }

    function getActiveParties(uint256 questId) external view returns (bytes32[] memory) {
        return activeQuests[questId].activeParties;
    }

    function isWalletParticipating(uint256 questId, address wallet) external view returns (bool) {
        return activeQuests[questId].participatingWallets[wallet];
    }
}
