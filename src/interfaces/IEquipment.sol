// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Types.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IEquipment is IERC1155 {
    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external;
    function getEquipmentStats(uint256 equipmentId)
        external
        view
        returns (Types.EquipmentStats memory stats, bool exists);
    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        returns (Types.SpecialAbility memory);
    function getSpecialAbilities(uint256 equipmentId) external view returns (Types.SpecialAbility[] memory);
    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        returns (bool);
    function calculateEquipmentBonus(uint256 characterId)
        external
        view
        returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function getEquipmentCount() external view returns (uint256);
    function getEquipmentInfo(uint256 equipmentId)
        external
        view
        returns (string memory name, string memory description, bool isActive);
}
