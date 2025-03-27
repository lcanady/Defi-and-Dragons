// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITimeQuest {
    function recordTimeProgress(bytes32 questId, uint256 characterId, uint256 streak) external;
}
