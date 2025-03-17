// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ArcaneFactory } from "./ArcaneFactory.sol";
import { ArcanePair } from "./ArcanePair.sol";
import { Equipment } from "../Equipment.sol";
import { ItemDrop } from "../ItemDrop.sol";
import "../interfaces/Types.sol";

error InsufficientLPTokens();
error InsufficientResources();
error InvalidRecipe();
error CraftingCooldown();

/// @title ArcaneCrafting
/// @notice Handles crafting recipes that require LP tokens and AMM engagement
contract ArcaneCrafting is Ownable, ReentrancyGuard {
    ArcaneFactory public immutable factory;
    Equipment public immutable equipment;
    ItemDrop public immutable itemDrop;

    // Struct to define crafting recipe requirements
    struct Recipe {
        uint256 recipeId;
        uint256 resultingItemId;
        address lpToken;          // Required LP token address
        uint256 lpTokenAmount;    // Required LP token amount
        address[] resources;      // Additional required resource token addresses
        uint256[] resourceAmounts; // Required amounts for each resource
        uint256 cooldown;         // Cooldown period between crafts (in seconds)
        bool isActive;            // Whether this recipe is currently active
    }

    // Mapping to store crafting recipes
    mapping(uint256 => Recipe) public recipes;
    
    // Mapping to track last craft time for each user and recipe
    mapping(address => mapping(uint256 => uint256)) public lastCraftTime;
    
    // Mapping to track special gear that requires AMM engagement
    mapping(uint256 => bool) public ammRequiredGear;

    // Events
    event RecipeCreated(uint256 indexed recipeId, uint256 indexed resultingItemId);
    event RecipeUpdated(uint256 indexed recipeId, bool isActive);
    event ItemCrafted(address indexed crafter, uint256 indexed recipeId, uint256 indexed itemId);
    event AMMGearStatusSet(uint256 indexed itemId, bool required);

    constructor(address _factory, address _equipment, address _itemDrop) {
        _transferOwnership(msg.sender);
        factory = ArcaneFactory(_factory);
        equipment = Equipment(_equipment);
        itemDrop = ItemDrop(_itemDrop);
    }

    /// @notice Create a new crafting recipe
    /// @param _recipeId Unique identifier for the recipe
    /// @param _resultingItemId ID of the item that will be crafted
    /// @param _lpToken Address of the required LP token
    /// @param _lpTokenAmount Amount of LP tokens required
    /// @param _resources Array of resource token addresses required
    /// @param _resourceAmounts Array of amounts required for each resource
    /// @param _cooldown Cooldown period between crafts
    function createRecipe(
        uint256 _recipeId,
        uint256 _resultingItemId,
        address _lpToken,
        uint256 _lpTokenAmount,
        address[] memory _resources,
        uint256[] memory _resourceAmounts,
        uint256 _cooldown
    ) external onlyOwner {
        require(_resources.length == _resourceAmounts.length, "Resource arrays length mismatch");
        require(_lpToken != address(0), "Invalid LP token address");

        recipes[_recipeId] = Recipe({
            recipeId: _recipeId,
            resultingItemId: _resultingItemId,
            lpToken: _lpToken,
            lpTokenAmount: _lpTokenAmount,
            resources: _resources,
            resourceAmounts: _resourceAmounts,
            cooldown: _cooldown,
            isActive: true
        });

        emit RecipeCreated(_recipeId, _resultingItemId);
    }

    /// @notice Set whether an item requires AMM engagement to be crafted
    /// @param _itemId ID of the item
    /// @param _required Whether AMM engagement is required
    function setAMMRequiredGear(uint256 _itemId, bool _required) external onlyOwner {
        ammRequiredGear[_itemId] = _required;
        emit AMMGearStatusSet(_itemId, _required);
    }

    /// @notice Update recipe status (active/inactive)
    /// @param _recipeId ID of the recipe to update
    /// @param _isActive New active status
    function updateRecipeStatus(uint256 _recipeId, bool _isActive) external onlyOwner {
        recipes[_recipeId].isActive = _isActive;
        emit RecipeUpdated(_recipeId, _isActive);
    }

    /// @notice Check if a user has sufficient LP tokens and resources for a recipe
    /// @param _user Address of the user
    /// @param _recipeId ID of the recipe to check
    /// @return bool Whether the user has sufficient resources
    function checkRecipeRequirements(address _user, uint256 _recipeId) public view returns (bool) {
        Recipe memory recipe = recipes[_recipeId];
        if (!recipe.isActive) return false;

        // Check LP token balance
        if (IERC20(recipe.lpToken).balanceOf(_user) < recipe.lpTokenAmount) {
            return false;
        }

        // Check resource balances
        for (uint256 i = 0; i < recipe.resources.length; i++) {
            if (IERC20(recipe.resources[i]).balanceOf(_user) < recipe.resourceAmounts[i]) {
                return false;
            }
        }

        return true;
    }

    /// @notice Craft an item using LP tokens and resources
    /// @param _recipeId ID of the recipe to craft
    function craftItem(uint256 _recipeId) external nonReentrant {
        Recipe memory recipe = recipes[_recipeId];
        if (!recipe.isActive) revert InvalidRecipe();

        // Check requirements first
        if (!checkRecipeRequirements(msg.sender, _recipeId)) {
            revert InsufficientResources();
        }

        // Check cooldown only if there was a previous craft
        uint256 lastCraft = lastCraftTime[msg.sender][_recipeId];
        if (lastCraft != 0 && block.timestamp < lastCraft + recipe.cooldown) {
            revert CraftingCooldown();
        }

        // Transfer LP tokens
        IERC20(recipe.lpToken).transferFrom(msg.sender, address(this), recipe.lpTokenAmount);

        // Transfer resources
        for (uint256 i = 0; i < recipe.resources.length; i++) {
            IERC20(recipe.resources[i]).transferFrom(
                msg.sender,
                address(this),
                recipe.resourceAmounts[i]
            );
        }

        // Mint the crafted item
        equipment.mint(msg.sender, recipe.resultingItemId, 1, "");

        // Update last craft time
        lastCraftTime[msg.sender][_recipeId] = block.timestamp;

        emit ItemCrafted(msg.sender, _recipeId, recipe.resultingItemId);
    }

    /// @notice Get recipe details
    /// @param _recipeId ID of the recipe
    /// @return Recipe memory containing recipe details
    function getRecipe(uint256 _recipeId) external view returns (Recipe memory) {
        return recipes[_recipeId];
    }

    /// @notice Check if an item requires AMM engagement
    /// @param _itemId ID of the item to check
    /// @return bool Whether the item requires AMM engagement
    function isAMMRequired(uint256 _itemId) external view returns (bool) {
        return ammRequiredGear[_itemId];
    }
} 