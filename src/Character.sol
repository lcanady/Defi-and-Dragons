// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IEquipment.sol";
import "./CharacterWallet.sol";
import "./ProvableRandom.sol";

contract Character is ERC721, Ownable, ICharacter {
    // State variables
    mapping(uint256 => Types.Stats) public characterStats;
    mapping(uint256 => Types.CharacterState) public characterStates;
    mapping(uint256 => CharacterWallet) public characterWallets;

    uint256 private _nextTokenId;
    IEquipment private immutable equipmentContract;
    ProvableRandom private immutable randomGenerator;

    // Constants for stat generation
    uint256 public constant MIN_STAT = 5;  // Minimum value for each stat
    uint256 public constant MAX_STAT = 18; // Maximum value for each stat
    uint256 public constant TOTAL_POINTS = 45; // Total points to allocate across stats

    // Events
    event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, Types.Stats stats);
    event StateUpdated(uint256 indexed tokenId, Types.CharacterState state);

    constructor(address _equipmentContract, address _randomGenerator) ERC721("DnD Character", "DNDC") Ownable(msg.sender) {
        equipmentContract = IEquipment(_equipmentContract);
        randomGenerator = ProvableRandom(_randomGenerator);
    }

    function getCharacter(uint256 tokenId)
        external
        view
        returns (Types.Stats memory stats, Types.EquipmentSlots memory equipment, Types.CharacterState memory state)
    {
        require(_exists(tokenId), "Character does not exist");
        return (characterStats[tokenId], characterWallets[tokenId].getEquippedItems(), characterStates[tokenId]);
    }

    function mintCharacter(address to, Types.Alignment alignment)
        external
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize random seed for this character if not already done
        if (randomGenerator.getCurrentSeed(to) == bytes32(0)) {
            randomGenerator.initializeSeed(keccak256(abi.encodePacked(block.timestamp, to, tokenId)));
        }

        // Generate random stats
        uint256[] memory randomNumbers = randomGenerator.generateNumbers(3); // Get 3 random numbers
        
        // Scale the random numbers to our stat range and ensure total equals TOTAL_POINTS
        uint256 strength = (randomNumbers[0] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT;
        uint256 agility = (randomNumbers[1] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT;
        uint256 magic = (randomNumbers[2] % (MAX_STAT - MIN_STAT + 1)) + MIN_STAT;
        
        // Adjust stats to meet total points requirement
        uint256 total = strength + agility + magic;
        if (total != TOTAL_POINTS) {
            uint256 diff = total > TOTAL_POINTS ? 
                total - TOTAL_POINTS : 
                TOTAL_POINTS - total;
                
            if (total > TOTAL_POINTS) {
                // Reduce stats proportionally
                strength = strength * TOTAL_POINTS / total;
                agility = agility * TOTAL_POINTS / total;
                magic = magic * TOTAL_POINTS / total;
                
                // Add any remaining points due to rounding
                uint256 finalTotal = strength + agility + magic;
                if (finalTotal < TOTAL_POINTS) {
                    strength += TOTAL_POINTS - finalTotal;
                }
            } else {
                // Add remaining points to the stat matching alignment, ensuring we don't exceed MAX_STAT
                if (alignment == Types.Alignment.STRENGTH) {
                    if (strength + diff > MAX_STAT) {
                        // Distribute remaining points to other stats
                        uint256 remaining = strength + diff - MAX_STAT;
                        strength = MAX_STAT;
                        // Distribute remaining points evenly
                        uint256 halfRemaining = remaining / 2;
                        agility += halfRemaining;
                        magic += remaining - halfRemaining;
                    } else {
                        strength += diff;
                    }
                } else if (alignment == Types.Alignment.AGILITY) {
                    if (agility + diff > MAX_STAT) {
                        // Distribute remaining points to other stats
                        uint256 remaining = agility + diff - MAX_STAT;
                        agility = MAX_STAT;
                        // Distribute remaining points evenly
                        uint256 halfRemaining = remaining / 2;
                        strength += halfRemaining;
                        magic += remaining - halfRemaining;
                    } else {
                        agility += diff;
                    }
                } else {
                    if (magic + diff > MAX_STAT) {
                        // Distribute remaining points to other stats
                        uint256 remaining = magic + diff - MAX_STAT;
                        magic = MAX_STAT;
                        // Distribute remaining points evenly
                        uint256 halfRemaining = remaining / 2;
                        strength += halfRemaining;
                        agility += remaining - halfRemaining;
                    } else {
                        magic += diff;
                    }
                }
            }
        }

        // Initialize character with generated stats
        characterStats[tokenId] = Types.Stats({
            strength: strength,
            agility: agility,
            magic: magic
        });

        // Create character wallet
        CharacterWallet wallet = new CharacterWallet(address(equipmentContract), tokenId, address(this));
        characterWallets[tokenId] = wallet;

        // Initialize character state
        characterStates[tokenId] = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: alignment,
            level: 1
        });

        emit CharacterCreated(tokenId, to, address(wallet));
        return tokenId;
    }

    function equip(uint256 tokenId, uint256 weaponId, uint256 armorId) external {
        require(_ownerOf(tokenId) == msg.sender, "Not character owner");
        require(_exists(tokenId), "Character does not exist");

        CharacterWallet wallet = characterWallets[tokenId];
        wallet.equip(weaponId, armorId);

        emit EquipmentChanged(tokenId, weaponId, armorId);
    }

    function unequip(uint256 tokenId, bool weapon, bool armor) external {
        require(_ownerOf(tokenId) == msg.sender, "Not character owner");
        require(_exists(tokenId), "Character does not exist");

        CharacterWallet wallet = characterWallets[tokenId];
        wallet.unequip(weapon, armor);

        emit EquipmentChanged(tokenId, 0, 0);
    }

    function updateStats(uint256 tokenId, Types.Stats memory newStats) external onlyOwner {
        require(_exists(tokenId), "Character does not exist");
        characterStats[tokenId] = newStats;
        emit StatsUpdated(tokenId, newStats);
    }

    function updateState(uint256 tokenId, Types.CharacterState memory newState) external onlyOwner {
        require(_exists(tokenId), "Character does not exist");
        characterStates[tokenId] = newState;
        emit StateUpdated(tokenId, newState);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        address previousOwner = super._update(to, tokenId, auth);

        // Transfer wallet ownership when character is transferred
        if (from != address(0) && to != address(0)) {
            // Skip mint and burn
            CharacterWallet wallet = characterWallets[tokenId];
            wallet.transferOwnership(to);
        }

        return previousOwner;
    }
}
