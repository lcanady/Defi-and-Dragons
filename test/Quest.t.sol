// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";
import "../src/interfaces/Types.sol";
import "../src/ProvableRandom.sol";
import "../src/Equipment.sol";

contract QuestTest is Test {
    Character public character;
    GameToken public gameToken;
    Quest public quest;
    address public user;
    uint256 public characterId;
    uint256 public questId;
    ProvableRandom public random;

    // Define quest objectives
    Quest.QuestObjective[] objectives;

    function setUp() public {
        // Initialize objectives array with a single objective
        objectives.push(Quest.QuestObjective({ targetValue: 10, currentValue: 0, objectiveType: keccak256("KILLS") }));

        user = address(0x1);
        vm.startPrank(address(this)); // Start as test contract (owner)

        // Deploy contracts in correct order
        random = new ProvableRandom();
        Equipment equipment = new Equipment(address(this));
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));

        gameToken = new GameToken();
        quest = new Quest(address(character), address(0)); // Mock party contract
        quest.initialize(address(gameToken));
        gameToken.setQuestContract(address(quest), true);
        gameToken.grantRole(gameToken.MINTER_ROLE(), address(quest));

        vm.stopPrank();
        vm.startPrank(user);

        // Reset random seed for user
        bytes32 context = bytes32(uint256(uint160(address(quest))));
        random.resetSeed(user, context);

        // Create a character
        characterId = character.mintCharacter(user, Types.Alignment.STRENGTH);

        // Create a basic quest
        vm.stopPrank();
        vm.startPrank(address(this)); // Switch back to owner for quest creation
        questId = quest.createQuest(
            1, // requiredLevel
            10, // requiredStrength
            10, // requiredAgility
            10, // requiredMagic
            100 * 10 ** 18, // rewardAmount
            uint32(1 hours), // cooldown
            false, // supportsParty
            0, // maxPartySize
            0, // partyBonusPercent
            false, // isRaid
            0, // maxParties
            Quest.QuestType.COMBAT, // questType
            objectives // objectives array
        );
        vm.stopPrank();
        vm.startPrank(user); // Back to user context
    }

    function testFailUseBeforeInitialize() public {
        Quest newQuest = new Quest(address(character), address(0)); // Mock party contract

        // Create a quest (this should work)
        uint256 newQuestId = newQuest.createQuest(
            1, // requiredLevel
            10, // requiredStrength
            10, // requiredAgility
            10, // requiredMagic
            100 * 10 ** 18, // rewardAmount
            uint32(1 hours), // cooldown
            false, // supportsParty
            0, // maxPartySize
            0, // partyBonusPercent
            false, // isRaid
            0, // maxParties
            Quest.QuestType.COMBAT, // questType
            objectives // objectives array
        );

        // Try to complete the quest (this should fail because gameToken is not initialized)
        newQuest.completeQuest(characterId, newQuestId);
    }

    function testStartQuest() public {
        quest.startQuest(characterId, questId, bytes32(0));
        assertTrue(quest.activeQuests(questId));
    }

    function testFailStartQuestInsufficientStats() public {
        // Create a quest with high requirements
        uint256 hardQuestId = quest.createQuest(
            1, // requiredLevel
            50, // requiredStrength
            50, // requiredAgility
            50, // requiredMagic
            100 * 10 ** 18, // rewardAmount
            uint32(1 hours), // cooldown
            false, // supportsParty
            0, // maxPartySize
            0, // partyBonusPercent
            false, // isRaid
            0, // maxParties
            Quest.QuestType.COMBAT, // questType
            objectives // objectives array
        );

        quest.startQuest(characterId, hardQuestId, bytes32(0));
    }

    function testCompleteQuest() public {
        quest.startQuest(characterId, questId, bytes32(0));
        quest.completeQuest(characterId, questId);

        assertFalse(quest.activeQuests(questId));
        assertEq(gameToken.balanceOf(user), 100 * 10 ** 18);
    }

    function testFailCompleteQuestNotStarted() public {
        quest.completeQuest(characterId, questId);
    }

    function testFailStartQuestOnCooldown() public {
        quest.startQuest(characterId, questId, bytes32(0));
        quest.completeQuest(characterId, questId);
        quest.startQuest(characterId, questId, bytes32(0)); // Should fail due to cooldown
    }
}
