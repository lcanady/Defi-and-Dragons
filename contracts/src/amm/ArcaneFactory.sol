// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ArcanePair.sol";

/// @title ArcaneFactory
/// @notice Factory contract for creating and managing liquidity pairs in the Arcane Exchange
contract ArcaneFactory is Ownable, ReentrancyGuard {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairLength);

    constructor() Ownable(msg.sender) { }

    /// @notice Creates a new liquidity pair for two tokens
    /// @param tokenA The first token of the pair
    /// @param tokenB The second token of the pair
    /// @return pair The address of the created pair
    function createPair(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");

        // Sort tokens to ensure consistent pair addresses
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        // Deploy new pair contract
        bytes memory bytecode = type(ArcanePair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Initialize pair
        ArcanePair(pair).initialize(token0, token1);

        // Store pair mapping both ways
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /// @notice Returns the number of pairs created
    /// @return The length of allPairs array
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
