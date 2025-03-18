// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, Vm } from "lib/forge-std/src/Test.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { Pet } from "../src/pets/Pet.sol";
import { Mount } from "../src/pets/Mount.sol";
import { Ability } from "../src/abilities/Ability.sol";
import { AttributeCalculator } from "../src/attributes/AttributeCalculator.sol";
import { Types } from "../src/interfaces/Types.sol";
import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { ArcaneCrafting } from "../src/amm/ArcaneCrafting.sol";
import { TestHelper } from "./helpers/TestHelper.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract AttributeSystemTest is Test, TestHelper, IERC721Receiver, IERC1155Receiver {
    using Strings for uint256;

    // State variables
    Character public character;
    Equipment public equipment;
    Pet public pet;
    Mount public mount;
    Ability public ability;
    AttributeCalculator public calculator;
    VRFCoordinatorV2Mock public vrfCoordinator;
    ItemDrop public itemDrop;
    ArcaneCrafting public crafting;

    // Constants
    uint256 public constant BASE_POINTS = 10_000; // 100% in basis points

    // Events for testing
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);

    address public owner;
    address public user;
    uint256 public characterId;
    Types.Stats public baseStats;

    // Test equipment IDs
    uint256 public weaponId;
    uint256 public armorId;

    // Constants for VRF
    uint64 constant _SUBSCRIPTION_ID = 1;
    bytes32 constant _KEY_HASH = keccak256("test");
    uint32 constant _CALLBACK_GAS_LIMIT = 2_000_000;
    uint16 constant _NUM_WORDS = 1;
    uint16 constant _REQUEST_CONFIRMATIONS = 3;

    // Implement onERC721Received
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Implement IERC1155Receiver
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

    // Helper function to deploy core contracts
    function deployContracts() private {
        // Deploy core contracts
        equipment = new Equipment();
        character = new Character(address(equipment));
        equipment.setCharacterContract(address(character));

        // Deploy providers
        pet = new Pet(address(character));
        mount = new Mount(address(character));
        ability = new Ability(address(character));

        // Deploy calculator
        calculator = new AttributeCalculator(address(character), address(equipment));

        // Set up provider permissions and add to calculator
        vm.startPrank(owner);
        pet.transferOwnership(owner);
        mount.transferOwnership(owner);
        ability.transferOwnership(owner);
        calculator.addProvider(address(pet));
        calculator.addProvider(address(mount));
        calculator.addProvider(address(ability));
        calculator.setMountContract(address(mount));
        vm.stopPrank();
    }

    // Helper function to deploy and setup VRF system
    function setupVRFSystem() private {
        vrfCoordinator = new VRFCoordinatorV2Mock(0.1 ether, 1e9);

        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(_SUBSCRIPTION_ID, 100 ether);

        itemDrop = new ItemDrop(
            address(vrfCoordinator),
            _SUBSCRIPTION_ID,
            _KEY_HASH,
            _CALLBACK_GAS_LIMIT,
            _REQUEST_CONFIRMATIONS,
            _NUM_WORDS
        );

        vrfCoordinator.addConsumer(_SUBSCRIPTION_ID, address(itemDrop));

        itemDrop.initialize(address(equipment));
        equipment.grantRole(equipment.MINTER_ROLE(), address(itemDrop));
    }

    // Helper function to create and equip test equipment
    function createAndEquipTestGear() private {
        weaponId = equipment.createEquipment(
            "Test Weapon",
            "A basic weapon",
            5, // strength bonus
            3, // agility bonus
            2 // magic bonus
        );

        armorId = equipment.createEquipment(
            "Test Armor",
            "Basic armor",
            3, // strength bonus
            4, // agility bonus
            1 // magic bonus
        );

        address walletAddress = address(character.characterWallets(characterId));
        require(walletAddress != address(0), "Character wallet not created");

        equipment.mint(walletAddress, weaponId, 1, "");
        equipment.mint(walletAddress, armorId, 1, "");

        vm.startPrank(user);
        character.equip(characterId, weaponId, armorId);
        vm.stopPrank();
    }

    // Helper function to set up approvals
    function setupApprovals() private {
        address walletAddress = address(character.characterWallets(characterId));
        require(walletAddress != address(0), "Character wallet not created");

        vm.startPrank(owner);
        equipment.setApprovalForAll(address(character), true);
        equipment.setApprovalForAll(address(pet), true);
        equipment.setApprovalForAll(address(mount), true);
        equipment.setApprovalForAll(address(ability), true);
        equipment.setApprovalForAll(address(itemDrop), true);
        equipment.setApprovalForAll(address(crafting), true);
        equipment.setApprovalForAll(walletAddress, true);
        equipment.setCharacterContract(address(itemDrop));
        equipment.setItemDrop(address(itemDrop));
        vm.stopPrank();

        vm.startPrank(user);
        equipment.setApprovalForAll(address(character), true);
        equipment.setApprovalForAll(walletAddress, true);
        vm.stopPrank();
    }

    // Helper function to create a character with specified level
    function createTestCharacter(uint256 level) private {
        baseStats = Types.Stats({ strength: 10, agility: 8, magic: 6 });

        characterId = character.mintCharacter(
            user, // Mint to user
            baseStats,
            Types.Alignment.STRENGTH
        );

        if (level > 1) {
            vm.startPrank(owner);
            Types.CharacterState memory state = Types.CharacterState({
                health: 100,
                consecutiveHits: 0,
                damageReceived: 0,
                roundsParticipated: 0,
                alignment: Types.Alignment.STRENGTH,
                level: level
            });
            character.updateState(characterId, state);
            vm.stopPrank();
        }
    }

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        deployContracts();
        setupVRFSystem();

        crafting = new ArcaneCrafting(address(character), address(equipment), address(itemDrop));

        createTestCharacter(10);
        setupApprovals();
        createAndEquipTestGear();
    }

    function testAddRemoveAbility() public {
        vm.startPrank(owner);
        uint256 abilityId = ability.createAbility(
            "Test Ability",
            1000, // 10% AMM fee reduction
            2000, // 20% crafting success boost
            1500, // 15% VRF cost reduction
            1 hours, // 1 hour cooldown reduction
            1 // Level 1 required
        );

        vm.startPrank(user);
        ability.learnAbility(characterId, abilityId);
        assertTrue(ability.hasActiveAbility(characterId), "Ability should be active");
        vm.stopPrank();

        vm.startPrank(owner);
        ability.deactivateAbility(abilityId);
        assertFalse(ability.hasActiveAbility(characterId), "Ability should be inactive");
        vm.stopPrank();
    }

    function testAddRemovePet() public {
        vm.startPrank(owner);
        uint256 petId = pet.createPet(
            "Test Pet",
            "A loyal companion",
            Pet.Rarity.RARE,
            2000, // 20% yield boost
            1500, // 15% drop rate boost
            1 // Level 1 required
        );
        assertEq(petId, 1_000_000, "Incorrect initial pet ID");
        vm.stopPrank();

        vm.startPrank(user);
        pet.mintPet(characterId, petId);
        assertTrue(pet.hasActivePet(characterId), "Pet should be active");

        // Check benefits
        (uint256 yieldBoost, uint256 dropBoost) = pet.getPetBenefits(characterId);
        assertEq(yieldBoost, 2000, "Incorrect yield boost");
        assertEq(dropBoost, 1500, "Incorrect drop boost");

        pet.unassignPet(characterId);
        assertFalse(pet.hasActivePet(characterId), "Pet should be inactive");
        vm.stopPrank();
    }

    function testAddRemoveMount() public {
        vm.startPrank(owner);
        uint256 mountId = mount.createMount(
            "Test Mount",
            "A swift steed",
            Mount.MountType.AIR,
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
        vm.stopPrank();

        vm.startPrank(user);
        mount.mintMount(characterId, mountId);
        assertTrue(mount.hasActiveMount(characterId), "Mount should be active");

        // Check benefits
        (uint256 questFeeReduction, uint256 travelReduction, uint256 stakingBoost, uint256 lockReduction) =
            mount.getMountBenefits(characterId);

        assertEq(questFeeReduction, 1000, "Incorrect quest fee reduction");
        assertEq(travelReduction, 12 hours, "Incorrect travel reduction");
        assertEq(stakingBoost, 1500, "Incorrect staking boost");
        assertEq(lockReduction, 1000, "Incorrect lock reduction");

        mount.unassignMount(characterId);
        assertFalse(mount.hasActiveMount(characterId), "Mount should be inactive");
        vm.stopPrank();
    }

    function testAPRAndFeeAdjustments() public {
        vm.startPrank(owner);
        uint256 mountId = mount.createMount(
            "Test Mount",
            "A swift steed",
            Mount.MountType.AIR,
            1000, // 10% speed boost
            1000, // 10% stamina boost
            1000, // 10% yield boost
            1000, // 10% drop rate boost
            2000, // 20% quest fee reduction
            12 hours, // 12 hours travel reduction
            1500, // 15% staking boost
            1000, // 10% LP lock reduction
            1 // Level 1 required
        );
        assertEq(mountId, 2_000_000, "Incorrect initial mount ID");
        vm.stopPrank();

        vm.startPrank(user);
        mount.mintMount(characterId, mountId);
        assertTrue(mount.hasActiveMount(characterId), "Mount should be active");

        // Check quest fee reduction
        uint256 questFeeReduction = calculator.getQuestFeeReduction(characterId);
        assertEq(questFeeReduction, 2000, "Incorrect quest fee reduction");
        vm.stopPrank();
    }

    function testVRFWithModifiers() public {
        // Create test items first
        vm.startPrank(owner);
        for (uint256 i = 0; i < 5; i++) {
            equipment.createEquipment(
                string(abi.encodePacked("Test Item ", i.toString())),
                string(abi.encodePacked("A test item #", i.toString())),
                5, // strength bonus
                0, // agility bonus
                0 // magic bonus
            );
        }
        vm.stopPrank();

        uint256 abilityId = ability.createAbility(
            "VRF Master",
            0, // No AMM fee reduction
            0, // No crafting boost
            2000, // 20% VRF cost reduction
            0, // No cooldown reduction
            1 // Level 1 required
        );

        vm.startPrank(user);
        ability.learnAbility(characterId, abilityId);

        address walletAddress = address(character.characterWallets(characterId));
        uint256 requestId = itemDrop.requestRandomDrop(walletAddress, 0);
        assertTrue(requestId > 0, "Request ID should be greater than 0");

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123;

        // Start recording logs
        vm.recordLogs();

        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(itemDrop), randomWords);

        (,, bool fulfilled) = itemDrop.dropRequests(requestId);
        assertTrue(fulfilled, "Request should be fulfilled");

        // Check for ItemDropped event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool itemDropped = false;
        uint256 droppedItemId;
        uint256 droppedAmount;
        address droppedPlayer;

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ItemDropped(address,uint256,uint256)")) {
                itemDropped = true;
                droppedPlayer = address(uint160(uint256(entries[i].topics[1])));
                droppedItemId = uint256(entries[i].topics[2]);
                droppedAmount = abi.decode(entries[i].data, (uint256));
                break;
            }
        }

        assertTrue(itemDropped, "No item drop event found");
        assertEq(droppedPlayer, walletAddress, "Item dropped to wrong player");
        assertEq(equipment.balanceOf(walletAddress, droppedItemId), 1, "Item should have been dropped");
    }

    function testCombinedBonusEffects() public {
        // Character is already created with level 10 in setUp()

        // Create items as owner
        vm.startPrank(owner);

        // Create and mint pet for yield boost
        uint256 petId = pet.createPet(
            "Yield Pet",
            "A profitable companion",
            Pet.Rarity.LEGENDARY,
            4000, // 40% yield boost
            0, // No drop rate boost
            1 // Level 1 required
        );
        assertEq(petId, 1_000_000, "Incorrect initial pet ID");

        // Create and mint mount for staking boost
        uint256 mountId = mount.createMount(
            "Staking Mount",
            "A profitable steed",
            Mount.MountType.AIR,
            1000, // 10% speed boost
            1000, // 10% stamina boost
            1000, // 10% yield boost
            1000, // 10% drop rate boost
            0, // No quest fee reduction
            0, // No travel reduction
            4000, // 40% staking boost
            0, // No LP lock reduction
            1 // Level 1 required
        );
        assertEq(mountId, 2_000_000, "Incorrect initial mount ID");

        // Create and learn ability for crafting boost
        uint256 abilityId = ability.createAbility(
            "Master Crafter",
            0, // No AMM fee reduction
            4000, // 40% crafting boost
            0, // No VRF cost reduction
            0, // No cooldown reduction
            1 // Level 1 required
        );
        vm.stopPrank();

        // Mint/learn everything as user
        vm.startPrank(user);
        pet.mintPet(characterId, petId);
        mount.mintMount(characterId, mountId);
        ability.learnAbility(characterId, abilityId);

        // Verify each provider is active for the character
        assertTrue(pet.hasActivePet(characterId), "Pet should be active");
        assertTrue(mount.hasActiveMount(characterId), "Mount should be active");
        assertTrue(ability.hasActiveAbility(characterId), "Ability should be active");

        // Verify individual bonuses
        assertEq(pet.getBonus(characterId), 4000, "Pet bonus should be 40%");
        assertEq(mount.getBonus(characterId), 4000, "Mount bonus should be 40%");
        assertEq(ability.getBonus(characterId), 4000, "Ability bonus should be 40%");

        // Calculate total bonuses
        (, uint256 bonusMultiplier) = calculator.calculateTotalAttributes(characterId);
        uint256 totalBonus = bonusMultiplier - BASE_POINTS;
        assertEq(
            totalBonus,
            13_500,
            "Combined bonus should be 135% (40% pet + 40% mount + 40% ability + 10% level + 5% alignment)"
        );

        vm.stopPrank();
    }
}
