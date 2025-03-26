// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "../lib/forge-std/src/Test.sol";
import { AttributeCalculator } from "../src/attributes/AttributeCalculator.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Pet } from "../src/pets/Pet.sol";
import { Mount } from "../src/pets/Mount.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { Types } from "../src/interfaces/Types.sol";
import { CharacterWallet } from "../src/CharacterWallet.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract AttributeCalculatorTest is Test, IERC721Receiver, IERC1155Receiver {
    AttributeCalculator public calculator;
    Character public character;
    Equipment public equipment;
    Pet public pet;
    Mount public mount;
    Ability public ability;
    ProvableRandom public random;

    address public owner;
    address public user;
    uint256 public characterId;
    uint256 public petId;
    uint256 public mountId;
    uint256 public abilityId;
    uint256 public weaponId;
    uint256 public armorId;

    // Implement ERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement ERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy core contracts
        equipment = new Equipment();
        random = new ProvableRandom();
        character = new Character(address(equipment), address(random));
        equipment.setCharacterContract(address(character));

        // Deploy calculator
        calculator = new AttributeCalculator(address(character), address(equipment));

        // Deploy provider contracts
        pet = new Pet(address(character));
        mount = new Mount(address(character));
        ability = new Ability(address(character));

        // Add providers to calculator
        calculator.addProvider(address(pet));
        calculator.addProvider(address(mount));
        calculator.addProvider(address(ability));

        // Create a character
        character.mintCharacter(user, Types.Alignment.STRENGTH);

        // Get character wallet
        CharacterWallet wallet = character.characterWallets(characterId);

        // Create and mint test equipment
        weaponId = equipment.createEquipment(
            "Test Sword",
            "A mighty sword",
            5, // strength bonus
            2, // agility bonus
            1 // magic bonus
        );

        armorId = equipment.createEquipment(
            "Test Armor",
            "Sturdy armor",
            3, // strength bonus
            4, // agility bonus
            2 // magic bonus
        );

        // Mint equipment to wallet
        equipment.mint(address(wallet), weaponId, 1, "");
        equipment.mint(address(wallet), armorId, 1, "");

        // Set up approvals
        vm.startPrank(user);
        equipment.setApprovalForAll(address(character), true);
        equipment.setApprovalForAll(address(wallet), true);
        character.equip(characterId, weaponId, armorId);
        vm.stopPrank();

        // Create and assign test pet
        petId = pet.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );

        assertEq(petId, 1_000_000, "Incorrect initial pet ID");

        vm.startPrank(user);
        pet.mintPet(characterId, petId);
        vm.stopPrank();

        // Create and assign test mount
        mountId = mount.createMount(
            "Test Mount",
            "A swift steed",
            Mount.MountType.LAND,
            1000, // 10% speed boost
            1000, // 10% stamina boost
            1000, // 10% yield boost
            1000, // 10% drop rate boost
            1000, // 10% quest fee reduction
            12 hours, // 12 hours travel reduction
            1500, // 15% staking boost
            1000, // 10% LP lock reduction
            1 // Level 1 required
        );

        assertEq(mountId, 2_000_000, "Incorrect initial mount ID");

        vm.startPrank(user);
        mount.mintMount(characterId, mountId);
        vm.stopPrank();

        // Create and assign test ability
        abilityId = ability.createAbility(
            "Test Ability",
            2000, // 20% AMM fee reduction
            2000, // 20% crafting success boost
            2000, // 20% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            1 // Level 1 required
        );

        vm.startPrank(user);
        ability.learnAbility(characterId, abilityId);
        vm.stopPrank();
    }

    function testBaseAttributes() public view {
        // First get the base stats without equipment
        Types.Stats memory baseStats = calculator.getBaseStats(characterId);
        
        // Get total stats with equipment
        Types.Stats memory totalStats = calculator.getRawStats(characterId);

        // Verify equipment bonuses are correctly added
        assertEq(totalStats.strength, baseStats.strength + 8, "Incorrect strength bonus"); // +5 from weapon, +3 from armor
        assertEq(totalStats.agility, baseStats.agility + 6, "Incorrect agility bonus"); // +2 from weapon, +4 from armor
        assertEq(totalStats.magic, baseStats.magic + 3, "Incorrect magic bonus"); // +1 from weapon, +2 from armor
    }

    function testBonusMultipliers() public {
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Expected bonuses:
        // Base: 10000 (100%)
        // Pet: 2000 (20%)
        // Mount: 1500 (15%)
        // Ability: 2000 (20%)
        // Alignment: 500 (5% for strength alignment)
        // Level: 100 (1% for level 1)
        uint256 expectedMultiplier = 16_100; // 10000 + 2000 + 1500 + 2000 + 500 + 100

        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus multiplier");
    }

    function testStatBonuses() public {
        // Get raw stats
        Types.Stats memory rawStats = calculator.getRawStats(characterId);

        // Get individual stat bonuses
        uint256 strengthBonus = calculator.getStatBonus(characterId, 0);
        uint256 agilityBonus = calculator.getStatBonus(characterId, 1);
        uint256 magicBonus = calculator.getStatBonus(characterId, 2);

        // Calculate expected bonuses with multiplier
        uint256 expectedMultiplier = 16_100; // Base (10000) + Pet (2000) + Mount (1500) + Ability (2000) + Alignment (500) + Level (100)
        uint256 expectedStrength = (rawStats.strength * expectedMultiplier) / 10_000;
        uint256 expectedAgility = (rawStats.agility * expectedMultiplier) / 10_000;
        uint256 expectedMagic = (rawStats.magic * expectedMultiplier) / 10_000;

        assertEq(strengthBonus, expectedStrength, "Incorrect strength bonus");
        assertEq(agilityBonus, expectedAgility, "Incorrect agility bonus");
        assertEq(magicBonus, expectedMagic, "Incorrect magic bonus");
    }

    function testLevelProgression() public {
        // Update character to level 10
        Types.CharacterState memory newState = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: Types.Alignment.STRENGTH,
            level: 10
        });
        character.updateState(characterId, newState);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Expected bonuses:
        // Base: 10000 (100%)
        // Pet: 2000 (20%)
        // Mount: 1500 (15%)
        // Ability: 2000 (20%)
        // Alignment: 500 (5%)
        // Level: 1000 (10% for level 10)
        uint256 expectedMultiplier = 17_000; // 10000 + 2000 + 1500 + 2000 + 500 + 1000

        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect level 10 bonus multiplier");
    }

    function testDeactivatedEquipment() public {
        // Get base stats before deactivating equipment
        Types.Stats memory baseStats = calculator.getBaseStats(characterId);

        // Deactivate equipment
        equipment.deactivateEquipment(weaponId);
        equipment.deactivateEquipment(armorId);

        // Get stats after deactivating equipment
        Types.Stats memory totalStats = calculator.getRawStats(characterId);

        // Should only have base stats since equipment is deactivated
        assertEq(totalStats.strength, baseStats.strength, "Incorrect strength with deactivated equipment");
        assertEq(totalStats.agility, baseStats.agility, "Incorrect agility with deactivated equipment");
        assertEq(totalStats.magic, baseStats.magic, "Incorrect magic with deactivated equipment");
    }

    function testDeactivatedBonuses() public {
        // Deactivate all bonus sources
        pet.deactivatePet(petId);
        mount.deactivateMount(mountId);
        ability.deactivateAbility(abilityId);

        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);

        // Expected bonuses:
        // Base: 10000 (100%)
        // Alignment: 500 (5%)
        // Level: 100 (1%)
        uint256 expectedMultiplier = 10_600; // 10000 + 500 + 100

        assertEq(bonusMultiplier, expectedMultiplier, "Incorrect bonus multiplier with deactivated sources");
    }

    function testCalculateTotalStats() public {
        // Get raw stats (base + equipment)
        Types.Stats memory rawStats = calculator.getRawStats(characterId);
        
        // Calculate total stats with multiplier
        (Types.Stats memory totalStats, uint256 multiplier) = calculator.calculateTotalAttributes(characterId);

        // Expected multiplier from previous test
        uint256 expectedMultiplier = 16_100; // Base (10000) + Pet (2000) + Mount (1500) + Ability (2000) + Alignment (500) + Level (100)
        
        // Calculate expected stats
        uint256 expectedStrength = (rawStats.strength * expectedMultiplier) / 10_000;
        uint256 expectedAgility = (rawStats.agility * expectedMultiplier) / 10_000;
        uint256 expectedMagic = (rawStats.magic * expectedMultiplier) / 10_000;

        // Verify multiplier and stats
        assertEq(multiplier, expectedMultiplier, "Incorrect multiplier");
        assertEq(totalStats.strength, expectedStrength, "Incorrect total strength");
        assertEq(totalStats.agility, expectedAgility, "Incorrect total agility");
        assertEq(totalStats.magic, expectedMagic, "Incorrect total magic");
    }
}
