// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/ICharacter.sol";

/// @title Title
/// @notice Manages character titles and their associated benefits
contract Title is ERC721, Ownable {
    struct TitleData {
        string name;
        uint256 yieldBoostBps; // Yield boost in basis points (100 = 1%)
        uint256 feeReductionBps; // Fee reduction in basis points
        uint256 dropRateBoostBps; // Drop rate boost in basis points
        bool active;
    }

    struct CharacterTitle {
        uint256 titleId;
        uint256 timestamp;
        bool active;
    }

    // Title storage
    mapping(uint256 => TitleData) public titles;
    mapping(uint256 => CharacterTitle) public characterTitles; // characterId => CharacterTitle
    uint256 private _nextTitleId;

    // Character contract reference
    ICharacter public immutable characterContract;

    // Events
    event TitleCreated(
        uint256 indexed titleId, string name, uint256 yieldBoostBps, uint256 feeReductionBps, uint256 dropRateBoostBps
    );
    event TitleAssigned(uint256 indexed characterId, uint256 indexed titleId);
    event TitleRevoked(uint256 indexed characterId, uint256 indexed titleId);
    event TitleActivated(uint256 indexed titleId);
    event TitleDeactivated(uint256 indexed titleId);

    constructor(address _characterContract) ERC721("Character Title", "TITLE") {
        characterContract = ICharacter(_characterContract);
    }

    /// @notice Create a new title type
    function createTitle(string memory name, uint256 yieldBoostBps, uint256 feeReductionBps, uint256 dropRateBoostBps)
        external
        onlyOwner
        returns (uint256)
    {
        require(yieldBoostBps <= 10_000, "Yield boost too high"); // Max 100%
        require(feeReductionBps <= 10_000, "Fee reduction too high"); // Max 100%
        require(dropRateBoostBps <= 10_000, "Drop rate boost too high"); // Max 100%

        uint256 titleId = _nextTitleId++;
        titles[titleId] = TitleData({
            name: name,
            yieldBoostBps: yieldBoostBps,
            feeReductionBps: feeReductionBps,
            dropRateBoostBps: dropRateBoostBps,
            active: true
        });

        emit TitleCreated(titleId, name, yieldBoostBps, feeReductionBps, dropRateBoostBps);
        return titleId;
    }

    /// @notice Assign a title to a character
    function assignTitle(uint256 characterId, uint256 titleId) external {
        require(titles[titleId].active, "Title not active");
        require(
            characterContract.ownerOf(characterId) == msg.sender || owner() == msg.sender,
            "Not character owner or contract owner"
        );

        characterTitles[characterId] = CharacterTitle({ titleId: titleId, timestamp: block.timestamp, active: true });

        emit TitleAssigned(characterId, titleId);
    }

    /// @notice Revoke a title from a character
    function revokeTitle(uint256 characterId) external onlyOwner {
        require(characterTitles[characterId].active, "No active title");

        uint256 titleId = characterTitles[characterId].titleId;
        characterTitles[characterId].active = false;

        emit TitleRevoked(characterId, titleId);
    }

    /// @notice Get character's title benefits
    function getTitleBenefits(uint256 characterId) external view returns (uint256, uint256, uint256) {
        CharacterTitle memory charTitle = characterTitles[characterId];
        if (!charTitle.active) return (0, 0, 0);

        TitleData memory title = titles[charTitle.titleId];
        if (!title.active) return (0, 0, 0);

        return (title.yieldBoostBps, title.feeReductionBps, title.dropRateBoostBps);
    }

    /// @notice Check if a character has an active title
    function hasActiveTitle(uint256 characterId) external view returns (bool) {
        return characterTitles[characterId].active && titles[characterTitles[characterId].titleId].active;
    }

    /// @notice Deactivate a title type
    function deactivateTitle(uint256 titleId) external onlyOwner {
        require(titles[titleId].active, "Title already inactive");
        titles[titleId].active = false;
        emit TitleDeactivated(titleId);
    }

    /// @notice Activate a title type
    function activateTitle(uint256 titleId) external onlyOwner {
        require(!titles[titleId].active, "Title already active");
        titles[titleId].active = true;
        emit TitleActivated(titleId);
    }
}
