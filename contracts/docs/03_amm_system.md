# AMM (Automated Market Maker) System Documentation

## Overview
The AMM System is a sophisticated decentralized trading infrastructure that powers the in-game economy through automated market making. Built on the constant product formula (x * y = k), it enables seamless trading of in-game resources while providing liquidity providers with incentives through LP tokens and yield farming opportunities. The system integrates deeply with crafting and equipment systems to create a dynamic, player-driven economy.

## Core Components

### ArcaneFactory Contract
The factory contract serves as the central registry and creator of trading pairs:
```solidity
contract ArcaneFactory is IArcaneFactory, Ownable {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256 pairId
    );
    
    // Creates a new trading pair and deploys pair contract
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB 
            ? (tokenA, tokenB) 
            : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");
        
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        ArcanePair newPair = new ArcanePair{salt: salt}();
        pair = address(newPair);
        
        newPair.initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);
        return pair;
    }
}
```

### ArcanePair Contract
Manages individual liquidity pools and handles token swaps:
```solidity
contract ArcanePair is IArcanePool {
    using SafeMath for uint256;
    
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    
    address public factory;
    address public token0;
    address public token1;
    
    uint112 private reserve0;
    uint112 private reserve1;
    uint32  private blockTimestampLast;
    
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;
    
    struct SwapVariables {
        uint112 _reserve0;
        uint112 _reserve1;
        uint256 balance0;
        uint256 balance1;
        uint256 amount0In;
        uint256 amount1In;
        uint256 amount0Out;
        uint256 amount1Out;
    }
    
    // Swap tokens maintaining constant product formula
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        SwapVariables memory vars;
        (vars._reserve0, vars._reserve1,) = getReserves();
        require(amount0Out < vars._reserve0 && amount1Out < vars._reserve1, "INSUFFICIENT_LIQUIDITY");
        
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        
        vars.balance0 = IERC20(token0).balanceOf(address(this));
        vars.balance1 = IERC20(token1).balanceOf(address(this));
        vars.amount0In = vars.balance0 > vars._reserve0 - amount0Out ? vars.balance0 - (vars._reserve0 - amount0Out) : 0;
        vars.amount1In = vars.balance1 > vars._reserve1 - amount1Out ? vars.balance1 - (vars._reserve1 - amount1Out) : 0;
        require(vars.amount0In > 0 || vars.amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
        
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = vars.balance0.mul(1000).sub(vars.amount0In.mul(3));
            uint256 balance1Adjusted = vars.balance1.mul(1000).sub(vars.amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint256(vars._reserve0).mul(vars._reserve1).mul(1000**2), "K");
        }
        
        _update(vars.balance0, vars.balance1, vars._reserve0, vars._reserve1);
        emit Swap(msg.sender, vars.amount0In, vars.amount1In, amount0Out, amount1Out, to);
    }
}
```

### Staking System
Manages LP token staking and rewards distribution:
```solidity
contract ArcaneStaking is IArcaneStaking, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;        // LP token amount
        uint256 rewardDebt;    // Reward debt
        uint256 lockEndTime;   // Lock end timestamp
    }
    
    struct PoolInfo {
        IERC20 lpToken;        // LP token contract
        uint256 allocPoint;    // Allocation points for rewards
        uint256 lastRewardTime;// Last reward distribution time
        uint256 accRewardPerShare; // Accumulated rewards per share
        uint256 lockDuration;  // Required lock duration
    }
    
    // Pool info
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Stake LP tokens with time lock
    function stake(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        // Update pool rewards
        updatePool(_pid);
        
        // Transfer LP tokens
        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        // Update user info
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare)
                .div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeRewardTransfer(msg.sender, pending);
            }
        }
        
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        user.lockEndTime = block.timestamp.add(pool.lockDuration);
        
        emit Stake(msg.sender, _pid, _amount);
    }
}
```

## Advanced Features

### Price Oracle Implementation
```solidity
contract ArcanePriceOracle is IArcanePriceOracle {
    using FixedPoint for *;
    
    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }
    
    mapping(address => Observation[]) public pairObservations;
    uint256 public constant OBSERVATION_PERIOD = 24 hours;
    
    // Update price accumulator
    function update(address pair) external {
        (uint256 price0Cumulative, uint256 price1Cumulative,) = ArcanePair(pair).getAccumulators();
        uint256 timeElapsed = block.timestamp - pairObservations[pair][0].timestamp;
        
        require(timeElapsed >= OBSERVATION_PERIOD, "PERIOD_NOT_ELAPSED");
        
        // Calculate TWAP
        uint256 price0 = price0Cumulative.sub(pairObservations[pair][0].price0Cumulative).div(timeElapsed);
        uint256 price1 = price1Cumulative.sub(pairObservations[pair][0].price1Cumulative).div(timeElapsed);
        
        // Store new observation
        pairObservations[pair][0] = Observation(block.timestamp, price0Cumulative, price1Cumulative);
        
        emit PriceUpdated(pair, price0, price1);
    }
}
```

### Flash Swap Implementation
```solidity
contract ArcaneFlashSwap is IArcaneFlashSwap {
    using SafeMath for uint256;
    
    // Execute flash swap
    function executeOperation(
        address pair,
        uint256 amount0,
        uint256 amount1,
        bytes calldata params
    ) external returns (bool) {
        // Custom logic using flash-borrowed tokens
        
        // Repay flash swap
        uint256 fee0 = amount0.mul(3).div(1000);
        uint256 fee1 = amount1.mul(3).div(1000);
        
        IERC20(ArcanePair(pair).token0()).transfer(pair, amount0.add(fee0));
        IERC20(ArcanePair(pair).token1()).transfer(pair, amount1.add(fee1));
        
        return true;
    }
}
```

## Integration Examples

### Crafting System Integration
```solidity
contract ArcaneCrafting {
    IArcaneAMM public amm;
    
    // Craft item using LP tokens as catalyst
    function craftWithLiquidity(
        uint256 recipeId,
        uint256 lpAmount,
        address lpToken
    ) external returns (uint256 itemId) {
        // Verify LP token is from valid pair
        require(amm.isValidPair(lpToken), "INVALID_LP_TOKEN");
        
        // Transfer LP tokens
        IERC20(lpToken).transferFrom(msg.sender, address(this), lpAmount);
        
        // Calculate success rate boost from LP amount
        uint256 successBoost = calculateLPBoost(lpAmount);
        
        // Execute crafting with boosted success rate
        itemId = _executeCrafting(recipeId, successBoost);
        
        emit ItemCrafted(msg.sender, itemId, lpAmount);
        return itemId;
    }
}
```

### Quest System Integration
```solidity
contract ArcaneQuests {
    struct QuestReward {
        address lpToken;
        uint256 amount;
    }
    
    // Complete quest with LP token rewards
    function completeQuest(uint256 questId) external {
        require(isQuestComplete(questId), "QUEST_INCOMPLETE");
        
        QuestReward memory reward = questRewards[questId];
        if (reward.lpToken != address(0)) {
            // Mint LP tokens as reward
            IArcanePair(reward.lpToken).mint(msg.sender, reward.amount);
        }
        
        emit QuestCompleted(msg.sender, questId);
    }
}
```

## Advanced Usage Examples

### Multi-Hop Trading
```solidity
contract ArcaneRouter {
    // Execute multi-hop swap
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        
        _safeTransferFrom(
            path[0],
            msg.sender,
            ArcanePair(pairFor(path[0], path[1])),
            amounts[0]
        );
        
        _swap(amounts, path, to);
        
        emit Swap(msg.sender, path[0], path[path.length-1], amounts[0], amounts[amounts.length-1]);
    }
}
```

## Gas Optimization Examples

### Optimized Storage Layout
```solidity
contract OptimizedPair {
    // Pack variables to use single storage slot
    struct Slot0 {
        // Price and liquidity variables
        uint160 sqrtPriceX96;  // 160 bits
        int24 tick;            // 24 bits
        uint16 observationIndex; // 16 bits
        uint16 observationCardinality; // 16 bits
        uint16 observationCardinalityNext; // 16 bits
        uint8 feeProtocol;     // 8 bits
        bool unlocked;         // 1 bit
    }
    
    Slot0 public slot0;
    
    // Use events for off-chain tracking
    event Sync(uint160 sqrtPriceX96, int24 tick);
}
```

## Error Handling and Recovery

### Emergency Procedures
```solidity
contract EmergencyHandler {
    // Emergency withdraw function
    function emergencyWithdraw(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(token != address(0), "INVALID_TOKEN");
        require(recipient != address(0), "INVALID_RECIPIENT");
        
        IERC20(token).safeTransfer(recipient, amount);
        emit EmergencyWithdraw(token, recipient, amount);
    }
    
    // Pause trading
    function pauseTrading() external onlyOwner {
        _pause();
        emit TradingPaused(block.timestamp);
    }
}
```

## Monitoring and Analytics

### Pool Analytics
```solidity
contract ArcaneAnalytics {
    struct PoolStats {
        uint256 volume24h;
        uint256 tvl;
        uint256 apy;
        uint256 impermanentLoss;
    }
    
    // Calculate and update pool statistics
    function updatePoolStats(address pair) external {
        PoolStats storage stats = poolStats[pair];
        
        // Update 24h volume
        stats.volume24h = calculateVolume24h(pair);
        
        // Calculate TVL
        stats.tvl = calculateTVL(pair);
        
        // Calculate APY
        stats.apy = calculateAPY(pair);
        
        // Calculate IL
        stats.impermanentLoss = calculateImpermanentLoss(pair);
        
        emit PoolStatsUpdated(pair, stats);
    }
}
```

## Future Enhancements
1. Concentrated Liquidity
   - Implement Uniswap V3 style liquidity provision
   - Enable more capital efficient trading
   - Support multiple fee tiers

2. Advanced Oracle System
   - Implement TWAP with configurable periods
   - Add support for external price feeds
   - Implement manipulation resistance

3. Yield Optimization
   - Auto-compounding strategies
   - Optimal range management
   - Dynamic fee adjustment

4. Risk Management
   - Circuit breakers
   - Price impact limits
   - Liquidity thresholds

5. Cross-Chain Integration
   - Bridge integration
   - Cross-chain liquidity
   - Unified liquidity pools 