// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Types.sol";

interface IEquipment {
    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external;
    function getEquipmentStats(uint256 equipmentId) external view returns (Types.EquipmentStats memory);
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
}
