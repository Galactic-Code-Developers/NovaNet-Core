// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIRewardDistribution.sol";
import "./AISlashingMonitor.sol";
import "./AIValidatorReputation.sol";
import "./AIGovernanceFraudDetection.sol";

contract NovaNetStaking is Ownable, ReentrancyGuard {
    struct StakeInfo {
        uint256 amount;
        uint256 lastStakedBlock;
        bool isValidator;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public minValidatorStake = 10_000 ether; // Minimum stake required for validators
    uint256 public minDelegatorStake = 100 ether; // Minimum stake required for delegators
    uint256 public unstakeCooldown = 50; // Blocks before a user can unstake

    AIRewardDistribution public rewardDistribution;
    AISlashingMonitor public slashingMonitor;
    AIValidatorReputation public reputationContract;
    AIGovernanceFraudDetection public fraudDetection;

    event Staked(address indexed user, uint256 amount, bool isValidator);
    event Unstaked(address indexed user, uint256 amount);
    event Slashed(address indexed validator, uint256 penalty);
    event RewardDistributed(address indexed user, uint256 amount);
    event StakingParametersUpdated(uint256 minValidatorStake, uint256 minDelegatorStake, uint256 unstakeCooldown);

    constructor(
        address _rewardDistribution,
        address _slashingMonitor,
        address _reputationContract,
        address _fraudDetection
    ) {
        rewardDistribution = AIRewardDistribution(_rewardDistribution);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        reputationContract = AIValidatorReputation(_reputationContract);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
    }

    /// @notice Allows users to stake funds as a validator or delegator.
    function stake(bool _isValidator) external payable nonReentrant {
        require(msg.value > 0, "Stake amount must be greater than zero.");
        
        if (_isValidator) {
            require(msg.value >= minValidatorStake, "Validator stake must meet minimum.");
        } else {
            require(msg.value >= minDelegatorStake, "Delegator stake must meet minimum.");
        }

        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].lastStakedBlock = block.number;
        stakes[msg.sender].isValidator = _isValidator;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value, _isValidator);
    }

    /// @notice Allows users to unstake funds after cooldown.
    function unstake(uint256 _amount) external nonReentrant {
        require(stakes[msg.sender].amount >= _amount, "Insufficient staked balance.");
        require(block.number >= stakes[msg.sender].lastStakedBlock + unstakeCooldown, "Unstake cooldown in effect.");

        stakes[msg.sender].amount -= _amount;
        totalStaked -= _amount;

        payable(msg.sender).transfer(_amount);
        emit Unstaked(msg.sender, _amount);
    }

    /// @notice AI-powered slashing mechanism for validators violating network rules.
    function slashValidator(address _validator, uint256 _penalty) external onlyOwner {
        require(stakes[_validator].isValidator, "Address is not a validator.");
        require(_penalty <= stakes[_validator].amount, "Penalty exceeds staked amount.");

        stakes[_validator].amount -= _penalty;
        totalStaked -= _penalty;

        slashingMonitor.recordSlashing(_validator, _penalty);
        emit Slashed(_validator, _penalty);
    }

    /// @notice Distributes staking rewards using AI-driven optimization.
    function distributeRewards() external onlyOwner {
        address[] memory stakers = rewardDistribution.getStakers();
        uint256 totalRewards = address(this).balance / 10; // 10% of contract balance as rewards

        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 reward = rewardDistribution.calculateReward(stakers[i], totalRewards);
            payable(stakers[i]).transfer(reward);
            emit RewardDistributed(stakers[i], reward);
        }
    }

    /// @notice Updates staking parameters via governance decisions.
    function updateStakingParameters(uint256 _minValidatorStake, uint256 _minDelegatorStake, uint256 _unstakeCooldown) external onlyOwner {
        require(_minValidatorStake > 0 && _minDelegatorStake > 0, "Stake limits must be greater than zero.");
        require(_unstakeCooldown >= 10, "Unstake cooldown must be at least 10 blocks.");

        minValidatorStake = _minValidatorStake;
        minDelegatorStake = _minDelegatorStake;
        unstakeCooldown = _unstakeCooldown;

        emit StakingParametersUpdated(_minValidatorStake, _minDelegatorStake, _unstakeCooldown);
    }

    /// @notice Returns total staked funds in the contract.
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    /// @notice Returns staked information for a user.
    function getStakeInfo(address _user) external view returns (uint256 amount, uint256 lastStakedBlock, bool isValidator) {
        StakeInfo storage stake = stakes[_user];
        return (stake.amount, stake.lastStakedBlock, stake.isValidator);
    }
}
