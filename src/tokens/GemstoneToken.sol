// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

/**
 * @title GemstoneToken
 * @dev ERC20 token representing a rare Gemstone resource in DeFi & Dragons.
 * Minter role controlled by the ResourceFarm contract.
 */
contract GemstoneToken is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
} 