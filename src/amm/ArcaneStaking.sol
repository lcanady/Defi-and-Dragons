// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title ArcaneStaking
/// @notice Manages staking of LP tokens and reward distribution
contract ArcaneStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastStakeTime;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
        uint256 minStakingTime;
    }

    IERC20 public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public totalAllocPoint;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(uint256 indexed pid, address lpToken, uint256 allocPoint);
    event PoolUpdated(uint256 indexed pid, uint256 allocPoint);

    constructor(IERC20 _rewardToken, uint256 _rewardPerBlock) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
    }

    /// @notice Add a new LP token pool
    /// @param _allocPoint Allocation points for the new pool
    /// @param _lpToken LP token contract address
    /// @param _minStakingTime Minimum time tokens must be staked
    function addPool(uint256 _allocPoint, IERC20 _lpToken, uint256 _minStakingTime) external onlyOwner {
        _massUpdatePools();
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                totalStaked: 0,
                minStakingTime: _minStakingTime
            })
        );

        emit PoolAdded(poolInfo.length - 1, address(_lpToken), _allocPoint);
    }

    /// @notice Update allocation points for a pool
    /// @param _pid Pool ID
    /// @param _allocPoint New allocation points
    function setPool(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        _massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        emit PoolUpdated(_pid, _allocPoint);
    }

    /// @notice View function to see pending rewards
    /// @param _pid Pool ID
    /// @param _user User address
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(pool.totalStaked));
        }

        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    /// @notice Update reward variables for all pools
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool
    /// @param _pid Pool ID
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.totalStaked));
        pool.lastRewardBlock = block.number;
    }

    /// @notice Stake LP tokens
    /// @param _pid Pool ID
    /// @param _amount Amount to stake
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                _safeRewardTransfer(msg.sender, pending);
                emit RewardPaid(msg.sender, _pid, pending);
            }
        }

        if (_amount > 0) {
            pool.lpToken.transferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalStaked = pool.totalStaked.add(_amount);
            user.lastStakeTime = block.timestamp;
        }

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens
    /// @param _pid Pool ID
    /// @param _amount Amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not enough balance");
        require(block.timestamp >= user.lastStakeTime + pool.minStakingTime, "withdraw: minimum staking time not met");

        _updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
            emit RewardPaid(msg.sender, _pid, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
            pool.lpToken.transfer(msg.sender, _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Emergency withdraw without caring about rewards
    /// @param _pid Pool ID
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        pool.totalStaked = pool.totalStaked.sub(amount);
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Safe reward token transfer function
    /// @param _to Recipient address
    /// @param _amount Amount to transfer
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.transfer(_to, rewardBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    /// @notice Update reward per block
    /// @param _rewardPerBlock New reward per block
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        _massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }
}
