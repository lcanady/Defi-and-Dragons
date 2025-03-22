// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IAttributeProvider.sol";

/// @title Mock Attribute Provider
/// @notice A mock contract implementing IAttributeProvider for testing purposes
contract MockAttributeProvider is IAttributeProvider {
    mapping(uint256 => uint256) private _characterBonuses;
    mapping(uint256 => bool) private _activeForCharacter;
    uint256 private _defaultBonus;
    bool private _globalActive;

    constructor(uint256 defaultBonus_) {
        _defaultBonus = defaultBonus_;
        _globalActive = true;
    }

    /// @notice Get the bonus for a specific character
    /// @param characterId The ID of the character
    /// @return The bonus value in basis points (10000 = 100%)
    function getBonus(uint256 characterId) external view override returns (uint256) {
        // Return character-specific bonus if set, otherwise return default
        return _characterBonuses[characterId] == 0 ? _defaultBonus : _characterBonuses[characterId];
    }

    /// @notice Check if bonus is active for a character
    /// @param characterId The ID of the character
    /// @return Whether the bonus is active
    function isActive(uint256 characterId) external view override returns (bool) {
        return _globalActive && _activeForCharacter[characterId];
    }

    /// @notice Set a character-specific bonus
    /// @param characterId The ID of the character
    /// @param bonus The bonus value in basis points
    function setCharacterBonus(uint256 characterId, uint256 bonus) external {
        _characterBonuses[characterId] = bonus;
    }

    /// @notice Set the default bonus for characters without specific values
    /// @param bonus The default bonus value in basis points
    function setDefaultBonus(uint256 bonus) external {
        _defaultBonus = bonus;
    }

    /// @notice Set the global active state
    /// @param active The global active state
    function setGlobalActive(bool active) external {
        _globalActive = active;
    }

    /// @notice Set active state for a specific character
    /// @param characterId The ID of the character
    /// @param active Whether the bonus should be active
    function setActiveForCharacter(uint256 characterId, bool active) external {
        _activeForCharacter[characterId] = active;
    }

    /// @notice Batch set active state for multiple characters
    /// @param characterIds Array of character IDs
    /// @param active Whether the bonus should be active
    function batchSetActiveForCharacters(uint256[] calldata characterIds, bool active) external {
        for (uint256 i = 0; i < characterIds.length; i++) {
            _activeForCharacter[characterIds[i]] = active;
        }
    }

    /// @notice Batch set bonuses for multiple characters
    /// @param characterIds Array of character IDs
    /// @param bonuses Array of bonus values
    function batchSetCharacterBonuses(uint256[] calldata characterIds, uint256[] calldata bonuses) external {
        require(characterIds.length == bonuses.length, "MockAttributeProvider: Array lengths must match");

        for (uint256 i = 0; i < characterIds.length; i++) {
            _characterBonuses[characterIds[i]] = bonuses[i];
        }
    }

    /// @notice Reset all character-specific settings
    function reset() external {
        _globalActive = true;
        _defaultBonus = 0;
    }

    /// @notice Get the current default bonus value
    function getDefaultBonus() external view returns (uint256) {
        return _defaultBonus;
    }

    /// @notice Get the current global active state
    function getGlobalActive() external view returns (bool) {
        return _globalActive;
    }
}
