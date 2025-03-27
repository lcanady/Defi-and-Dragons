// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IEquipment } from "../../src/interfaces/IEquipment.sol";
import { Types } from "../../src/interfaces/Types.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract MockEquipment is ERC1155, IEquipment {
    constructor(address characterContract) ERC1155("") { }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public override {
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

    function getEquipmentStats(uint256 tokenId)
        external
        view
        override
        returns (Types.EquipmentStats memory stats, bool exists)
    {
        return (stats, true);
    }

    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        override
        returns (Types.SpecialAbility memory)
    {
        return Types.SpecialAbility({
            name: "",
            description: "",
            triggerCondition: Types.TriggerCondition.NONE,
            triggerValue: 0,
            effectType: Types.EffectType.NONE,
            effectValue: 0,
            cooldown: 0
        });
    }

    function getSpecialAbilities(uint256 equipmentId) external view override returns (Types.SpecialAbility[] memory) {
        return new Types.SpecialAbility[](0);
    }

    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        override
    { }

    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        override
        returns (bool)
    {
        return true;
    }

    function calculateEquipmentBonus(uint256 characterId)
        external
        view
        override
        returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)
    {
        return (0, 0, 0);
    }

    function getEquipmentCount() external view override returns (uint256) {
        return 0;
    }

    function getEquipmentInfo(uint256 equipmentId)
        external
        view
        override
        returns (string memory name, string memory description, bool isActive)
    {
        return ("", "", true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IEquipment).interfaceId;
    }
}
