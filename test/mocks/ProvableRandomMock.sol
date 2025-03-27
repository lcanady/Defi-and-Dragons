// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ProvableRandom} from "../../src/ProvableRandom.sol";

contract ProvableRandomMock is ProvableRandom {
    mapping(bytes32 => uint256[]) public mockNumbers;

    function setMockNumbers(bytes32 seed, uint256[] memory numbers) public {
        mockNumbers[seed] = numbers;
    }

    function generateNumbers(address owner, bytes32 seed, uint256 count) public override returns (uint256[] memory) {
        if (mockNumbers[seed].length > 0) {
            return mockNumbers[seed];
        }
        return super.generateNumbers(owner, seed, count);
    }
} 