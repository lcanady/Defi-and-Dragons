// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ArcaneFactory } from "./ArcaneFactory.sol";
import { ArcanePair } from "./ArcanePair.sol";

error InvalidPath();
error InsufficientOutputAmount();
error PairNotFound();
error InsufficientInputAmount();
error InsufficientLiquidity();
error ExcessiveInputAmount();
error InsufficientAAmount();
error InsufficientBAmount();
error TransferFailed();

/// @title ArcaneRouter
/// @notice Handles routing of trades and liquidity provision
contract ArcaneRouter is ReentrancyGuard {
    ArcaneFactory public immutable factory;

    constructor(address _factory) {
        factory = ArcaneFactory(_factory);
    }

    /// @notice Add liquidity to a pool
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @param amountADesired Desired amount of tokenA
    /// @param amountBDesired Desired amount of tokenB
    /// @param amountAMin Minimum amount of tokenA
    /// @param amountBMin Minimum amount of tokenB
    /// @param to Address to receive LP tokens
    /// @return amountA Amount of tokenA added
    /// @return amountB Amount of tokenB added
    /// @return liquidity Amount of LP tokens minted
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (factory.getPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        (amountA, amountB) =
            _calculateLiquidityAmounts(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        address pair = factory.getPair(tokenA, tokenB);
        _transferTokens(tokenA, msg.sender, pair, amountA);
        _transferTokens(tokenB, msg.sender, pair, amountB);
        liquidity = ArcanePair(pair).mint(to);
    }

    /// @notice Remove liquidity from a pool
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @param liquidity Amount of LP tokens to burn
    /// @param amountAMin Minimum amount of tokenA to receive
    /// @param amountBMin Minimum amount of tokenB to receive
    /// @param to Address to receive tokens
    /// @return amountA Amount of tokenA received
    /// @return amountB Amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        address pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();

        ArcanePair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = ArcanePair(pair).burn(to);

        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    /// @notice Swap exact tokens for tokens
    /// @param amountIn Exact amount of input tokens
    /// @param amountOutMin Minimum amount of output tokens
    /// @param path Array of token addresses representing the path
    /// @param to Address to receive output tokens
    /// @return amounts Array of amounts for each swap in the path
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        external
        nonReentrant
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) revert InvalidPath();
        amounts = _getAmountsOut(amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();

        _transferTokens(path[0], msg.sender, factory.getPair(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /// @notice Calculate optimal liquidity amounts
    function _calculateLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        address pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            return (amountADesired, amountBDesired);
        }

        (uint112 reserveA, uint112 reserveB,) = ArcanePair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            if (amountBOptimal < amountBMin) revert InsufficientBAmount();
            return (amountADesired, amountBOptimal);
        }

        uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
        if (amountAOptimal > amountADesired) revert ExcessiveInputAmount();
        if (amountAOptimal < amountAMin) revert InsufficientAAmount();
        return (amountAOptimal, amountBDesired);
    }

    /// @notice Get amounts out for a given input amount and path
    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            (uint112 reserve0, uint112 reserve1,) = ArcanePair(factory.getPair(path[i], path[i + 1])).getReserves();
            amounts[i + 1] = _getAmountOut(amounts[i], reserve0, reserve1);
        }
    }

    /// @notice Calculate output amount for a single swap
    function _getAmountOut(uint256 amountIn, uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
        if (amountIn == 0) revert InsufficientInputAmount();
        if (reserve0 == 0 || reserve1 == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserve1;
        uint256 denominator = (reserve0 * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    /// @notice Execute swaps along a path
    function _swap(uint256[] memory amounts, address[] memory path, address to) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address pair = factory.getPair(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input < output ? (uint256(0), amountOut) : (amountOut, uint256(0));
            ArcanePair(pair).swap(amount0Out, amount1Out, to);
        }
    }

    /// @notice Helper function to transfer tokens
    function _transferTokens(address token, address from, address to, uint256 amount) internal {
        bool success = IERC20(token).transferFrom(from, to, amount);
        if (!success) revert TransferFailed();
    }
}
