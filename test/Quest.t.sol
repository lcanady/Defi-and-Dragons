// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";
import "../src/interfaces/Types.sol";
import "../src/ProvableRandom.sol";

contract QuestTest is Test {
    Character public character;
    GameToken public gameToken;
    Quest public quest;
    address public user;
    uint256 public characterId;
    uint256 public questId;
    ProvableRandom public random;

    function setUp() public {
        user = address(0x1);
        vm.startPrank(address(this)); // Start as test contract (owner)

        // Deploy contracts
        random = new ProvableRandom();
        character = new Character(address(0), address(random)); // Mock equipment address
        gameToken = new GameToken();
        quest = new Quest(address(character));
        quest.initialize(address(gameToken));
        gameToken.setQuestContract(address(quest), true);
        gameToken.grantRole(gameToken.MINTER_ROLE(), address(quest));

        vm.stopPrank();
        vm.startPrank(user);

        // Setup initial state
        Types.Stats memory stats = Types.Stats({ strength: 40, agility: 30, magic: 30 });

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
            1 hours // cooldown
        );
        vm.stopPrank();
        vm.startPrank(user); // Back to user context
    }

    function testFailUseBeforeInitialize() public {
        Quest newQuest = new Quest(address(character));

        // Create a quest (this should work)
        uint256 newQuestId = newQuest.createQuest(
            1, // requiredLevel
            10, // requiredStrength
            10, // requiredAgility
            10, // requiredMagic
            100 * 10 ** 18, // rewardAmount
            1 hours // cooldown
        );

        // Try to complete the quest (this should fail because gameToken is not initialized)
        newQuest.completeQuest(characterId, newQuestId);
    }

    function testStartQuest() public {
        quest.startQuest(characterId, questId);
        assertTrue(quest.activeQuests(questId));
    }

    function testFailStartQuestInsufficientStats() public {
        // Create a quest with high requirements
        uint256 hardQuestId = quest.createQuest(
            1, // requiredLevel
            50, // requiredStrength (higher than character's)
            50, // requiredAgility
            50, // requiredMagic
            100 * 10 ** 18, // rewardAmount
            1 hours // cooldown
        );

        quest.startQuest(characterId, hardQuestId);
    }

    function testCompleteQuest() public {
        quest.startQuest(characterId, questId);
        quest.completeQuest(characterId, questId);

        assertFalse(quest.activeQuests(questId));
        assertEq(gameToken.balanceOf(user), 100 * 10 ** 18);
    }

    function testFailCompleteQuestNotStarted() public {
        quest.completeQuest(characterId, questId);
    }

    function testFailStartQuestOnCooldown() public {
        quest.startQuest(characterId, questId);
        quest.completeQuest(characterId, questId);
        quest.startQuest(characterId, questId); // Should fail due to cooldown
    }
}
