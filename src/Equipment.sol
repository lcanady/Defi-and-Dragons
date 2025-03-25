// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Errors.sol";
import "./interfaces/ICharacter.sol";

contract Equipment is ERC1155, Ownable, AccessControl, IEquipment {
    // State variables
    mapping(uint256 => Types.EquipmentStats) public equipmentStats;
    mapping(uint256 => bool) private _exists;
    mapping(uint256 => Types.SpecialAbility[]) public specialAbilities;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public abilityCooldowns;
    uint256 private _nextTokenId = 1; // Start from 1 instead of 0
    address private _characterContract;
    address private _itemDrop;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Events
    event EquipmentCreated(uint256 indexed tokenId, string name, string description);
    event EquipmentActivated(uint256 indexed tokenId);
    event EquipmentDeactivated(uint256 indexed tokenId);

    constructor() ERC1155("") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyCharacterContract() {
        require(msg.sender == _characterContract, "Only character contract");
        _;
    }

    function setCharacterContract(address characterContract) external onlyOwner {
        require(characterContract != address(0), "Invalid character contract");
        _characterContract = characterContract;
    }

    function createEquipment(
        string memory name,
        string memory description,
        uint8 strengthBonus,
        uint8 agilityBonus,
        uint8 magicBonus
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        equipmentStats[tokenId] = Types.EquipmentStats({
            strengthBonus: strengthBonus,
            agilityBonus: agilityBonus,
            magicBonus: magicBonus,
            isActive: true,
            name: name,
            description: description
        });

        _exists[tokenId] = true;
        emit EquipmentCreated(tokenId, name, description);
        return tokenId;
    }

    function getEquipmentStats(uint256 tokenId)
        external
        view
        override
        returns (Types.EquipmentStats memory stats, bool exists)
    {
        stats = equipmentStats[tokenId];
        exists = _exists[tokenId];
        return (stats, exists);
    }

    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        override
        returns (Types.SpecialAbility memory)
    {
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
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
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
        abilityCooldowns[characterId][equipmentId][abilityIndex] = currentRound;
    }

    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        override
        returns (bool)
    {
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
        Types.SpecialAbility memory ability = specialAbilities[equipmentId][abilityIndex];
        uint256 lastUsed = abilityCooldowns[characterId][equipmentId][abilityIndex];
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
            (Types.EquipmentStats memory weaponStats, bool weaponExists) = this.getEquipmentStats(equipment.weaponId);
            if (weaponExists && weaponStats.isActive) {
                strengthBonus += weaponStats.strengthBonus;
                agilityBonus += weaponStats.agilityBonus;
                magicBonus += weaponStats.magicBonus;
            }
        }

        // Calculate bonuses from armor
        if (equipment.armorId != 0) {
            (Types.EquipmentStats memory armorStats, bool armorExists) = this.getEquipmentStats(equipment.armorId);
            if (armorExists && armorStats.isActive) {
                strengthBonus += armorStats.strengthBonus;
                agilityBonus += armorStats.agilityBonus;
                magicBonus += armorStats.magicBonus;
            }
        }

        return (strengthBonus, agilityBonus, magicBonus);
    }

    /// @notice Deactivate an equipment type
    /// @param equipmentId The ID of the equipment to deactivate
    function deactivateEquipment(uint256 equipmentId) external onlyOwner {
        // Check if equipment exists
        if (!_exists[equipmentId]) {
            revert("Equipment does not exist");
        }

        Types.EquipmentStats storage stats = equipmentStats[equipmentId];

        // Check if equipment has any bonuses
        if (stats.strengthBonus == 0 && stats.agilityBonus == 0 && stats.magicBonus == 0) {
            revert("Equipment does not exist");
        }

        stats.isActive = false;
        emit EquipmentDeactivated(equipmentId);
    }

    /// @notice Activate an equipment type
    /// @param equipmentId The ID of the equipment to activate
    function activateEquipment(uint256 equipmentId) external onlyOwner {
        // Check if equipment exists
        if (!_exists[equipmentId]) {
            revert("Equipment does not exist");
        }

        Types.EquipmentStats storage stats = equipmentStats[equipmentId];

        // Check if equipment has any bonuses
        if (stats.strengthBonus == 0 && stats.agilityBonus == 0 && stats.magicBonus == 0) {
            revert("Equipment does not exist");
        }

        stats.isActive = true;
        emit EquipmentActivated(equipmentId);
    }

    function setItemDrop(address itemDrop) external onlyOwner {
        require(itemDrop != address(0), "Invalid item drop contract");
        _itemDrop = itemDrop;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external override onlyRole(MINTER_ROLE) {
        // Check if equipment is active
        if (_exists[id]) {
            Types.EquipmentStats memory stats = equipmentStats[id];
            if (!stats.isActive) {
                revert("Equipment not active");
            }
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
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getEquipmentCount() external view returns (uint256) {
        return _nextTokenId - 1;
    }

    function getEquipmentInfo(uint256 equipmentId) external view returns (string memory name, string memory description, bool isActive) {
        require(_exists[equipmentId], "Equipment does not exist");
        Types.EquipmentStats memory stats = equipmentStats[equipmentId];
        return (stats.name, stats.description, stats.isActive);
    }
}
