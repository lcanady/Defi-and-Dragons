// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/IEquipment.sol";
import "./CharacterWallet.sol";

contract Character is ERC721, Ownable, ICharacter {
    // State variables
    mapping(uint256 => Types.Stats) public characterStats;
    mapping(uint256 => Types.CharacterState) public characterStates;
    mapping(uint256 => CharacterWallet) public characterWallets;
    
    uint256 private _nextTokenId;
    IEquipment private immutable equipmentContract;

    // Events
    event CharacterCreated(uint256 indexed tokenId, address indexed owner, address wallet);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId);
    event StatsUpdated(uint256 indexed tokenId, Types.Stats stats);
    event StateUpdated(uint256 indexed tokenId, Types.CharacterState state);

    constructor(address _equipmentContract) ERC721("DnD Character", "DNDC") Ownable(msg.sender) {
        equipmentContract = IEquipment(_equipmentContract);
    }

    function getCharacter(uint256 tokenId) external view returns (
        Types.Stats memory stats,
        Types.EquipmentSlots memory equipment,
        Types.CharacterState memory state
    ) {
        require(_exists(tokenId), "Character does not exist");
        return (
            characterStats[tokenId],
            characterWallets[tokenId].getEquippedItems(),
            characterStates[tokenId]
        );
    }

    function mintCharacter(
        address to,
        Types.Stats memory initialStats,
        Types.Alignment alignment
    ) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize character with provided stats
        characterStats[tokenId] = initialStats;

        // Create character wallet
        CharacterWallet wallet = new CharacterWallet(
            address(equipmentContract),
            tokenId,
            address(this),
            to
        );
        characterWallets[tokenId] = wallet;

        // Initialize character state
        characterStates[tokenId] = Types.CharacterState({
            health: 100,
            consecutiveHits: 0,
            damageReceived: 0,
            roundsParticipated: 0,
            alignment: alignment
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

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        address previousOwner = super._update(to, tokenId, auth);

        // Transfer wallet ownership when character is transferred
        if (from != address(0) && to != address(0)) {  // Skip mint and burn
            CharacterWallet wallet = characterWallets[tokenId];
            wallet.transferOwnership(to);
        }

        return previousOwner;
    }
}
