// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Character is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Character class options
    enum Class { WARRIOR, MAGE, ROGUE, CLERIC }

    // Base stats structure
    struct Stats {
        uint8 strength;
        uint8 dexterity;
        uint8 constitution;
        uint8 intelligence;
        uint8 wisdom;
        uint8 charisma;
        uint8 level;
        uint256 experience;
    }

    // Equipment slots structure
    struct Equipment {
        uint256 weaponId;
        uint256 armorId;
        uint256 shieldId;
        uint256 amuletId;
        uint256 ringId;
    }

    // Mapping from token ID to character details
    mapping(uint256 => Stats) public characterStats;
    mapping(uint256 => Class) public characterClass;
    mapping(uint256 => Equipment) public characterEquipment;

    // Events
    event CharacterMinted(address indexed owner, uint256 indexed tokenId, Class class);
    event StatsUpdated(uint256 indexed tokenId, Stats stats);
    event EquipmentUpdated(uint256 indexed tokenId, Equipment equipment);

    constructor() ERC721("DnD Character", "DNDC") Ownable(msg.sender) {}

    /**
     * @dev Mint a new character with specified class and base stats
     * @param to The address that will own the character
     * @param class The character's class
     * @param stats The character's initial stats
     */
    function mintCharacter(
        address to,
        Class class,
        Stats memory stats
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(to, newTokenId);
        characterClass[newTokenId] = class;
        characterStats[newTokenId] = stats;

        // Initialize empty equipment
        characterEquipment[newTokenId] = Equipment(0, 0, 0, 0, 0);

        emit CharacterMinted(to, newTokenId, class);
        emit StatsUpdated(newTokenId, stats);

        return newTokenId;
    }

    /**
     * @dev Update character's stats (restricted to owner or approved)
     * @param tokenId The character's token ID
     * @param stats The new stats
     */
    function updateStats(uint256 tokenId, Stats memory stats) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        characterStats[tokenId] = stats;
        emit StatsUpdated(tokenId, stats);
    }

    /**
     * @dev Update character's equipment (restricted to owner or approved)
     * @param tokenId The character's token ID
     * @param equipment The new equipment configuration
     */
    function updateEquipment(uint256 tokenId, Equipment memory equipment) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        characterEquipment[tokenId] = equipment;
        emit EquipmentUpdated(tokenId, equipment);
    }

    /**
     * @dev Get all character information
     * @param tokenId The character's token ID
     */
    function getCharacter(uint256 tokenId) public view returns (
        Class class,
        Stats memory stats,
        Equipment memory equipment
    ) {
        require(_exists(tokenId), "Character does not exist");
        return (
            characterClass[tokenId],
            characterStats[tokenId],
            characterEquipment[tokenId]
        );
    }
} 