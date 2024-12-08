// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { Types } from "./interfaces/Types.sol";
import { IEquipment } from "./interfaces/IEquipment.sol";
import { OnlyCharacterContract, NotWeaponOwner, NotArmorOwner } from "./interfaces/Errors.sol";

contract CharacterWallet is Ownable, ERC1155Holder {
    IEquipment public immutable equipment;
    uint256 public immutable characterId;
    address public immutable characterContract;

    Types.EquipmentSlots private _equippedItems;

    event ItemEquipped(uint256 indexed characterId, uint256 weaponId, uint256 armorId);
    event ItemUnequipped(uint256 indexed characterId, bool weapon, bool armor);

    constructor(address _equipment, uint256 _characterId, address _characterContract) {
        _transferOwnership(msg.sender);
        equipment = IEquipment(_equipment);
        characterId = _characterId;
        characterContract = _characterContract;
    }

    modifier onlyCharacterContract() {
        if (msg.sender != characterContract) revert OnlyCharacterContract();
        _;
    }

    function equip(uint256 weaponId, uint256 armorId) external onlyCharacterContract {
        if (weaponId > 0) {
            if (equipment.balanceOf(owner(), weaponId) == 0) revert NotWeaponOwner();
            _equippedItems.weaponId = weaponId;
        }

        if (armorId > 0) {
            if (equipment.balanceOf(owner(), armorId) == 0) revert NotArmorOwner();
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
