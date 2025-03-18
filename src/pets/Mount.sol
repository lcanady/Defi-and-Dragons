// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Types.sol";
import "../interfaces/IAttributeProvider.sol";
import "../Character.sol";

/// @title Mount
/// @notice NFT contract for mounts that provide travel and economic benefits
contract Mount is ERC721, Ownable, IAttributeProvider {
    // Custom errors
    error BoostTooHigh();
    error NotCharacterOwner();
    error AlreadyHasMount();
    error InsufficientLevel();
    error MountNotActive();
    error NoMountAssigned();

    // Constants for maximum boost values (in basis points)
    uint256 public constant MAX_SPEED_BOOST = 5000; // 50%
    uint256 public constant MAX_STAMINA_BOOST = 5000; // 50%
    uint256 public constant MAX_YIELD_BOOST = 5000; // 50%
    uint256 public constant MAX_DROP_BOOST = 5000; // 50%

    // Mount types
    enum MountType {
        LAND,
        SEA,
        AIR
    }

    struct MountData {
        string name;
        string description;
        MountType mountType;
        uint256 speedBoost;
        uint256 staminaBoost;
        uint256 yieldBoost;
        uint256 dropRateBoost;
        uint256 requiredLevel;
        bool isActive;
        uint256 questFeeReduction;
        uint256 travelTimeReduction;
        uint256 stakingBoostBps;
        uint256 lpLockReductionBps;
    }

    // Storage
    mapping(uint256 => MountData) public mounts;
    mapping(uint256 => uint256) public characterToMount; // characterId => mountId
    uint256 private _nextMountId;

    // Character contract reference
    Character public immutable characterContract;

    // Constants
    uint256 public constant MAX_FEE_REDUCTION = 5000; // 50% in basis points
    uint256 public constant MAX_TRAVEL_REDUCTION = 1 days;
    uint256 public constant MAX_STAKING_BOOST = 5000; // 50% in basis points
    uint256 public constant MAX_LOCK_REDUCTION = 5000; // 50% in basis points

    // Events
    event MountCreated(uint256 indexed mountId, string name, MountType mountType);
    event MountAssigned(uint256 indexed characterId, uint256 indexed mountId);
    event MountUnassigned(uint256 indexed characterId, uint256 indexed mountId);
    event MountActivated(uint256 indexed mountId);
    event MountDeactivated(uint256 indexed mountId);

    constructor(address _characterContract) ERC721("Game Mount", "MOUNT") Ownable(msg.sender) {
        characterContract = Character(_characterContract);
        _nextMountId = 2_000_000;
    }

    /// @notice Create a new mount type
    /// @param name The name of the mount
    /// @param description The description of the mount
    /// @param mountType The type of mount (LAND, SEA, or AIR)
    /// @param speedBoost The speed boost in basis points
    /// @param staminaBoost The stamina boost in basis points
    /// @param yieldBoost The yield boost in basis points
    /// @param dropRateBoost The drop rate boost in basis points
    /// @param questFeeReduction The quest fee reduction in basis points
    /// @param travelTimeReduction The travel time reduction in seconds
    /// @param stakingBoostBps The staking boost in basis points
    /// @param lpLockReductionBps The LP lock reduction in basis points
    /// @param requiredLevel The required level to use this mount
    /// @return The ID of the newly created mount
    function createMount(
        string memory name,
        string memory description,
        MountType mountType,
        uint256 speedBoost,
        uint256 staminaBoost,
        uint256 yieldBoost,
        uint256 dropRateBoost,
        uint256 questFeeReduction,
        uint256 travelTimeReduction,
        uint256 stakingBoostBps,
        uint256 lpLockReductionBps,
        uint256 requiredLevel
    ) external onlyOwner returns (uint256) {
        // Validate boost values
        if (
            speedBoost > MAX_SPEED_BOOST || staminaBoost > MAX_STAMINA_BOOST || yieldBoost > MAX_YIELD_BOOST
                || dropRateBoost > MAX_DROP_BOOST || questFeeReduction > MAX_FEE_REDUCTION
                || travelTimeReduction > MAX_TRAVEL_REDUCTION || stakingBoostBps > MAX_STAKING_BOOST
                || lpLockReductionBps > MAX_LOCK_REDUCTION
        ) {
            revert BoostTooHigh();
        }

        // Validate required level
        require(requiredLevel > 0, "Required level must be greater than 0");

        uint256 mountId = _nextMountId++;

        mounts[mountId] = MountData({
            name: name,
            description: description,
            mountType: mountType,
            speedBoost: speedBoost,
            staminaBoost: staminaBoost,
            yieldBoost: yieldBoost,
            dropRateBoost: dropRateBoost,
            requiredLevel: requiredLevel,
            isActive: true, // Set to true by default
            questFeeReduction: questFeeReduction,
            travelTimeReduction: travelTimeReduction,
            stakingBoostBps: stakingBoostBps,
            lpLockReductionBps: lpLockReductionBps
        });

        emit MountCreated(mountId, name, mountType);
        emit MountActivated(mountId);
        return mountId;
    }

    /// @notice Mint a mount to a character
    function mintMount(uint256 characterId, uint256 mountId) external {
        // Check if mount type exists and is active
        MountData memory mountData = mounts[mountId];
        if (mountData.requiredLevel == 0) revert MountNotActive(); // Mount type doesn't exist
        if (!mountData.isActive) revert MountNotActive();

        // Check character ownership
        address characterOwner = characterContract.ownerOf(characterId);
        if (msg.sender != characterOwner) {
            revert NotCharacterOwner();
        }

        // Get character wallet and verify it exists
        address characterWallet = address(characterContract.characterWallets(characterId));
        require(characterWallet != address(0), "Invalid character wallet");

        // Check if character already has a mount
        if (characterToMount[characterId] != 0) {
            revert AlreadyHasMount();
        }

        // Check character level requirement
        (,, Types.CharacterState memory state) = characterContract.getCharacter(characterId);
        if (state.level < mountData.requiredLevel) {
            revert InsufficientLevel();
        }

        // First assign mount to character to prevent reentrancy
        characterToMount[characterId] = mountId;

        // Then mint the mount NFT to the character's wallet
        _safeMint(characterWallet, mountId);

        emit MountAssigned(characterId, mountId);
    }

    /// @notice Unassign a mount from a character
    function unassignMount(uint256 characterId) external {
        uint256 mountId = characterToMount[characterId];
        if (mountId == 0) revert NoMountAssigned();

        // Check character ownership
        address characterOwner = characterContract.ownerOf(characterId);
        if (msg.sender != characterOwner) {
            revert NotCharacterOwner();
        }

        // Get character wallet and verify it exists
        address characterWallet = address(characterContract.characterWallets(characterId));
        require(characterWallet != address(0), "Invalid character wallet");

        // Verify mount exists and is owned by character wallet
        if (!_exists(mountId)) {
            // Clear stale mount assignment
            characterToMount[characterId] = 0;
            revert NoMountAssigned();
        }

        if (ownerOf(mountId) != characterWallet) {
            // Clear stale mount assignment
            characterToMount[characterId] = 0;
            revert NoMountAssigned();
        }

        // Clear mount assignment first
        characterToMount[characterId] = 0;

        // Then burn the mount NFT
        _burn(mountId);

        emit MountUnassigned(characterId, mountId);
    }

    /// @notice Check if a character has an active mount
    function hasActiveMount(uint256 characterId) public view returns (bool) {
        uint256 mountId = characterToMount[characterId];
        if (mountId == 0) return false;

        // Get character wallet
        address characterWallet = address(characterContract.characterWallets(characterId));
        if (characterWallet == address(0)) return false;

        // Check if the mount exists and is active
        if (!_exists(mountId)) {
            return false;
        }

        MountData memory mount = mounts[mountId];
        if (!mount.isActive) {
            return false;
        }

        // Check if the mount is owned by the character's wallet
        return ownerOf(mountId) == characterWallet;
    }

    /// @notice Get mount benefits for a character
    function getMountBenefits(uint256 characterId)
        public
        view
        returns (
            uint256 questFeeReduction,
            uint256 travelTimeReduction,
            uint256 stakingBoostBps,
            uint256 lpLockReductionBps
        )
    {
        if (!hasActiveMount(characterId)) return (0, 0, 0, 0);

        uint256 mountId = characterToMount[characterId];
        MountData memory mount = mounts[mountId];
        return (mount.questFeeReduction, mount.travelTimeReduction, mount.stakingBoostBps, mount.lpLockReductionBps);
    }

    /// @notice Get a mount's type
    function getMountType(uint256 mountId) external view returns (MountType) {
        return mounts[mountId].mountType;
    }

    /// @notice Deactivate a mount type
    function deactivateMount(uint256 mountId) external onlyOwner {
        mounts[mountId].isActive = false;
        emit MountDeactivated(mountId);
    }

    /// @notice Activate a mount type
    function activateMount(uint256 mountId) external onlyOwner {
        mounts[mountId].isActive = true;
        emit MountActivated(mountId);
    }

    /// @inheritdoc IAttributeProvider
    function getBonus(uint256 characterId) external view override returns (uint256) {
        if (!hasActiveMount(characterId)) return 0;
        uint256 mountId = characterToMount[characterId];
        MountData memory mount = mounts[mountId];
        return mount.stakingBoostBps;
    }

    /// @inheritdoc IAttributeProvider
    function isActive(uint256 characterId) external view override returns (bool) {
        return hasActiveMount(characterId);
    }

    /// @notice Get attribute bonuses for a character
    /// @param characterId The ID of the character
    /// @return bonuses The attribute bonuses provided by the mount
    function getAttributeBonuses(uint256 characterId) external view returns (Types.AttributeBonuses memory) {
        uint256 mountId = characterToMount[characterId];
        if (mountId == 0 || !hasActiveMount(characterId)) {
            return Types.AttributeBonuses(0, 0);
        }

        MountData memory mount = mounts[mountId];
        return Types.AttributeBonuses(mount.yieldBoost, mount.dropRateBoost);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
