// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JediStaking is Ownable {  
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

    constructor() {
        _rewardPercent = 20;
        _rewardRate = 5 seconds;
        _lockTime = 5 seconds;
        _lpToken = ERC20(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        _rewardToken = ERC20(0xFa2bEB1ab1F5fb849Dc5981B88c2E1CdFB51f482);
    }

    // for testing
    function setRewardToken(address _token) external onlyOwner returns(bool) {
        _rewardToken = ERC20(_token);

        return true;
    }

    // for testing
    function setLPToken(address _token) external onlyOwner returns(bool) {
        _lpToken = ERC20(_token);

        return true;
    }

    function setRewardPercent(uint256 _newPercent) external onlyOwner returns(bool) {
        require(_newPercent > 0 && _newPercent < 100, "Enter number between 0-100");
        _rewardPercent = _newPercent;

        return true;
    }

    function setRewardRate(uint256 _newRate) external onlyOwner returns(bool) {
        require(_newRate > 0, "RewardRate cannot be zero");
        _rewardRate = _newRate;

        return true;
    }

    function setLockTime(uint256 _newTime) external onlyOwner returns(bool) {
        require(_newTime > 0, "LockTime cannot be zero");
        _lockTime = _newTime;

        return true;
    }

    
    function stake(uint256 _amount) external returns(bool) {
        _lpToken.transferFrom(msg.sender, address(this), _amount);

        Staker storage s = _stakers[msg.sender];
        s.amount += _amount;
        s.stakeTime = block.timestamp;
        s.claimed = 0;

        return true;
    }

    function claim() external returns(bool) {
        Staker storage c = _stakers[msg.sender];

        require(c.amount > 0, "You did not staked");

        unchecked {
            uint256 reward = ((c.amount * _rewardPercent) / 100) * ((block.timestamp - c.stakeTime) / _rewardRate) - c.claimed;
            if(reward > 0) {
                _rewardToken.transfer(msg.sender, reward);
            } 
            c.claimed += reward;  
        }
           
        return true; 
    }

    function unstake() external returns(bool) {
        Staker storage u = _stakers[msg.sender];

        require(u.amount > 0, "You did not staked");
        require(u.stakeTime + _lockTime <= block.timestamp, "Lock time is not expired");

        unchecked {
            uint256 reward = ((u.amount * _rewardPercent) / 100) * ((block.timestamp - u.stakeTime) / _rewardRate) - u.claimed;
            
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

