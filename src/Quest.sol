// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Errors.sol";
import "./Party.sol";

/// @title Quest
/// @notice Core quest management contract that handles quest creation, progress, and completion
/// @dev Optimized for gas efficiency with custom errors and storage packing
contract Quest is AccessControl {
    bytes32 public constant QUEST_MANAGER_ROLE = keccak256("QUEST_MANAGER_ROLE");
    bytes32 public constant QUEST_VALIDATOR_ROLE = keccak256("QUEST_VALIDATOR_ROLE");

    ICharacter public immutable character;
    IGameToken public gameToken;
    Party public immutable partyContract;

    enum QuestType {
        COMBAT, // Requires combat victories/stats
        SOCIAL, // Requires social interactions
        ACHIEVEMENT, // Requires reaching milestones
        PROTOCOL, // Requires DeFi interactions
        TIME // Requires time-based completion

    }

    struct QuestObjective {
        uint128 targetValue; // The value that needs to be reached
        uint128 currentValue; // Current progress
        bytes32 objectiveType; // What needs to be tracked (kills, trades, etc)
    }

    struct QuestTemplate {
        uint8 requiredLevel;
        uint8 requiredStrength;
        uint8 requiredAgility;
        uint8 requiredMagic;
        uint128 rewardAmount;
        uint32 cooldown;
        bool supportsParty;
        uint8 maxPartySize;
        uint8 partyBonusPercent;
        bool isRaid;
        uint8 maxParties;
        QuestType questType;
        QuestObjective[] objectives;
    }

    struct ActiveQuest {
        bool isActive;
        bytes32[] activeParties;
        mapping(address => bool) participatingWallets;
        mapping(bytes32 => mapping(bytes32 => uint128)) partyProgress; // partyId => objectiveType => progress
        mapping(bytes32 => uint256) partyMemberMask; // partyId => bitmask of participating members (max 256 members)
    }

    // Quest objective types
    bytes32 public constant KILLS = keccak256("KILLS");
    bytes32 public constant DAMAGE_DEALT = keccak256("DAMAGE_DEALT");
    bytes32 public constant TRADES_MADE = keccak256("TRADES_MADE");
    bytes32 public constant ITEMS_COLLECTED = keccak256("ITEMS_COLLECTED");
    bytes32 public constant LIQUIDITY_PROVIDED = keccak256("LIQUIDITY_PROVIDED");
    bytes32 public constant TIME_SPENT = keccak256("TIME_SPENT");
    bytes32 public constant COMBAT_COMPLETED = keccak256("COMBAT_COMPLETED");

    mapping(uint256 => QuestTemplate) public questTemplates;
    mapping(uint256 => mapping(uint256 => uint64)) public lastQuestCompletionTime;
    mapping(uint256 => ActiveQuest) public activeQuests;

    event QuestProgressUpdated(
        uint256 indexed questId, bytes32 indexed partyId, bytes32 objectiveType, uint128 progress
    );

    event QuestStarted(uint256 indexed questId, bytes32[] parties);
    event PartyJoinedQuest(uint256 indexed questId, bytes32 indexed partyId);
    event QuestCompleted(uint256 indexed questId, bytes32[] parties, uint128 reward);
    event RaidReward(address indexed wallet, uint256 indexed questId, uint128 reward);

    constructor(address characterContract, address partyContract_) {
        character = ICharacter(characterContract);
        partyContract = Party(partyContract_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Initialize the contract with game token
    /// @param _gameToken Address of the game token contract
    function initialize(address _gameToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(gameToken) != address(0)) revert AlreadyInitialized();
        gameToken = IGameToken(_gameToken);
    }

    modifier onlyCharacterOwnerOrManager(uint256 characterId) {
        if (character.ownerOf(characterId) != msg.sender && !hasRole(QUEST_MANAGER_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Create a new quest template
    /// @param requiredLevel Minimum level required
    /// @param requiredStrength Minimum strength required
    /// @param requiredAgility Minimum agility required
    /// @param requiredMagic Minimum magic required
    /// @param rewardAmount Base reward amount
    /// @param cooldown Time between quest attempts
    /// @param supportsParty Whether quest can be done in party
    /// @param maxPartySize Maximum party size
    /// @param partyBonusPercent Bonus reward percentage for full party
    /// @param isRaid Whether quest is a raid
    /// @param maxParties Maximum number of parties for raid
    /// @param questType Type of quest
    /// @param objectives Array of quest objectives
    /// @return questId The unique identifier for the quest
    function createQuest(
        uint8 requiredLevel,
        uint8 requiredStrength,
        uint8 requiredAgility,
        uint8 requiredMagic,
        uint128 rewardAmount,
        uint32 cooldown,
        bool supportsParty,
        uint8 maxPartySize,
        uint8 partyBonusPercent,
        bool isRaid,
        uint8 maxParties,
        QuestType questType,
        QuestObjective[] calldata objectives
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        if (objectives.length == 0) revert NoObjectives();
        if (maxPartySize > 10) revert PartyTooLarge();
        if (partyBonusPercent > 100) revert BonusTooHigh();
        if (isRaid) {
            if (maxParties <= 1 || maxParties > 10) revert InvalidRaidSize();
            if (!supportsParty) revert RaidsMustSupportParties();
        }

        uint256 questId = uint256(
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
                    questType,
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
            maxParties: maxParties,
            questType: questType,
            objectives: objectives
        });

        return questId;
    }

    /// @notice Start a quest for a character or party
    /// @param characterId Character ID starting the quest
    /// @param questId Quest template ID
    /// @param partyId Optional party ID if starting as party
    function startQuest(uint256 characterId, uint256 questId, bytes32 partyId)
        external
        onlyCharacterOwnerOrManager(characterId)
    {
        QuestTemplate storage quest = questTemplates[questId];
        if (quest.requiredLevel == 0) revert QuestNotExists();

        ActiveQuest storage activeQuest = activeQuests[questId];
        if (quest.isRaid) {
            if (partyId == bytes32(0)) revert RaidRequiresParty();
            if (activeQuest.activeParties.length >= quest.maxParties) revert RaidFull();
        } else {
            if (activeQuest.isActive) revert QuestAlreadyActive();
        }

        // Handle party validation if party ID provided
        if (partyId != bytes32(0)) {
            if (!quest.supportsParty) revert QuestDoesNotSupportParty();

            // Verify party exists and caller owns it
            (, uint256[] memory memberIds, address owner, bool active,) = partyContract.getPartyInfo(partyId);
            if (!active) revert PartyNotActive();
            if (owner != msg.sender) revert NotPartyOwner();
            if (memberIds.length > quest.maxPartySize) revert PartyTooLarge();
            if (activeQuest.participatingWallets[msg.sender]) revert WalletAlreadyParticipating();

            // Verify all party members meet requirements and build participation mask
            uint256 participationMask;
            uint256 len = memberIds.length;
            unchecked {
                for (uint256 i; i < len; ++i) {
                    uint256 memberId = memberIds[i];
                    if (character.ownerOf(memberId) != msg.sender) revert NotAllCharactersOwned();

                    // Check cooldowns
                    uint256 lastCompletion = lastQuestCompletionTime[memberId][questId];
                    if (lastCompletion > 0 && block.timestamp < lastCompletion + quest.cooldown) {
                        revert CharacterOnCooldown();
                    }

                    // Check stats
                    (Types.Stats memory stats,,) = character.getCharacter(memberId);
                    if (stats.strength < quest.requiredStrength) revert InsufficientStrength();
                    if (stats.agility < quest.requiredAgility) revert InsufficientAgility();
                    if (stats.magic < quest.requiredMagic) revert InsufficientMagic();

                    // Add to participation mask
                    participationMask |= 1 << (memberId % 256);
                }
            }

            activeQuest.partyMemberMask[partyId] = participationMask;
            activeQuest.activeParties.push(partyId);
            activeQuest.participatingWallets[msg.sender] = true;
            emit PartyJoinedQuest(questId, partyId);
        } else {
            // Solo quest checks
            uint256 lastCompletion = lastQuestCompletionTime[characterId][questId];
            if (lastCompletion > 0 && block.timestamp < lastCompletion + quest.cooldown) {
                revert CharacterOnCooldown();
            }

            (Types.Stats memory stats,,) = character.getCharacter(characterId);
            if (stats.strength < quest.requiredStrength) revert InsufficientStrength();
            if (stats.agility < quest.requiredAgility) revert InsufficientAgility();
            if (stats.magic < quest.requiredMagic) revert InsufficientMagic();

            // Use bitmask for solo character
            bytes32 soloPartyId = bytes32(uint256(uint160(msg.sender)));
            activeQuest.partyMemberMask[soloPartyId] = 1 << (characterId % 256);
        }

        activeQuest.isActive = true;

        if (!quest.isRaid || activeQuest.activeParties.length == quest.maxParties) {
            emit QuestStarted(questId, activeQuest.activeParties);
        }
    }

    /// @notice Complete a quest
    /// @param characterId Character ID completing the quest
    /// @param questId Quest template ID
    function completeQuest(uint256 characterId, uint256 questId) external onlyCharacterOwnerOrManager(characterId) {
        ActiveQuest storage activeQuest = activeQuests[questId];
        if (!activeQuest.isActive) revert QuestNotActive();
        QuestTemplate storage quest = questTemplates[questId];

        if (quest.isRaid) {
            if (activeQuest.activeParties.length == 0) revert NoPartiesInRaid();

            // For raids, any participating party member can complete it
            bool isParticipant;
            uint256 partyLen = activeQuest.activeParties.length;
            unchecked {
                for (uint256 i; i < partyLen; ++i) {
                    (, uint256[] memory memberIds,,,) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
                    uint256 memberLen = memberIds.length;
                    for (uint256 j; j < memberLen; ++j) {
                        if (memberIds[j] == characterId) {
                            isParticipant = true;
                            break;
                        }
                    }
                    if (isParticipant) break;
                }
            }
            if (!isParticipant) revert NotRaidParticipant();

            // Calculate and distribute rewards for each participating wallet
            uint128 baseReward = quest.rewardAmount;
            uint128 raidBonus;
            unchecked {
                raidBonus =
                    uint128((uint256(baseReward) * quest.partyBonusPercent * activeQuest.activeParties.length) / 100);
            }
            uint128 totalReward = baseReward + raidBonus;

            // Each wallet gets full reward + bonus
            for (uint256 i; i < partyLen;) {
                (,, address owner,,) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
                gameToken.mint(owner, totalReward);
                emit RaidReward(owner, questId, totalReward);
                unchecked {
                    ++i;
                }
            }
        } else {
            if (activeQuest.activeParties.length > 0) {
                // Party quest
                bytes32 partyId = activeQuest.activeParties[0];
                (, uint256[] memory memberIds, address owner, bool active,) = partyContract.getPartyInfo(partyId);
                if (!active || owner != msg.sender) revert NotPartyOwner();

                // Calculate reward with party bonus
                uint128 baseReward = quest.rewardAmount;
                uint128 partyBonus;
                if (memberIds.length == quest.maxPartySize) {
                    unchecked {
                        partyBonus = uint128((uint256(baseReward) * quest.partyBonusPercent) / 100);
                    }
                }

                // Full reward goes to wallet since all characters belong to same owner
                gameToken.mint(msg.sender, baseReward + partyBonus);
            } else {
                // Solo quest completion
                lastQuestCompletionTime[characterId][questId] = uint64(block.timestamp);
                gameToken.mint(msg.sender, quest.rewardAmount);
            }
        }

        // Update completion times for all participating characters
        uint256 totalParties = activeQuest.activeParties.length;
        unchecked {
            for (uint256 i; i < totalParties; ++i) {
                (, uint256[] memory memberIds,,,) = partyContract.getPartyInfo(activeQuest.activeParties[i]);
                uint256 memberLen = memberIds.length;
                for (uint256 j; j < memberLen; ++j) {
                    lastQuestCompletionTime[memberIds[j]][questId] = uint64(block.timestamp);
                }
            }
        }

        // Clean up quest state
        emit QuestCompleted(questId, activeQuest.activeParties, quest.rewardAmount);
        delete activeQuests[questId];
    }

    /// @notice Get active parties for a quest
    /// @param questId Quest template ID
    /// @return Array of active party IDs
    function getActiveParties(uint256 questId) external view returns (bytes32[] memory) {
        return activeQuests[questId].activeParties;
    }

    /// @notice Check if a wallet is participating in a quest
    /// @param questId Quest template ID
    /// @param wallet Wallet address to check
    /// @return Whether the wallet is participating
    function isWalletParticipating(uint256 questId, address wallet) external view returns (bool) {
        return activeQuests[questId].participatingWallets[wallet];
    }

    /// @notice Update progress for a quest objective
    /// @param questId Quest template ID
    /// @param partyId Party ID to update progress for
    /// @param objectiveType Type of objective being updated
    /// @param progress Amount of progress to add
    function updateQuestProgress(uint256 questId, bytes32 partyId, bytes32 objectiveType, uint128 progress)
        external
        onlyRole(QUEST_VALIDATOR_ROLE)
    {
        ActiveQuest storage activeQuest = activeQuests[questId];
        if (!activeQuest.isActive) revert QuestNotActive();

        // Update progress
        unchecked {
            activeQuest.partyProgress[partyId][objectiveType] += progress;
        }

        emit QuestProgressUpdated(questId, partyId, objectiveType, activeQuest.partyProgress[partyId][objectiveType]);

        // Check if quest is completed
        if (_checkQuestCompletion(questId, partyId)) {
            // Auto-complete if all objectives are met
            _completeQuest(questId, partyId);
        }
    }

    /// @notice Check if a quest's objectives are completed
    /// @param questId Quest template ID
    /// @param partyId Party ID to check
    /// @return Whether all objectives are completed
    function _checkQuestCompletion(uint256 questId, bytes32 partyId) internal view returns (bool) {
        QuestTemplate storage template = questTemplates[questId];
        ActiveQuest storage activeQuest = activeQuests[questId];

        uint256 len = template.objectives.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                QuestObjective memory objective = template.objectives[i];
                if (activeQuest.partyProgress[partyId][objective.objectiveType] < objective.targetValue) {
                    return false;
                }
            }
        }
        return true;
    }

    /// @notice Get progress details for a quest
    /// @param questId Quest template ID
    /// @param partyId Party ID to get progress for
    /// @return objectiveTypes Array of objective types
    /// @return currentValues Array of current progress values
    /// @return targetValues Array of target values
    function getQuestProgress(uint256 questId, bytes32 partyId)
        external
        view
        returns (bytes32[] memory objectiveTypes, uint128[] memory currentValues, uint128[] memory targetValues)
    {
        QuestTemplate storage template = questTemplates[questId];
        ActiveQuest storage activeQuest = activeQuests[questId];

        uint256 len = template.objectives.length;
        objectiveTypes = new bytes32[](len);
        currentValues = new uint128[](len);
        targetValues = new uint128[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                objectiveTypes[i] = template.objectives[i].objectiveType;
                currentValues[i] = activeQuest.partyProgress[partyId][template.objectives[i].objectiveType];
                targetValues[i] = template.objectives[i].targetValue;
            }
        }
    }

    /// @notice Internal function to complete a quest
    /// @param questId Quest template ID
    /// @param partyId Party ID completing the quest
    function _completeQuest(uint256 questId, bytes32 partyId) internal {
        // Get quest and party info
        QuestTemplate storage quest = questTemplates[questId];
        (, uint256[] memory memberIds, address owner,,) = partyContract.getPartyInfo(partyId);

        // Calculate and distribute rewards
        uint128 baseReward = quest.rewardAmount;
        uint128 bonus;
        if (memberIds.length == quest.maxPartySize) {
            unchecked {
                bonus = uint128((uint256(baseReward) * quest.partyBonusPercent) / 100);
            }
        }

        // Mint rewards
        uint128 totalReward = baseReward + bonus;
        gameToken.mint(owner, totalReward);

        // Update completion times
        uint64 completionTime = uint64(block.timestamp);
        uint256 len = memberIds.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                lastQuestCompletionTime[memberIds[i]][questId] = completionTime;
            }
        }

        // Clean up quest state for this party
        bytes32[] memory parties = new bytes32[](1);
        parties[0] = partyId;
        emit QuestCompleted(questId, parties, totalReward);

        // Only delete entire quest if not a raid or if last party
        ActiveQuest storage activeQuest = activeQuests[questId];
        if (!quest.isRaid || activeQuest.activeParties.length == 1) {
            delete activeQuests[questId];
        }
    }

    /// @notice Check if a character is participating in a quest
    /// @param questId Quest template ID
    /// @param partyId Party ID to check
    /// @param characterId Character ID to check
    /// @return Whether the character is participating
    function isCharacterParticipating(uint256 questId, bytes32 partyId, uint256 characterId)
        external
        view
        returns (bool)
    {
        return (activeQuests[questId].partyMemberMask[partyId] & (1 << (characterId % 256))) != 0;
    }

    /// @notice Get all participating characters for a party in a quest
    /// @param questId Quest template ID
    /// @param partyId Party ID to check
    /// @return Array of participating character IDs
    function getPartyParticipatingCharacters(uint256 questId, bytes32 partyId)
        external
        view
        returns (uint256[] memory)
    {
        (, uint256[] memory memberIds,,,) = partyContract.getPartyInfo(partyId);
        uint256[] memory participatingIds = new uint256[](memberIds.length);
        uint256 count;
        uint256 mask = activeQuests[questId].partyMemberMask[partyId];

        // Use bitmask to efficiently check participation
        uint256 len = memberIds.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (mask & (1 << (memberIds[i] % 256)) != 0) {
                    participatingIds[count++] = memberIds[i];
                }
            }
        }

        // Resize array to actual count
        assembly {
            mstore(participatingIds, count)
        }

        return participatingIds;
    }
}
