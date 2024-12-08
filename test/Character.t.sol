// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";
import { Types } from "../src/interfaces/Types.sol";

contract CharacterTest is Test {
    Character public character;
    Equipment public equipment;
    address public owner;
    address public player;
    uint256 public characterId;

    function setUp() public {
        owner = address(this);
        player = makeAddr("player");

        // Deploy contracts
        equipment = new Equipment();
        character = new Character(address(equipment));

        // Setup equipment
        equipment.setCharacterContract(address(character));
        equipment.createEquipment(1, "Test Weapon", "A test weapon", 5, 0, 0);
        equipment.createEquipment(2, "Test Armor", "A test armor", 0, 5, 0);

        // Mint character
        vm.startPrank(owner);
        characterId = character.mintCharacter(
            player, Types.Stats({ strength: 10, agility: 10, magic: 10 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();
    }

    function testMint() public {
        assertEq(character.ownerOf(characterId), player);
        assertEq(character.balanceOf(player), 1);
    }

    function testUpdateStats() public {
        vm.startPrank(owner);
        character.updateStats(characterId, Types.Stats({ strength: 15, agility: 12, magic: 8 }));
        vm.stopPrank();

        (Types.Stats memory stats,,) = character.getCharacter(characterId);
        assertEq(stats.strength, 15);
        assertEq(stats.agility, 12);
        assertEq(stats.magic, 8);
    }

    function testUpdateState() public {
        vm.startPrank(owner);
        character.updateState(
            characterId,
            Types.CharacterState({
                health: 100,
                consecutiveHits: 3,
                damageReceived: 50,
                roundsParticipated: 5,
                alignment: Types.Alignment.STRENGTH
            })
        );
        vm.stopPrank();

        (,, Types.CharacterState memory state) = character.getCharacter(characterId);
        assertEq(uint256(state.health), 100);
        assertEq(state.consecutiveHits, 3);
        assertEq(state.damageReceived, 50);
        assertEq(state.roundsParticipated, 5);
        assertEq(uint256(state.alignment), uint256(Types.Alignment.STRENGTH));
    }

    function testEquip() public {
        // Get character's wallet
        CharacterWallet wallet = character.characterWallets(characterId);

        // Set up Equipment contract
        vm.startPrank(owner);
        equipment.setCharacterContract(address(character));

        // Mint equipment to player
        equipment.mint(player, 1, 1, "");
        equipment.mint(player, 2, 1, "");
        vm.stopPrank();

        // Transfer wallet ownership to player
        vm.prank(address(character));
        wallet.transferOwnership(player);

        // Player approves equipment for both wallet and character contract
        vm.startPrank(player);
        equipment.setApprovalForAll(address(wallet), true);
        equipment.setApprovalForAll(address(character), true);
        vm.stopPrank();

        // Equip items through character contract
        vm.prank(player);
        character.equip(characterId, 1, 2);

        // Check equipped items
        (, Types.EquipmentSlots memory slots,) = character.getCharacter(characterId);
        assertEq(slots.weaponId, 1);
        assertEq(slots.armorId, 2);
    }

    function testFailEquipUnownedItems() public {
        // Get character's wallet
        CharacterWallet wallet = character.characterWallets(characterId);

        // Transfer wallet ownership to player
        vm.prank(owner);
        wallet.transferOwnership(player);

        // Try to equip items without owning them
        vm.startPrank(player);
        equipment.setApprovalForAll(address(wallet), true);
        vm.expectRevert();
        character.equip(characterId, 1, 2);
        vm.stopPrank();
    }

    function testFailEquipWrongCharacter() public {
        // Create another character
        vm.startPrank(owner);
        uint256 otherCharacterId = character.mintCharacter(
            makeAddr("other"), Types.Stats({ strength: 10, agility: 10, magic: 10 }), Types.Alignment.STRENGTH
        );
        vm.stopPrank();

        // Mint equipment to player
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 1;
        amounts[1] = 1;
        vm.startPrank(owner);
        mintTestEquipment(equipment, player, itemIds, amounts);
        vm.stopPrank();

        // Try to equip items to wrong character (should fail)
        vm.prank(player);
        vm.expectRevert("NotCharacterOwner()");
        character.equip(otherCharacterId, 1, 2);
    }

    function testEquipmentBalances() public {
        // Mint multiple items
        vm.startPrank(owner);
        uint256[] memory itemIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        itemIds[0] = 1;
        itemIds[1] = 2;
        amounts[0] = 3;
        amounts[1] = 2;
        mintTestEquipment(equipment, player, itemIds, amounts);
        vm.stopPrank();

        // Check balances
        uint256[] memory balances = checkEquipmentBalances(equipment, player, itemIds);
        assertEq(balances[0], 3, "Should have 3 weapons");
        assertEq(balances[1], 2, "Should have 2 armor pieces");
    }

    function mintTestEquipment(Equipment _equipment, address _to, uint256[] memory _itemIds, uint256[] memory _amounts)
        internal
    {
        for (uint256 i = 0; i < _itemIds.length; i++) {
            _equipment.mint(_to, _itemIds[i], _amounts[i], "");
        }
    }

    function checkEquipmentBalances(Equipment _equipment, address _owner, uint256[] memory _itemIds)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_itemIds.length);
        for (uint256 i = 0; i < _itemIds.length; i++) {
            balances[i] = _equipment.balanceOf(_owner, _itemIds[i]);
        }
        return balances;
    }
}
