// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Staking JDT Tokens contract
/// @author Omur Kubanychbekov, github.com/JediFaust
/// @notice You can use this contract for staking JDT Tokens
/// @dev All functions tested successfully and have no errors

contract JediStaking is Ownable, ReentrancyGuard {  
    using SafeMath for uint256;   
    uint256 private _rewardPercent;
    uint256 private _lockTime;
    uint256 private _rewardRate;
    mapping(address => Staker) private _stakers;

    ERC20 private _lpToken;
    ERC20 private _rewardToken;

    struct Staker {
        uint256 claimed;
        uint256 amount;
        uint256 stakeTime;
    }

   /// @notice Deploys the contract with the initial parameters(lpToken, rewardToken)
   /// @dev Constructor should be used when deploying contract
   /// @param lpToken Address of Liquidity Pool Token contract
   /// @param rewardToken Address of Reward Token contract
    constructor(address lpToken, address rewardToken) {
        _rewardPercent = 20;
        _rewardRate = 10 minutes;
        _lockTime = 20 minutes;
        _lpToken = ERC20(lpToken);
        _rewardToken = ERC20(rewardToken);
    }
    
   /// @notice Sets the reward percent
   /// @dev Only owner can call this function
   /// @param _newPercent Sets natural amount of Reward Percent  
   /// @return true if transaction is successful
    function setRewardPercent(uint256 _newPercent) external onlyOwner returns(bool) {
        require(_newPercent > 0 && _newPercent < 100, "Enter number between 0-100");
        _rewardPercent = _newPercent;

        return true;
    }

   /// @notice Sets the reward rate time 
   /// @dev Only owner can call this function
   /// @param _newRate Sets Reward Rate in seconds
   /// @return true if transaction is successful
    function setRewardRate(uint256 _newRate) external onlyOwner returns(bool) {
        require(_newRate > 0, "RewardRate cannot be zero");
        _rewardRate = _newRate;

        return true;
    }

    /// @notice Sets the lock time for unstaking
    /// @dev Only owner can call this function
    /// @param _newTime Sets Lock Time in seconds
    /// @return true if transaction is successful
    function setLockTime(uint256 _newTime) external onlyOwner returns(bool) {
        require(_newTime > 0, "LockTime cannot be zero");
        _lockTime = _newTime;

        return true;
    }

    /// @notice Stake function
    /// @dev Adds staking amount to caller and,
    /// transfers amount of tokens to contract
    /// adds amount when called again
    /// @param _amount Amount of tokens to stake,
    /// @return true if transaction is successful
    function stake(uint256 _amount) external nonReentrant returns(bool) {
        _lpToken.transferFrom(msg.sender, address(this), _amount);

        Staker storage s = _stakers[msg.sender];
        s.amount += _amount;
        s.stakeTime = block.timestamp;
        s.claimed = 0;

        return true;
    }

    /// @notice Claims reward tokens
    /// @dev Calculates the reward and transfers it to caller
    /// @return true if transaction is successful
    function claim() external nonReentrant returns(bool) {
        Staker storage c = _stakers[msg.sender];

        require(c.amount > 0, "You did not staked");

        unchecked {
            uint256 reward = ((c.amount * _rewardPercent).div(100)) * ((block.timestamp - c.stakeTime).div(_rewardRate)) - c.claimed;
            if(reward > 0) {
                _rewardToken.transfer(msg.sender, reward);
            } 
            c.claimed += reward;  
        }
           
        return true; 
    }

    /// @notice Unstakes tokens
    /// @dev Calculates the left amount of reward,
    ///  and transfers it to caller
    /// clears the total amount and sends
    /// LP tokens to caller back
    /// @return true if transaction is successful
    function unstake() external nonReentrant returns(bool) {
        Staker storage u = _stakers[msg.sender];

        require(u.amount > 0, "You did not staked");
        require(u.stakeTime + _lockTime <= block.timestamp, "Lock time is not expired");

        unchecked {
            uint256 reward = ((u.amount * _rewardPercent).div(100)) * ((block.timestamp - u.stakeTime).div(_rewardRate)) - u.claimed;
            
            if(reward > 0) { 
                _rewardToken.transfer(msg.sender, reward); 
            }
        }

        _lpToken.transfer(msg.sender, u.amount);
        u.amount = 0;
        u.claimed = 0;

        return true;
    }
}

