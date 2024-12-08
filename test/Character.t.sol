// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/interfaces/Types.sol";

contract CharacterTest is Test {
    Character public character;
    Equipment public equipment;
    address public owner;
    address public user;

    // Test character stats
    Types.Stats strengthChar = Types.Stats({ strength: 60, agility: 20, magic: 20 });

    Types.Stats agilityChar = Types.Stats({ strength: 20, agility: 60, magic: 20 });

    Types.Stats magicChar = Types.Stats({ strength: 20, agility: 20, magic: 60 });

    Types.Stats tankStrengthChar = Types.Stats({ strength: 50, agility: 25, magic: 25 });

    Types.Stats tankAgilityChar = Types.Stats({ strength: 25, agility: 50, magic: 25 });

    Types.Stats tankMagicChar = Types.Stats({ strength: 25, agility: 25, magic: 50 });

    function setUp() public {
        owner = address(this);
        user = address(0x1);

        // Deploy contracts
        character = new Character(address(0)); // Mock equipment address
        equipment = new Equipment();
    }

    function testMint() public {
        uint256 tokenId = character.mintCharacter(msg.sender, strengthChar, Types.Alignment.STRENGTH);
        assertEq(character.ownerOf(tokenId), msg.sender);

        (Types.Stats memory stats,, Types.CharacterState memory state) = character.getCharacter(tokenId);
        assertEq(stats.strength, strengthChar.strength);
        assertEq(stats.agility, strengthChar.agility);
        assertEq(stats.magic, strengthChar.magic);
        assertEq(uint256(state.alignment), uint256(Types.Alignment.STRENGTH));
    }

    function testEquip() public {
        // Deploy equipment with proper setup
        equipment = new Equipment();
        character = new Character(address(equipment));
        equipment.setCharacterContract(address(character));

        // Create equipment as owner
        vm.startPrank(owner);
        equipment.createEquipment(1, "Test Weapon", "A test weapon", 5, 0, 0);
        equipment.createEquipment(2, "Test Armor", "A test armor", 0, 5, 0);

        // Mint character to user
        uint256 tokenId = character.mintCharacter(user, strengthChar, Types.Alignment.STRENGTH);
        
        // Get character's wallet
        CharacterWallet wallet = character.characterWallets(tokenId);
        
        // Mint equipment to wallet
        equipment.mint(address(wallet), 1, 1, "");
        equipment.mint(address(wallet), 2, 1, "");
        vm.stopPrank();

        // Equip items as the user
        vm.startPrank(user);
        character.equip(tokenId, 1, 2);
        vm.stopPrank();

        // Verify equipment
        (, Types.EquipmentSlots memory equipped,) = character.getCharacter(tokenId);
        assertEq(equipped.weaponId, 1);
        assertEq(equipped.armorId, 2);
    }

    function testUpdateStats() public {
        uint256 tokenId = character.mintCharacter(msg.sender, agilityChar, Types.Alignment.AGILITY);

        character.updateStats(tokenId, strengthChar);

        (Types.Stats memory stats,,) = character.getCharacter(tokenId);
        assertEq(stats.strength, strengthChar.strength);
        assertEq(stats.agility, strengthChar.agility);
        assertEq(stats.magic, strengthChar.magic);
    }

    function testUpdateState() public {
        uint256 tokenId = character.mintCharacter(msg.sender, magicChar, Types.Alignment.MAGIC);

        Types.CharacterState memory newState = Types.CharacterState({
            health: 80,
            consecutiveHits: 2,
            damageReceived: 20,
            roundsParticipated: 5,
            alignment: Types.Alignment.STRENGTH
        });

        character.updateState(tokenId, newState);

        (,, Types.CharacterState memory state) = character.getCharacter(tokenId);
        assertEq(state.health, newState.health);
        assertEq(state.consecutiveHits, newState.consecutiveHits);
        assertEq(state.damageReceived, newState.damageReceived);
        assertEq(state.roundsParticipated, newState.roundsParticipated);
        assertEq(uint256(state.alignment), uint256(newState.alignment));
    }
}
