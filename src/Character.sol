// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Errors.sol";
import "./CharacterWallet.sol";
import "./ProvableRandom.sol";

/// @title Character
/// @notice Core contract for character NFTs and their attributes
contract Character is ERC721, Ownable, ICharacter {
    using Math for uint256;

    // State variables - packed for gas optimization
    struct PackedStats {
        uint64 strength; // Reduced from uint256 since max is 18
        uint64 agility; // Reduced from uint256 since max is 18
        uint64 magic; // Reduced from uint256 since max is 18
        uint64 reserved; // For future use, maintains packing
    }

    struct PackedState {
        uint64 health; // Reduced from uint256, 100 max
        uint32 consecutiveHits; // Reduced from uint256
        uint32 damageReceived; // Reduced from uint256
        uint32 roundsParticipated; // Reduced from uint256
        uint8 level; // Reduced from uint256, 1-255 sufficient
        Types.Alignment alignment; // Already small enum
        uint8 reserved; // For future use, maintains packing
    }

    mapping(uint256 => PackedStats) public characterStats;
    mapping(uint256 => PackedState) public characterStates;
    mapping(uint256 => CharacterWallet) public characterWallets;

    uint64 private _nextTokenId; // Reduced from uint256, supports plenty of characters
    IEquipment private immutable equipment;
    ProvableRandom private immutable provableRandom;

    // Constants for stat generation
    uint8 public constant MIN_STAT = 5; // Reduced from uint256
    uint8 public constant MAX_STAT = 18; // Reduced from uint256
    uint8 public constant TOTAL_POINTS = 45; // Reduced from uint256

    // Events - indexed where useful for filtering
    event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, uint64 strength, uint64 agility, uint64 magic);
    event StateUpdated(uint256 indexed tokenId, PackedState state);

    constructor(address _equipmentContract, address _provableRandom) ERC721("DnD Character", "DNDC") Ownable() {
        equipment = IEquipment(_equipmentContract);
        provableRandom = ProvableRandom(_provableRandom);
        _transferOwnership(msg.sender);
    }

    function getCharacter(uint256 tokenId)
        external
        view
        returns (
            Types.Stats memory stats,
            Types.EquipmentSlots memory equipmentSlots,
            Types.CharacterState memory state
        )
    {
        return getCharacterInfo(tokenId);
    }

    function getCharacterInfo(uint256 tokenId)
        public
        view
        returns (
            Types.Stats memory stats,
            Types.EquipmentSlots memory equipmentSlots,
            Types.CharacterState memory state
        )
    {
        if (!_exists(tokenId)) revert CharacterNotFound();

        // Convert packed stats to return format
        PackedStats memory packed = characterStats[tokenId];
        stats.strength = packed.strength;
        stats.agility = packed.agility;
        stats.magic = packed.magic;

        // Convert packed state to return format
        PackedState memory packedState = characterStates[tokenId];
        state.health = packedState.health;
        state.consecutiveHits = packedState.consecutiveHits;
        state.damageReceived = packedState.damageReceived;
        state.roundsParticipated = packedState.roundsParticipated;
        state.alignment = packedState.alignment;
        state.level = packedState.level;

        return (stats, characterWallets[tokenId].getEquippedItems(), state);
    }

    function mintCharacter(address to, Types.Alignment alignment) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Reset and initialize random seed for character creation
        bytes32 context = bytes32(uint256(uint160(address(this))));
        provableRandom.resetSeed(to, context);
        provableRandom.initializeSeed(to, context);

        // Generate random numbers for character attributes
        uint256[] memory randomNumbers = provableRandom.generateNumbers(to, context, 3);

        // Scale the random numbers to our stat range
        uint64 strength = uint64((randomNumbers[0] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT);
        uint64 agility = uint64((randomNumbers[1] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT);
        uint64 magic = uint64((randomNumbers[2] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT);

        // Adjust stats to meet total points requirement
        unchecked {
            // Safe because max possible total is 3 * MAX_STAT which is well within uint64
            uint64 total = strength + agility + magic;

            if (total != TOTAL_POINTS) {
                if (total > TOTAL_POINTS) {
                    // Reduce stats proportionally
                    strength = uint64((uint256(strength) * TOTAL_POINTS) / total);
                    agility = uint64((uint256(agility) * TOTAL_POINTS) / total);
                    magic = uint64((uint256(magic) * TOTAL_POINTS) / total);

                    // Add any remaining points due to rounding
                    total = strength + agility + magic;
                    if (total < TOTAL_POINTS) {
                        strength += uint64(TOTAL_POINTS - total);
                    }
                } else {
                    // Add remaining points based on alignment
                    uint64 diff = TOTAL_POINTS - total;

                    if (alignment == Types.Alignment.STRENGTH && strength + diff <= MAX_STAT) {
                        strength += diff;
                    } else if (alignment == Types.Alignment.AGILITY && agility + diff <= MAX_STAT) {
                        agility += diff;
                    } else if (alignment == Types.Alignment.MAGIC && magic + diff <= MAX_STAT) {
                        magic += diff;
                    } else {
                        // Distribute remaining points evenly if max stat would be exceeded
                        uint64 remaining = diff;
                        uint64 share = remaining / 3;
                        strength += share;
                        agility += share;
                        magic += remaining - (2 * share); // Remainder goes to magic
                    }
                }
            }
        }

        // Store packed stats
        characterStats[tokenId] = PackedStats({ strength: strength, agility: agility, magic: magic, reserved: 0 });

        // Create character wallet
        CharacterWallet wallet = new CharacterWallet(address(equipment), tokenId, address(this));
        characterWallets[tokenId] = wallet;

        // Initialize packed character state
        characterStates[tokenId] = PackedState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: alignment,
            level: 1,
            reserved: 0
        });

        emit CharacterCreated(tokenId, to, address(wallet));
        return tokenId;
    }

    function equip(uint256 tokenId, uint256 weaponId, uint256 armorId) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotCharacterOwner();
        if (!_exists(tokenId)) revert CharacterNotFound();

        CharacterWallet wallet = characterWallets[tokenId];
        wallet.equip(weaponId, armorId);

        emit EquipmentChanged(tokenId, weaponId, armorId);
    }

    function unequip(uint256 tokenId, bool weapon, bool armor) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotCharacterOwner();
        if (!_exists(tokenId)) revert CharacterNotFound();

        CharacterWallet wallet = characterWallets[tokenId];
        wallet.unequip(weapon, armor);

        emit EquipmentChanged(tokenId, 0, 0);
    }

    function updateStats(uint256 tokenId, Types.Stats memory newStats) external onlyOwner {
        if (!_exists(tokenId)) revert CharacterNotFound();

        // Convert and store as packed stats
        characterStats[tokenId] = PackedStats({
            strength: uint64(newStats.strength),
            agility: uint64(newStats.agility),
            magic: uint64(newStats.magic),
            reserved: 0
        });

        emit StatsUpdated(tokenId, uint64(newStats.strength), uint64(newStats.agility), uint64(newStats.magic));
    }

    function updateState(uint256 tokenId, Types.CharacterState memory newState) external onlyOwner {
        if (!_exists(tokenId)) revert CharacterNotFound();

        // Convert and store as packed state
        PackedState memory packedState = PackedState({
            health: uint64(newState.health),
            consecutiveHits: uint32(newState.consecutiveHits),
            damageReceived: uint32(newState.damageReceived),
            roundsParticipated: uint32(newState.roundsParticipated),
            alignment: newState.alignment,
            level: uint8(newState.level),
            reserved: 0
        });

        characterStates[tokenId] = packedState;
        emit StateUpdated(tokenId, packedState);
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return super._exists(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
