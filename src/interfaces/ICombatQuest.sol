// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICombatQuest {
    function startBossFight(bytes32 monsterId, uint256 spawnDuration) external returns (bytes32);
}
