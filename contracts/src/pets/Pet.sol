// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Types.sol";
import "../interfaces/IAttributeProvider.sol";
import "../Character.sol";

/// @title Pet
/// @notice NFT contract for pets that provide boosts to characters
contract Pet is ERC721, Ownable, IAttributeProvider {
    // Pet rarity tiers
    enum Rarity {
        COMMON, // 10% boost
        UNCOMMON, // 20% boost
        RARE, // 30% boost
        EPIC, // 40% boost
        LEGENDARY // 50% boost

    }

    struct PetData {
        string name;
        string description;
        Rarity rarity;
        uint256 yieldBoostBps; // Yield boost in basis points (e.g., 1000 = 10%)
        uint256 dropRateBoostBps; // Drop rate boost in basis points
        uint256 requiredLevel; // Character level required to own this pet
        bool isActive;
    }

    // Storage
    mapping(uint256 => PetData) public pets;
    mapping(uint256 => uint256) public characterToPet; // characterId => petId
    mapping(uint256 => bool) private _characterHasPet; // Track if character has any pet assigned
    mapping(uint256 => bool) private _existsMap; // Track if pet exists
    mapping(uint256 => uint256) private _mintedPetToType; // Minted pet ID to pet type ID mapping
    uint256 private _nextPetTypeId;
    uint256 private _nextTokenId;

    // Character contract reference
    Character public immutable characterContract;

    // Constants
    uint256 public constant MAX_BOOST = 5000; // 50% in basis points

    // Events
    event PetCreated(uint256 indexed petId, string name, Rarity rarity);
    event PetAssigned(uint256 indexed characterId, uint256 indexed petId);
    event PetUnassigned(uint256 indexed characterId, uint256 indexed petId);
    event PetActivated(uint256 indexed petId);
    event PetDeactivated(uint256 indexed petId);

    // Errors
    error PetNotActive();
    error InsufficientLevel();
    error AlreadyHasPet();
    error NotCharacterOwner();
    error BoostTooHigh();
    error NoPetAssigned();

    constructor(address _characterContract) ERC721("Game Pet", "PET") Ownable(msg.sender) {
        characterContract = Character(_characterContract);
        _nextPetTypeId = 1_000_000;
        _nextTokenId = 1;
    }

    /// @notice Check if a pet exists
    function _exists(uint256 petId) internal view returns (bool) {
        return _existsMap[petId];
    }

    /// @notice Create a new pet type
    function createPet(
        string memory name,
        string memory description,
        Rarity rarity,
        uint256 yieldBoost,
        uint256 dropRateBoost,
        uint256 requiredLevel
    ) external onlyOwner returns (uint256) {
        // Validate boost values
        if (yieldBoost > MAX_BOOST) revert BoostTooHigh();
        if (dropRateBoost > MAX_BOOST) revert BoostTooHigh();

        uint256 petTypeId = _nextPetTypeId++;
        pets[petTypeId] = PetData({
            name: name,
            description: description,
            rarity: rarity,
            yieldBoostBps: yieldBoost,
            dropRateBoostBps: dropRateBoost,
            requiredLevel: requiredLevel,
            isActive: true
        });

        _existsMap[petTypeId] = true;
        emit PetCreated(petTypeId, name, rarity);
        return petTypeId;
    }

    /// @notice Mint a pet to a character
    function mintPet(uint256 characterId, uint256 petTypeId) external {
        // Check if pet type exists and is active
        if (!_exists(petTypeId)) revert PetNotActive(); // Pet type doesn't exist

        PetData memory petData = pets[petTypeId];
        if (!petData.isActive) revert PetNotActive();

        // Verify ownership and level requirements
        address owner = characterContract.ownerOf(characterId);
        require(msg.sender == owner, "Not character owner");

        (,, Types.CharacterState memory state) = characterContract.getCharacter(characterId);
        require(state.level >= petData.requiredLevel, "Insufficient level");

        // Check if character already has a pet
        if (_characterHasPet[characterId]) {
            revert AlreadyHasPet();
        }

        // Mint the pet to the character's wallet with a new token ID
        address characterWallet = address(characterContract.characterWallets(characterId));
        require(characterWallet != address(0), "Invalid character wallet");
        uint256 tokenId = _nextTokenId++;
        _mint(characterWallet, tokenId);

        // Store the mapping between minted token ID and pet type
        _mintedPetToType[tokenId] = petTypeId;

        // Assign the pet to the character using the token ID
        characterToPet[characterId] = tokenId;
        _characterHasPet[characterId] = true;

        emit PetAssigned(characterId, tokenId);
    }

    /// @notice Unassign a pet from a character
    function unassignPet(uint256 characterId) external {
        uint256 tokenId = characterToPet[characterId];
        if (!_characterHasPet[characterId]) revert NoPetAssigned();
        if (characterContract.ownerOf(characterId) != msg.sender) revert NotCharacterOwner();

        address characterWallet = address(characterContract.characterWallets(characterId));
        require(characterWallet != address(0), "Invalid character wallet");
        require(ownerOf(tokenId) == characterWallet, "Pet not owned by character wallet");

        // Update state before burning to prevent reentrancy
        characterToPet[characterId] = 0;
        _characterHasPet[characterId] = false;
        delete _mintedPetToType[tokenId];
        _burn(tokenId);

        emit PetUnassigned(characterId, tokenId);
    }

    /// @notice Check if a character has an active pet
    function hasActivePet(uint256 characterId) public view returns (bool) {
        uint256 tokenId = characterToPet[characterId];
        if (tokenId == 0) return false;

        uint256 petTypeId = _mintedPetToType[tokenId];
        if (!_exists(petTypeId)) return false;

        address wallet = address(characterContract.characterWallets(characterId));
        return pets[petTypeId].isActive && ownerOf(tokenId) == wallet;
    }

    /// @notice Get pet benefits for a character
    function getPetBenefits(uint256 characterId) public view returns (uint256 yieldBoost, uint256 dropRateBoost) {
        uint256 tokenId = characterToPet[characterId];
        if (tokenId == 0) return (0, 0);

        uint256 petTypeId = _mintedPetToType[tokenId];
        if (!_exists(petTypeId) || !pets[petTypeId].isActive) return (0, 0);

        PetData memory pet = pets[petTypeId];
        return (pet.yieldBoostBps, pet.dropRateBoostBps);
    }

    /// @notice Get a pet's rarity
    function getPetRarity(uint256 tokenId) external view returns (Rarity) {
        uint256 petTypeId = _mintedPetToType[tokenId];
        return pets[petTypeId].rarity;
    }

    /// @notice Deactivate a pet type
    function deactivatePet(uint256 petTypeId) external onlyOwner {
        pets[petTypeId].isActive = false;
        emit PetDeactivated(petTypeId);
    }

    /// @notice Activate a pet type
    function activatePet(uint256 petTypeId) external onlyOwner {
        pets[petTypeId].isActive = true;
        emit PetActivated(petTypeId);
    }

    /// @inheritdoc IAttributeProvider
    function getBonus(uint256 characterId) external view override returns (uint256) {
        if (!hasActivePet(characterId)) return 0;
        (uint256 yieldBoost,) = getPetBenefits(characterId);
        return yieldBoost;
    }

    /// @inheritdoc IAttributeProvider
    function isActive(uint256 characterId) external view override returns (bool) {
        return hasActivePet(characterId);
    }
}
