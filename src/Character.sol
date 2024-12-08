// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IEquipment.sol";

contract Character is ERC721, Ownable, ICharacter {
    // State variables
    mapping(uint256 => Types.Stats) public characterStats;
    mapping(uint256 => Types.EquipmentSlots) public characterEquipment;
    mapping(uint256 => Types.CharacterState) public characterStates;

    uint256 private _nextTokenId;
    IEquipment private equipmentContract;

    // Events
    event CharacterCreated(uint256 indexed tokenId, address indexed owner);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, Types.Stats stats);
    event StateUpdated(uint256 indexed tokenId, Types.CharacterState state);

    constructor(address _equipmentContract) ERC721("DnD Character", "DNDC") Ownable(msg.sender) {
        equipmentContract = IEquipment(_equipmentContract);
    }

    // Implementation of ICharacter interface
    function getCharacter(uint256 tokenId)
        external
        view
        returns (Types.Stats memory stats, Types.EquipmentSlots memory equipment, Types.CharacterState memory state)
    {
        require(_exists(tokenId), "Character does not exist");
        return (characterStats[tokenId], characterEquipment[tokenId], characterStates[tokenId]);
    }

    // Character creation
    function mintCharacter(address to, Types.Stats memory initialStats, Types.Alignment alignment)
        external
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize character with provided stats
        characterStats[tokenId] = initialStats;

        // Initialize empty equipment slots
        characterEquipment[tokenId] = Types.EquipmentSlots({ weaponId: 0, armorId: 0 });

        // Initialize character state
        characterStates[tokenId] = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: alignment
        });

        emit CharacterCreated(tokenId, to);
        return tokenId;
    }

    // Equipment management
    function equip(uint256 tokenId, uint256 weaponId, uint256 armorId) external {
        require(_ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender, "Not owner or approved");
        require(_exists(tokenId), "Character does not exist");

        // Check if the caller owns the equipment
        if (weaponId > 0) {
            require(equipmentContract.balanceOf(msg.sender, weaponId) > 0, "Don't own weapon");
        }
        if (armorId > 0) {
            require(equipmentContract.balanceOf(msg.sender, armorId) > 0, "Don't own armor");
        }

        characterEquipment[tokenId].weaponId = weaponId;
        characterEquipment[tokenId].armorId = armorId;

        emit EquipmentChanged(tokenId, weaponId, armorId);
    }

    // Update character stats
    function updateStats(uint256 tokenId, Types.Stats memory newStats) external onlyOwner {
        require(_exists(tokenId), "Character does not exist");
        characterStats[tokenId] = newStats;
        emit StatsUpdated(tokenId, newStats);
    }

    // Update character state
    function updateState(uint256 tokenId, Types.CharacterState memory newState) external onlyOwner {
        require(_exists(tokenId), "Character does not exist");
        characterStates[tokenId] = newState;
        emit StateUpdated(tokenId, newState);
    }

    // Internal helper functions
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
