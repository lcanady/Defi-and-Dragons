// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ProvableRandom} from "./ProvableRandom.sol";

contract AttributeSystem {
    ProvableRandom public immutable random;
    mapping(address => bool) public providers;
    uint256 public constant PROVIDER_BONUS = 2060; // 20.60% bonus
    uint256 public constant MAX_PROVIDERS = 10;
    uint256 public providerCount;

    constructor(address _random) {
        random = ProvableRandom(_random);
    }

    function addProvider(address provider) external {
        require(!providers[provider], "Provider already exists");
        require(providerCount < MAX_PROVIDERS, "Maximum providers reached");
        providers[provider] = true;
        providerCount++;
    }

    function removeProvider(address provider) external {
        require(providers[provider], "Provider does not exist");
        providers[provider] = false;
        providerCount--;
    }

    function isProvider(address provider) external view returns (bool) {
        return providers[provider];
    }

    function calculateBonus(uint256 characterId) external view returns (uint256) {
        uint256 totalBonus = 0;
        for (uint256 i = 0; i < providerCount; i++) {
            totalBonus += PROVIDER_BONUS;
        }
        return totalBonus;
    }
} 