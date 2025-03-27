// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Errors.sol";
import "./interfaces/ICharacter.sol";

contract Equipment is ERC1155, Ownable, AccessControl, IEquipment {
    // Packed equipment stats for gas optimization
    struct PackedEquipmentStats {
        uint8 strengthBonus;
        uint8 agilityBonus;
        uint8 magicBonus;
        bool isActive;
        Types.Alignment statAffinity;
        string name;
        string description;
    }

    // State variables
    mapping(uint256 => PackedEquipmentStats) public equipmentStats;
    mapping(uint256 => bool) private _exists;
    mapping(uint256 => Types.SpecialAbility[]) public specialAbilities;

    // Optimized cooldown storage - pack characterId, equipmentId, and abilityIndex into single slot
    mapping(bytes32 => uint40) public abilityCooldowns; // Using uint40 for timestamps (sufficient until year 2104)

    uint64 private _nextTokenId = 1; // Start from 1, reduced from uint256
    address private _characterContract;
    address private _itemDrop;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Events
    event EquipmentCreated(uint256 indexed tokenId, string name, string description);
    event EquipmentActivated(uint256 indexed tokenId);
    event EquipmentDeactivated(uint256 indexed tokenId);
    event CharacterContractUpdated(address indexed newContract);

    constructor(address characterContract) ERC1155("") Ownable() {
        if (characterContract == address(0)) revert InvalidCharacterContract();
        _characterContract = characterContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyCharacterContract() {
        if (msg.sender != _characterContract) revert NotCharacterContract();
        _;
    }

    function setCharacterContract(address characterContract) external onlyOwner {
        if (characterContract == address(0)) revert InvalidCharacterContract();
        _characterContract = characterContract;
        emit CharacterContractUpdated(characterContract);
    }

    function createEquipment(
        string calldata name,
        string calldata description,
        uint8 strengthBonus,
        uint8 agilityBonus,
        uint8 magicBonus,
        Types.Alignment statAffinity,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _exists[tokenId] = true;

        equipmentStats[tokenId] = PackedEquipmentStats({
            strengthBonus: strengthBonus,
            agilityBonus: agilityBonus,
            magicBonus: magicBonus,
            isActive: true,
            statAffinity: statAffinity,
            name: name,
            description: description
        });

        emit EquipmentCreated(tokenId, name, description);
        return tokenId;
    }

    function getEquipmentStats(uint256 tokenId)
        external
        view
        override
        returns (Types.EquipmentStats memory stats, bool exists)
    {
        exists = _exists[tokenId];
        if (!exists) return (stats, false);

        PackedEquipmentStats storage packed = equipmentStats[tokenId];
        stats.strengthBonus = packed.strengthBonus;
        stats.agilityBonus = packed.agilityBonus;
        stats.magicBonus = packed.magicBonus;
        stats.isActive = packed.isActive;
        stats.statAffinity = packed.statAffinity;
        stats.name = packed.name;
        stats.description = packed.description;
        return (stats, true);
    }

    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        override
        returns (Types.SpecialAbility memory)
    {
        if (abilityIndex >= specialAbilities[equipmentId].length) revert InvalidAbilityIndex();
        return specialAbilities[equipmentId][abilityIndex];
    }

    function getSpecialAbilities(uint256 equipmentId) external view override returns (Types.SpecialAbility[] memory) {
        return specialAbilities[equipmentId];
    }

    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        override
        onlyCharacterContract
    {
        if (abilityIndex >= specialAbilities[equipmentId].length) revert InvalidAbilityIndex();
        bytes32 cooldownKey = keccak256(abi.encodePacked(characterId, equipmentId, abilityIndex));
        abilityCooldowns[cooldownKey] = uint40(currentRound);
    }

    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        override
        returns (bool)
    {
        if (abilityIndex >= specialAbilities[equipmentId].length) revert InvalidAbilityIndex();
        Types.SpecialAbility memory ability = specialAbilities[equipmentId][abilityIndex];
        bytes32 cooldownKey = keccak256(abi.encodePacked(characterId, equipmentId, abilityIndex));
        uint256 lastUsed = abilityCooldowns[cooldownKey];
        return currentRound >= lastUsed + ability.cooldown;
    }

    function calculateEquipmentBonus(uint256 characterId)
        external
        view
        override
        returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)
    {
        // Get equipped items from character contract
        (, Types.EquipmentSlots memory equipment,) = ICharacter(_characterContract).getCharacter(characterId);

        // Calculate bonuses from weapon
        if (equipment.weaponId != 0) {
            PackedEquipmentStats storage weaponStats = equipmentStats[equipment.weaponId];
            if (_exists[equipment.weaponId] && weaponStats.isActive) {
                strengthBonus += weaponStats.strengthBonus;
                agilityBonus += weaponStats.agilityBonus;
                magicBonus += weaponStats.magicBonus;
            }
        }

        // Calculate bonuses from armor
        if (equipment.armorId != 0) {
            PackedEquipmentStats storage armorStats = equipmentStats[equipment.armorId];
            if (_exists[equipment.armorId] && armorStats.isActive) {
                strengthBonus += armorStats.strengthBonus;
                agilityBonus += armorStats.agilityBonus;
                magicBonus += armorStats.magicBonus;
            }
        }

        return (strengthBonus, agilityBonus, magicBonus);
    }

    function deactivateEquipment(uint256 equipmentId) external onlyOwner {
        if (!_exists[equipmentId]) revert EquipmentNotFound();

        PackedEquipmentStats storage stats = equipmentStats[equipmentId];
        if (stats.strengthBonus == 0 && stats.agilityBonus == 0 && stats.magicBonus == 0) {
            revert NoEquipmentBonuses();
        }

        stats.isActive = false;
        emit EquipmentDeactivated(equipmentId);
    }

    function activateEquipment(uint256 equipmentId) external onlyOwner {
        if (!_exists[equipmentId]) revert EquipmentNotFound();

        PackedEquipmentStats storage stats = equipmentStats[equipmentId];
        if (stats.strengthBonus == 0 && stats.agilityBonus == 0 && stats.magicBonus == 0) {
            revert NoEquipmentBonuses();
        }

        stats.isActive = true;
        emit EquipmentActivated(equipmentId);
    }

    function setItemDrop(address itemDrop) external onlyOwner {
        if (itemDrop == address(0)) revert InvalidItemDropContract();
        _itemDrop = itemDrop;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external override onlyRole(MINTER_ROLE) {
        // Check if equipment is active
        if (_exists[id]) {
            PackedEquipmentStats storage stats = equipmentStats[id];
            if (!stats.isActive) revert EquipmentNotActive();
        }

        _mint(to, id, amount, data);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IEquipment)
        returns (uint256)
    {
        return super.balanceOf(account, id);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return super.uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IEquipment).interfaceId;
    }

    function getEquipmentCount() external view returns (uint256) {
        return _nextTokenId - 1;
    }

    function getEquipmentInfo(uint256 equipmentId)
        external
        view
        returns (string memory name, string memory description, bool isActive)
    {
        if (!_exists[equipmentId]) revert EquipmentNotFound();
        PackedEquipmentStats storage stats = equipmentStats[equipmentId];
        return (stats.name, stats.description, stats.isActive);
    }
}
