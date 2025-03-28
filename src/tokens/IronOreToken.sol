// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

/**
 * @title IronOreToken
 * @dev ERC20 token representing Iron Ore resource in DeFi & Dragons.
 * Minter role controlled by the ResourceFarm contract.
 */
contract IronOreToken is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        // Grant the deployer the default admin role initially
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant the deployer the minter role initially (to be transferred to ResourceFarm)
        _grantRole(MINTER_ROLE, msg.sender);
        // Grant the deployer the pauser role initially
        _grantRole(PAUSER_ROLE, msg.sender);
    }
} 