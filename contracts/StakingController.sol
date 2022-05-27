// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SCToken.sol";
import "./RCToken.sol";

contract StakingController is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Staking user for a pool
    struct UserInfo {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 accumulatedRewards; // The reward tokens quantity the user can harvest
    }

    // Staking pool
    struct PoolInfo {
        IERC20 stakeToken; // Token to be staked
        uint256 allocPoint; // Total tokens staked
        uint256 lastRewardedBlock; // Last block number the user had their rewards calculated
        uint256 accTokenPerShare;
    }

    RCToken public rewardToken;

    PoolInfo[] internal pools;
    mapping (address => UserInfo) public userInfo;
    uint256 public tokensPerBlock;

    uint256 public totalAllocPoint;
    address public devaddr;

    event Deposit(address indexed user,  uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor (
        uint256 _tokenPerBlock,
        SCToken _stakingToken,
        RCToken _rewardToken,
        address _devaddr
    ) {
        totalAllocPoint = 10000;
         pools.push(PoolInfo({
            stakeToken: _stakingToken,
            allocPoint: 10000,
            lastRewardedBlock: block.number,
            accTokenPerShare: 0
        }));

        rewardToken = _rewardToken;
        devaddr = _devaddr;
        tokensPerBlock = _tokenPerBlock;
    }

    function pendingToken(address _user)
        external view returns(uint256) {
        PoolInfo storage pool = pools[0];
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.stakeToken.balanceOf(address(this));
        if(block.number > pool.lastRewardedBlock && lpSupply != 0){
            uint256 numBlocks = block.number - pool.lastRewardedBlock;
            uint256 reward = numBlocks.mul(tokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(reward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.accumulatedRewards);
    }
    
    function updateStakingPool() internal {
        uint256 length = pools.length;
        uint256 points = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            points = points.add(pools[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(pools[0].allocPoint).add(points);
            pools[0].allocPoint = points;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = pools[0];
        if (block.number <= pool.lastRewardedBlock) {
            return;
        }
        uint256 lpSupply = pool.stakeToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardedBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardedBlock, block.number);
        uint256 rewardTokenReward = multiplier.mul(tokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        rewardToken.mint(devaddr, rewardTokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokensPerBlock.mul(1e12).div(lpSupply));
        pool.lastRewardedBlock = block.number;
    }

    // Stake rewardToken tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = pools[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.accumulatedRewards);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.accumulatedRewards = user.amount.mul(pool.accTokenPerShare).div(1e12);

        rewardToken.mint(msg.sender, _amount);

        emit Deposit(msg.sender,  _amount);
    }

    // Withdraw rewardToken tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = pools[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.accumulatedRewards);
        if(pending > 0) {
            safeTokenTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.accumulatedRewards = user.amount.mul(pool.accTokenPerShare).div(1e12);

        rewardToken.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBal) {
            transferSuccess = rewardToken.transfer(_to, tokenBal);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }


    function deposit(uint256 _amount) external {
        PoolInfo storage pool = pools[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e18).sub(user.accumulatedRewards);
            if (pending > 0) {
                safeTokenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.accumulatedRewards = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = pools[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.accumulatedRewards);
        if (pending > 0) {
            safeTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.accumulatedRewards = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }


}