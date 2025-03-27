// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../ProtocolQuestValidator.sol";
import "../CombatActions.sol";

contract GameAMM is AccessControl, ReentrancyGuard {
    ProtocolQuestValidator public immutable questValidator;
    CombatActions public immutable combatActions;

    // AMM state variables
    mapping(address => mapping(address => uint256)) public liquidityProvided; // user => token => amount
    mapping(address => uint256) public totalLiquidity; // token => total amount

    // Supported tokens
    mapping(address => bool) public supportedTokens;
    address[] public allSupportedTokens;

    // Character tracking for combat
    mapping(address => uint256) public activeCharacters; // wallet => characterId

    event LiquidityAdded(address indexed provider, address indexed token, uint256 amount, uint256 damage);
    event LiquidityRemoved(address indexed provider, address indexed token, uint256 amount);
    event TokenSupported(address indexed token);
    event TokenRemoved(address indexed token);
    event CharacterSet(address indexed wallet, uint256 indexed characterId);

    constructor(address _questValidator, address _combatActions) {
        questValidator = ProtocolQuestValidator(_questValidator);
        combatActions = CombatActions(_combatActions);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setActiveCharacter(uint256 characterId) external {
        require(combatActions.character().ownerOf(characterId) == msg.sender, "Not character owner");
        activeCharacters[msg.sender] = characterId;
        emit CharacterSet(msg.sender, characterId);
    }

    function addSupportedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!supportedTokens[token], "Token already supported");
        supportedTokens[token] = true;
        allSupportedTokens.push(token);
        emit TokenSupported(token);
    }

    function removeSupportedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supportedTokens[token], "Token not supported");
        supportedTokens[token] = false;

        // Remove from array
        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            if (allSupportedTokens[i] == token) {
                allSupportedTokens[i] = allSupportedTokens[allSupportedTokens.length - 1];
                allSupportedTokens.pop();
                break;
            }
        }

        emit TokenRemoved(token);
    }

    function addLiquidity(address token, uint256 amount) external nonReentrant returns (uint256 damage) {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens to AMM
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update liquidity tracking
        liquidityProvided[msg.sender][token] += amount;
        totalLiquidity[token] += amount;

        // Notify quest validator of liquidity provision
        questValidator.onLiquidityProvided(msg.sender, token, amount);

        // Process combat action if character is in battle
        uint256 characterId = activeCharacters[msg.sender];
        if (characterId != 0) {
            // Get battle state
            (,,, bool isActive) = combatActions.getBattleState(characterId);
            if (isActive) {
                // Trigger combat move for liquidity provision
                damage = combatActions.triggerMove(
                    characterId,
                    CombatActions.ActionType.YIELD_FARM, // Using YIELD_FARM for liquidity
                    amount
                );
            }
        }

        emit LiquidityAdded(msg.sender, token, amount, damage);
        return damage;
    }

    function removeLiquidity(address token, uint256 amount) external nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than 0");
        require(liquidityProvided[msg.sender][token] >= amount, "Insufficient liquidity");

        // Transfer tokens back to provider
        IERC20(token).transfer(msg.sender, amount);

        // Update liquidity tracking
        liquidityProvided[msg.sender][token] -= amount;
        totalLiquidity[token] -= amount;

        emit LiquidityRemoved(msg.sender, token, amount);
    }

    function getUserLiquidity(address user, address token) external view returns (uint256) {
        return liquidityProvided[user][token];
    }

    function getAllUserLiquidity(address user)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = new address[](allSupportedTokens.length);
        amounts = new uint256[](allSupportedTokens.length);

        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            tokens[i] = allSupportedTokens[i];
            amounts[i] = liquidityProvided[user][allSupportedTokens[i]];
        }

        return (tokens, amounts);
    }
}
