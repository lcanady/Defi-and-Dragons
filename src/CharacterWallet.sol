// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Types.sol";

contract CharacterWallet is ERC1155Holder, Ownable {
    IEquipment public immutable equipment;
    uint256 public immutable characterId;
    address public immutable characterContract;

    // Current equipped items
    Types.EquipmentSlots public equippedItems;

    event ItemEquipped(uint256 indexed slot, uint256 indexed itemId);
    event ItemUnequipped(uint256 indexed slot, uint256 indexed itemId);

    constructor(
        address _equipment,
        uint256 _characterId,
        address _characterContract,
        address _owner
    ) Ownable(_owner) {
        equipment = IEquipment(_equipment);
        characterId = _characterId;
        characterContract = _characterContract;
    }

    modifier onlyCharacterOwner() {
        require(msg.sender == owner() || msg.sender == characterContract, "Not authorized");
        _;
    }

    function equip(uint256 weaponId, uint256 armorId) external onlyCharacterOwner {
        // Check if caller owns the equipment
        if (weaponId > 0) {
            require(equipment.balanceOf(address(this), weaponId) > 0, "Don't own weapon");
            equippedItems.weaponId = weaponId;
            emit ItemEquipped(1, weaponId); // 1 for weapon slot
        }
        
        if (armorId > 0) {
            require(equipment.balanceOf(address(this), armorId) > 0, "Don't own armor");
            equippedItems.armorId = armorId;
            emit ItemEquipped(2, armorId); // 2 for armor slot
        }
    }

    function unequip(bool weapon, bool armor) external onlyCharacterOwner {
        if (weapon && equippedItems.weaponId > 0) {
            uint256 oldWeaponId = equippedItems.weaponId;
            equippedItems.weaponId = 0;
            emit ItemUnequipped(1, oldWeaponId);
        }
        
        if (armor && equippedItems.armorId > 0) {
            uint256 oldArmorId = equippedItems.armorId;
            equippedItems.armorId = 0;
            emit ItemUnequipped(2, oldArmorId);
        }
    }

    function getEquippedItems() external view returns (Types.EquipmentSlots memory) {
        return equippedItems;
    }

    // Override transferOwnership to allow the character contract to transfer ownership
    function transferOwnership(address newOwner) public virtual override {
        if (msg.sender == characterContract) {
            _transferOwnership(newOwner);
        } else {
            super.transferOwnership(newOwner);
        }
    }
} 