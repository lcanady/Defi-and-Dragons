// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title ArcanePair
/// @notice Manages liquidity pool for a pair of tokens
contract ArcanePair is ERC20, ReentrancyGuard {
    using Math for uint256;
    using UQ112x112 for uint224;

    address public token0;
    address public token1;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    uint112 private _reserve0;
    uint112 private _reserve1;
    uint32 private _blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    bool public initialized;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    modifier onlyInitialized() {
        require(initialized, "NOT_INITIALIZED");
        _;
    }

    constructor() ERC20("Arcane LP Token", "ALP") { }

    /// @notice Initializes the pair with two tokens
    /// @param _token0 Address of the first token
    /// @param _token1 Address of the second token
    function initialize(address _token0, address _token1) external {
        require(!initialized, "ALREADY_INITIALIZED");
        token0 = _token0;
        token1 = _token1;
        initialized = true;
    }

    /// @notice Updates reserves and price accumulators
    function _update(uint256 balance0, uint256 balance1, uint112 reserve0New, uint112 reserve1New) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - _blockTimestampLast;

        if (timeElapsed > 0 && reserve0New != 0 && reserve1New != 0) {
            uint256 price0 = (uint256(reserve1New) << 112) / reserve0New;
            uint256 price1 = (uint256(reserve0New) << 112) / reserve1New;
            price0CumulativeLast += price0 * timeElapsed;
            price1CumulativeLast += price1 * timeElapsed;
        }

        _reserve0 = reserve0New;
        _reserve1 = reserve1New;
        _blockTimestampLast = blockTimestamp;
        emit Sync(reserve0New, reserve1New);
    }

    /// @notice Get current reserves and last block timestamp
    /// @return reserve0Current Current reserve of token0
    /// @return reserve1Current Current reserve of token1
    /// @return blockTimestampLastCurrent Last block timestamp
    function getReserves()
        public
        view
        returns (uint112 reserve0Current, uint112 reserve1Current, uint32 blockTimestampLastCurrent)
    {
        reserve0Current = _reserve0;
        reserve1Current = _reserve1;
        blockTimestampLastCurrent = _blockTimestampLast;
    }

    /// @notice Add liquidity to the pool
    /// @param to Address to receive LP tokens
    /// @return liquidity Amount of LP tokens minted
    function mint(address to) external nonReentrant onlyInitialized returns (uint256 liquidity) {
        (uint112 reserve0Current, uint112 reserve1Current,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0Current;
        uint256 amount1 = balance1 - reserve1Current;

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0xdead), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / reserve0Current, (amount1 * _totalSupply) / reserve1Current);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, uint112(balance0), uint112(balance1));
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @notice Remove liquidity from the pool
    /// @param to Address to receive tokens
    /// @return amount0 Amount of token0 returned
    /// @return amount1 Amount of token1 returned
    function burn(address to) external nonReentrant onlyInitialized returns (uint256 amount0, uint256 amount1) {
        uint256 liquidity = balanceOf(address(this));
        uint256 _totalSupply = totalSupply();
        amount0 = (liquidity * _reserve0) / _totalSupply;
        amount1 = (liquidity * _reserve1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, uint112(balance0), uint112(balance1));
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @notice Swap tokens
    /// @param amount0Out Amount of token0 to receive
    /// @param amount1Out Amount of token1 to receive
    /// @param to Address to receive tokens
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant onlyInitialized {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 reserve0Current, uint112 reserve1Current,) = getReserves();
        require(amount0Out < reserve0Current && amount1Out < reserve1Current, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0In = balance0 > reserve0Current - amount0Out ? balance0 - (reserve0Current - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1Current - amount1Out ? balance1 - (reserve1Current - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");

        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        require(
            balance0Adjusted * balance1Adjusted >= uint256(reserve0Current) * uint256(reserve1Current) * (1000 ** 2),
            "K"
        );

        _update(balance0, balance1, uint112(balance0), uint112(balance1));
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @notice Safe transfer helper
    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }
}

/// @notice Helper library for fixed point arithmetic
library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
