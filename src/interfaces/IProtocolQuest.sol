// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProtocolQuest {
    function recordInteraction(uint256 characterId, uint256 questId, uint128 volume) external;
}
