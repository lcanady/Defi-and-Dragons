// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/Types.sol";

/// @title Party
/// @notice Manages character parties for group activities and quests
contract Party is Ownable, ReentrancyGuard {
    ICharacter public immutable character;

    struct PartyInfo {
        string name;
        uint256[] memberIds;
        address owner;
        bool active;
        uint256 maxSize;
    }

    // Party ID => Party Info
    mapping(bytes32 => PartyInfo) public parties;
    
    // Character ID => Active Party ID
    mapping(uint256 => bytes32) public characterParties;

    event PartyCreated(bytes32 indexed partyId, string name, address indexed owner);
    event MemberAdded(bytes32 indexed partyId, uint256 indexed characterId);
    event MemberRemoved(bytes32 indexed partyId, uint256 indexed characterId);
    event PartyDisbanded(bytes32 indexed partyId);

    constructor(address _character) Ownable(msg.sender) {
        character = ICharacter(_character);
    }

    /// @notice Create a new party
    function createParty(
        string calldata name,
        uint256[] calldata initialMembers,
        uint256 maxSize
    ) external nonReentrant returns (bytes32) {
        require(maxSize >= initialMembers.length && maxSize <= 10, "Invalid party size");
        require(initialMembers.length > 0, "Empty party");

        // Verify ownership of all initial members
        for (uint256 i = 0; i < initialMembers.length; i++) {
            require(character.ownerOf(initialMembers[i]) == msg.sender, "Not character owner");
            require(characterParties[initialMembers[i]] == bytes32(0), "Character in party");
        }

        bytes32 partyId = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        
        parties[partyId] = PartyInfo({
            name: name,
            memberIds: initialMembers,
            owner: msg.sender,
            active: true,
            maxSize: maxSize
        });

        // Register characters to party
        for (uint256 i = 0; i < initialMembers.length; i++) {
            characterParties[initialMembers[i]] = partyId;
        }

        emit PartyCreated(partyId, name, msg.sender);
        return partyId;
    }

    /// @notice Add a member to a party
    function addMember(bytes32 partyId, uint256 characterId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        require(party.active, "Party not active");
        require(party.owner == msg.sender, "Not party owner");
        require(party.memberIds.length < party.maxSize, "Party full");
        require(character.ownerOf(characterId) == msg.sender, "Not character owner");
        require(characterParties[characterId] == bytes32(0), "Character in party");

        party.memberIds.push(characterId);
        characterParties[characterId] = partyId;

        emit MemberAdded(partyId, characterId);
    }

    /// @notice Remove a member from a party
    function removeMember(bytes32 partyId, uint256 characterId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        require(party.active, "Party not active");
        require(party.owner == msg.sender || character.ownerOf(characterId) == msg.sender, "Not authorized");

        // Find and remove member
        bool found = false;
        uint256[] memory newMembers = new uint256[](party.memberIds.length - 1);
        uint256 j = 0;
        
        for (uint256 i = 0; i < party.memberIds.length; i++) {
            if (party.memberIds[i] != characterId) {
                if (j < newMembers.length) {
                    newMembers[j] = party.memberIds[i];
                    j++;
                }
            } else {
                found = true;
            }
        }

        require(found, "Character not in party");

        party.memberIds = newMembers;
        characterParties[characterId] = bytes32(0);

        emit MemberRemoved(partyId, characterId);
    }

    /// @notice Disband a party
    function disbandParty(bytes32 partyId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        require(party.active, "Party not active");
        require(party.owner == msg.sender, "Not party owner");

        // Clear character party mappings
        for (uint256 i = 0; i < party.memberIds.length; i++) {
            characterParties[party.memberIds[i]] = bytes32(0);
        }

        party.active = false;
        emit PartyDisbanded(partyId);
    }

    /// @notice Get party members
    function getPartyMembers(bytes32 partyId) external view returns (uint256[] memory) {
        return parties[partyId].memberIds;
    }

    /// @notice Check if a character is in a party
    function isInParty(uint256 characterId) external view returns (bool) {
        return characterParties[characterId] != bytes32(0);
    }

    /// @notice Get a character's current party
    function getCharacterParty(uint256 characterId) external view returns (bytes32) {
        return characterParties[characterId];
    }

    /// @notice Get party info
    function getPartyInfo(bytes32 partyId) external view returns (
        string memory name,
        uint256[] memory memberIds,
        address owner,
        bool active,
        uint256 maxSize
    ) {
        PartyInfo storage party = parties[partyId];
        return (
            party.name,
            party.memberIds,
            party.owner,
            party.active,
            party.maxSize
        );
    }
} 