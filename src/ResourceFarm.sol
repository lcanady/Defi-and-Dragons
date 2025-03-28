// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ProvableRandom} from "./ProvableRandom.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";

/**
 * @title ResourceFarm
 * @dev Stake LP tokens (or other ERC20s) to farm resource tokens.
 * Inspired by MasterChef contracts.
 * Includes chance for rare drops on harvest using ProvableRandom.
 */
contract ResourceFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableERC20;

    ProvableRandom public randomSource;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool seedInitialized; // Track if random seed is initialized for this pool
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IMintableERC20 rewardToken; // Address of reward token contract (must be mintable by this farm).
        uint256 allocPoint; // How many allocation points assigned to this pool. REWARDS to distribute per block.
        uint256 lastRewardBlock; // Last block number that REWARDS distribution occurs.
        uint256 accRewardPerShare; // Accumulated REWARDS per share, times 1e18.
        uint256 totalStaked; // Total amount of LP tokens staked in this pool.
        IMintableERC20 rareRewardToken; // Optional: Address of the rare reward token (mintable).
        uint16 rareDropChanceBps; // Chance in basis points (0-10000) to get a rare drop on harvest.
        uint256 rareDropAmount; // Amount of rare token to drop.
    }

    // Array of all pools.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when REWARD mining starts.
    uint256 public startBlock;
    // Reward tokens created per block.
    uint256 public rewardPerBlock; // Note: This is the TOTAL reward across all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event RareHarvest(address indexed user, uint256 indexed pid, address indexed rareToken, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        IMintableERC20 indexed rewardToken,
        IMintableERC20 rareRewardToken,
        uint16 rareDropChanceBps,
        uint256 rareDropAmount
    );
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdateEmissionRate(uint256 rewardPerBlock);

    constructor(uint256 _rewardPerBlock, uint256 _startBlock, address _randomSource) Ownable() {
        require(_randomSource != address(0), "ResourceFarm: Invalid random source address");
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        randomSource = ProvableRandom(_randomSource);
    }

    /**
     * @notice Returns the number of pools in the farm.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Add a new lp to the pool.
     * @dev Can only be called by the owner.
     * @param _allocPoint Allocation points for this pool.
     * @param _lpToken Address of the LP token.
     * @param _rewardToken Address of the reward token.
     * @param _rareRewardToken Address of the rare reward token.
     * @param _rareDropChanceBps Chance in basis points (0-10000) to get a rare drop on harvest.
     * @param _rareDropAmount Amount of rare token to drop.
     * @param _withUpdate True if the pools should be updated, false otherwise.
     * @notice REQUIRE: The ResourceFarm contract MUST have the MINTER_ROLE for the _rewardToken and _rareRewardToken (if provided).
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IMintableERC20 _rewardToken,
        IMintableERC20 _rareRewardToken,
        uint16 _rareDropChanceBps,
        uint256 _rareDropAmount,
        bool _withUpdate
    ) external onlyOwner {
        require(_rareDropChanceBps <= 10000, "ResourceFarm: Chance must be <= 10000");
        if (_rareDropChanceBps > 0) {
            require(address(_rareRewardToken) != address(0), "ResourceFarm: Rare token needed for chance > 0");
            require(_rareDropAmount > 0, "ResourceFarm: Rare amount needed for chance > 0");
        }

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardToken: _rewardToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                totalStaked: 0,
                rareRewardToken: _rareRewardToken,
                rareDropChanceBps: _rareDropChanceBps,
                rareDropAmount: _rareDropAmount
            })
        );
        emit LogPoolAddition(
            poolInfo.length - 1,
            _allocPoint,
            _lpToken,
            _rewardToken,
            _rareRewardToken,
            _rareDropChanceBps,
            _rareDropAmount
        );
    }

    /**
     * @notice Update the given pool's allocation point.
     * @dev Can only be called by the owner.
     * @param _pid The index of the pool in the poolInfo array.
     * @param _allocPoint New allocation points for this pool.
     * @param _withUpdate True if the pools should be updated, false otherwise.
     */
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogSetPool(_pid, _allocPoint);
    }

    /**
     * @notice Update reward variables for all pools.
     * @dev Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid The index of the pool in the poolInfo array.
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0 || pool.allocPoint == 0 || totalAllocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - pool.lastRewardBlock;
        uint256 poolReward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;

        pool.accRewardPerShare = pool.accRewardPerShare + ((poolReward * 1e18) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param _pid The index of the pool in the poolInfo array.
     * @param _user Address of user.
     * @return Pending reward for the user.
     */
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.totalStaked;

        if (block.number > pool.lastRewardBlock && lpSupply != 0 && pool.allocPoint != 0 && totalAllocPoint != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 poolReward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((poolReward * 1e18) / lpSupply);
        }

        return (user.amount * accRewardPerShare) / 1e18 - user.rewardDebt;
    }

    /**
     * @notice Deposit LP tokens to ResourceFarm for reward token allocation.
     * @param _pid The index of the pool in the poolInfo array.
     * @param _amount Amount of LP tokens to deposit.
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (!user.seedInitialized) {
            bytes32 context = keccak256(abi.encodePacked(msg.sender, _pid));
            try randomSource.initializeSeed(msg.sender, context) {
                user.seedInitialized = true;
            } catch Error(string memory reason) {
                if (keccak256(bytes(reason)) != keccak256(bytes("SeedAlreadyInitialized()"))) {
                    revert(reason);
                }
                user.seedInitialized = true;
            } catch {
                revert("ResourceFarm: Random source initialization failed");
            }
        }

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
            if (pending > 0) {
                _harvestRewards(msg.sender, _pid, pool, user, pending);
            }
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            pool.totalStaked = pool.totalStaked + _amount;
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from ResourceFarm.
     * @param _pid The index of the pool in the poolInfo array.
     * @param _amount Amount of LP tokens to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "ResourceFarm: withdraw amount exceeds balance");

        updatePool(_pid);

        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
        if (pending > 0) {
            _harvestRewards(msg.sender, _pid, pool, user, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalStaked = pool.totalStaked - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @notice Harvest rewards from a specific pool.
     * @param _pid The index of the pool in the poolInfo array.
     */
    function harvest(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = (user.amount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;
        if (pending > 0) {
            _harvestRewards(msg.sender, _pid, pool, user, pending);
        } else {
            _attemptRareDrop(msg.sender, _pid, pool);
            user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18;
        }
    }

    /**
     * @notice Internal function to handle harvesting regular rewards and attempting rare drops.
     */
    function _harvestRewards(address _user, uint256 _pid, PoolInfo storage _pool, UserInfo storage _user_info, uint256 _pending) internal {
        safeRewardTransfer(_pool.rewardToken, _user, _pending);
        emit Harvest(_user, _pid, _pending);

        _attemptRareDrop(_user, _pid, _pool);

        _user_info.rewardDebt = (_user_info.amount * _pool.accRewardPerShare) / 1e18;
    }

    /**
     * @notice Internal function to check and mint rare drops based on ProvableRandom.
     */
    function _attemptRareDrop(address _user, uint256 _pid, PoolInfo storage _pool) internal {
        if (_pool.rareDropChanceBps == 0 || address(_pool.rareRewardToken) == address(0)) {
            return;
        }

        bytes32 context = keccak256(abi.encodePacked(_user, _pid));
        uint256[] memory randomNumbers = randomSource.generateNumbers(_user, context, 1);

        if ((randomNumbers[0] % 10000) < _pool.rareDropChanceBps) {
            safeRewardTransfer(_pool.rareRewardToken, _user, _pool.rareDropAmount);
            emit RareHarvest(_user, _pid, address(_pool.rareRewardToken), _pool.rareDropAmount);
        }
    }

    /**
     * @notice Withdraw without harvesting rewards.
     * @dev Useful for emergency situations.
     * @param _pid The index of the pool in the poolInfo array.
     * @param _amount Amount of LP tokens to withdraw.
     */
    function emergencyWithdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "ResourceFarm: emergency withdraw amount exceeds balance");

        uint256 amount = user.amount;
        user.amount = user.amount - _amount;
        pool.totalStaked = pool.totalStaked - _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e18; // Reset debt based on new amount

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount); // Emits standard withdraw event
    }

    /**
     * @notice Safely transfer reward tokens to the user.
     * @param _rewardToken The reward token contract.
     * @param _to The recipient address.
     * @param _amount The amount to transfer.
     */
    function safeRewardTransfer(IMintableERC20 _rewardToken, address _to, uint256 _amount) internal {
        if (address(_rewardToken) == address(0) || _amount == 0) {
            return;
        }
        _rewardToken.mint(_to, _amount);
    }

    /**
     * @notice Update the reward per block rate.
     * @dev Can only be called by the owner.
     * @param _rewardPerBlock The new reward per block rate.
     */
    function updateEmissionRate(uint256 _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit LogUpdateEmissionRate(_rewardPerBlock);
    }
} 