// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Equipment is ERC1155, Ownable {
    using Strings for uint256;

    // Equipment types
    enum EquipmentType { WEAPON, ARMOR, SHIELD, AMULET, RING }

    // Equipment attributes
    struct EquipmentAttributes {
        string name;
        EquipmentType equipmentType;
        uint8 level;
        uint8 damage;        // For weapons
        uint8 defense;       // For armor/shield
        uint8 magicBonus;    // For magical items
        bool isEquipped;
    }

    // Mapping from token ID to equipment attributes
    mapping(uint256 => EquipmentAttributes) public equipmentAttributes;
    
    // Counter for creating new equipment types
    uint256 private _nextEquipmentId = 1;

    // Events
    event EquipmentCreated(uint256 indexed tokenId, string name, EquipmentType equipmentType);
    event EquipmentMinted(address indexed to, uint256 indexed tokenId, uint256 amount);

    constructor() ERC1155("") Ownable(msg.sender) {}

    /**
     * @dev Create a new equipment type
     * @param name Equipment name
     * @param equipmentType Type of equipment
     * @param level Required level to use
     * @param damage Damage value (for weapons)
     * @param defense Defense value (for armor/shield)
     * @param magicBonus Magic bonus value
     */
    function createEquipmentType(
        string memory name,
        EquipmentType equipmentType,
        uint8 level,
        uint8 damage,
        uint8 defense,
        uint8 magicBonus
    ) public onlyOwner returns (uint256) {
        uint256 newEquipmentId = _nextEquipmentId++;
        
        equipmentAttributes[newEquipmentId] = EquipmentAttributes({
            name: name,
            equipmentType: equipmentType,
            level: level,
            damage: damage,
            defense: defense,
            magicBonus: magicBonus,
            isEquipped: false
        });

        emit EquipmentCreated(newEquipmentId, name, equipmentType);
        return newEquipmentId;
    }

    /**
     * @dev Mint new equipment
     * @param to Address to mint to
     * @param id Equipment type ID
     * @param amount Amount to mint
     * @param data Additional data
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(id < _nextEquipmentId, "Equipment type does not exist");
        _mint(to, id, amount, data);
        emit EquipmentMinted(to, id, amount);
    }

    /**
     * @dev Batch mint new equipment
     * @param to Address to mint to
     * @param ids Array of equipment type IDs
     * @param amounts Array of amounts to mint
     * @param data Additional data
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < _nextEquipmentId, "Equipment type does not exist");
        }
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Get equipment attributes
     * @param id Equipment type ID
     */
    function getEquipmentAttributes(uint256 id) public view returns (EquipmentAttributes memory) {
        require(id < _nextEquipmentId, "Equipment type does not exist");
        return equipmentAttributes[id];
    }

    /**
     * @dev Set equipment as equipped/unequipped
     * @param id Equipment type ID
     * @param equipped Equipment status
     */
    function setEquipped(uint256 id, bool equipped) public {
        require(id < _nextEquipmentId, "Equipment type does not exist");
        require(balanceOf(msg.sender, id) > 0, "Must own equipment to equip/unequip");
        equipmentAttributes[id].isEquipped = equipped;
    }

    /**
     * @dev URI for token metadata
     * @param tokenId Token ID
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < _nextEquipmentId, "Equipment type does not exist");
        return string(abi.encodePacked("https://game.example.com/api/equipment/", tokenId.toString()));
    }
} 