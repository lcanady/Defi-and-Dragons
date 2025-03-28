// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Types.sol";
import { NotCharacterContract, NotWeaponOwner, NotArmorOwner } from "./interfaces/Errors.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CharacterWallet is Ownable, ERC1155Holder, ERC721Holder {
    IEquipment public immutable equipment;
    uint256 public immutable characterId;
    address public immutable characterContract;

    Types.EquipmentSlots private _equippedItems;

    event ItemEquipped(uint256 indexed characterId, uint256 weaponId, uint256 armorId);
    event ItemUnequipped(uint256 indexed characterId, bool weapon, bool armor);

    constructor(address _equipment, uint256 _characterId, address _characterContract) {
        equipment = IEquipment(_equipment);
        characterId = _characterId;
        characterContract = _characterContract;
        _transferOwnership(msg.sender);
    }

    modifier onlyCharacterContract() {
        if (msg.sender != characterContract) revert NotCharacterContract();
        _;
    }

    function equip(uint256 weaponId, uint256 armorId) external onlyCharacterContract {
        // Check weapon ownership and equip
        if (equipment.balanceOf(address(this), weaponId) == 0) {
            if (weaponId != 0) revert NotWeaponOwner();
        } else {
            _equippedItems.weaponId = weaponId;
        }

        // Check armor ownership and equip
        if (equipment.balanceOf(address(this), armorId) == 0) {
            if (armorId != 0) revert NotArmorOwner();
        } else {
            _equippedItems.armorId = armorId;
        }

        emit ItemEquipped(characterId, weaponId, armorId);
    }

    function unequip(bool weapon, bool armor) external onlyCharacterContract {
        if (weapon) {
            _equippedItems.weaponId = 0;
        }
        if (armor) {
            _equippedItems.armorId = 0;
        }
        emit ItemUnequipped(characterId, weapon, armor);
    }

    function getEquippedItems() external view returns (Types.EquipmentSlots memory) {
        return _equippedItems;
    }
}
