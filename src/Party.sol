// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/Types.sol";
import "./interfaces/Errors.sol";

/// @title Party
/// @notice Manages character parties for group activities and quests
contract Party is Ownable, ReentrancyGuard {
    ICharacter public immutable character;

    struct PartyInfo {
        string name;
        uint256[] memberIds; // Can't reduce size as these are NFT IDs
        address owner;
        bool active;
        uint8 maxSize; // Reduced from uint256, max is 10
        uint8 memberCount; // Track count separately for gas optimization
    }

    // Party ID => Party Info
    mapping(bytes32 => PartyInfo) public parties;

    // Character ID => Active Party ID
    mapping(uint256 => bytes32) public characterParties;

    // Party ID => Member existence mapping for O(1) lookups
    mapping(bytes32 => mapping(uint256 => bool)) private partyMembership;

    event PartyCreated(bytes32 indexed partyId, string name, address indexed owner);
    event MemberAdded(bytes32 indexed partyId, uint256 indexed characterId);
    event MemberRemoved(bytes32 indexed partyId, uint256 indexed characterId);
    event PartyDisbanded(bytes32 indexed partyId);

    constructor(address _character) Ownable() {
        character = ICharacter(_character);
        _transferOwnership(msg.sender);
    }

    /// @notice Create a new party
    function createParty(
        string calldata name,
        uint256[] calldata initialMembers,
        uint8 maxSize // Changed to uint8
    ) external nonReentrant returns (bytes32) {
        uint256 memberCount = initialMembers.length;
        if (maxSize < memberCount || maxSize > 10) revert InvalidPartySize();
        if (memberCount == 0) revert EmptyParty();

        // Verify ownership of all initial members
        unchecked {
            // Safe because we already checked length > 0 and array access is bounds checked
            for (uint256 i; i < memberCount; ++i) {
                if (character.ownerOf(initialMembers[i]) != msg.sender) revert NotCharacterOwner();
                if (characterParties[initialMembers[i]] != bytes32(0)) revert CharacterInParty();
            }
        }

        bytes32 partyId = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));

        // Store party info
        parties[partyId].name = name;
        parties[partyId].memberIds = initialMembers;
        parties[partyId].owner = msg.sender;
        parties[partyId].active = true;
        parties[partyId].maxSize = maxSize;
        parties[partyId].memberCount = uint8(memberCount);

        // Register characters to party
        unchecked {
            for (uint256 i; i < memberCount; ++i) {
                uint256 memberId = initialMembers[i];
                characterParties[memberId] = partyId;
                partyMembership[partyId][memberId] = true;
            }
        }

        emit PartyCreated(partyId, name, msg.sender);
        return partyId;
    }

    /// @notice Add a member to a party
    function addMember(bytes32 partyId, uint256 characterId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        if (!party.active) revert PartyNotActive();
        if (party.owner != msg.sender) revert NotPartyOwner();
        if (party.memberCount >= party.maxSize) revert PartyFull();
        if (character.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();
        if (characterParties[characterId] != bytes32(0)) revert CharacterInParty();

        party.memberIds.push(characterId);
        characterParties[characterId] = partyId;
        partyMembership[partyId][characterId] = true;
        unchecked {
            ++party.memberCount;
        }

        emit MemberAdded(partyId, characterId);
    }

    /// @notice Remove a member from a party
    function removeMember(bytes32 partyId, uint256 characterId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        if (!party.active) revert PartyNotActive();
        if (party.owner != msg.sender && character.ownerOf(characterId) != msg.sender) revert NotAuthorized();
        if (!partyMembership[partyId][characterId]) revert CharacterNotInParty();

        // Remove member efficiently using swap and pop
        uint256[] storage members = party.memberIds;
        uint256 len = members.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                if (members[i] == characterId) {
                    if (i != len - 1) {
                        members[i] = members[len - 1];
                    }
                    members.pop();
                    break;
                }
            }
        }

        characterParties[characterId] = bytes32(0);
        partyMembership[partyId][characterId] = false;
        unchecked {
            --party.memberCount;
        }

        emit MemberRemoved(partyId, characterId);
    }

    /// @notice Disband a party
    function disbandParty(bytes32 partyId) external nonReentrant {
        PartyInfo storage party = parties[partyId];
        if (!party.active) revert PartyNotActive();
        if (party.owner != msg.sender) revert NotPartyOwner();

        // Clear character party mappings
        uint256[] memory members = party.memberIds;
        uint256 len = members.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                uint256 memberId = members[i];
                characterParties[memberId] = bytes32(0);
                partyMembership[partyId][memberId] = false;
            }
        }

        party.active = false;
        party.memberCount = 0;
        delete party.memberIds;

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

    /// @notice Check if a character is in a specific party
    function isInSpecificParty(bytes32 partyId, uint256 characterId) external view returns (bool) {
        return partyMembership[partyId][characterId];
    }

    /// @notice Get party info
    function getPartyInfo(bytes32 partyId)
        external
        view
        returns (string memory name, uint256[] memory memberIds, address owner, bool active, uint8 maxSize)
    {
        PartyInfo storage party = parties[partyId];
        return (party.name, party.memberIds, party.owner, party.active, party.maxSize);
    }
}
