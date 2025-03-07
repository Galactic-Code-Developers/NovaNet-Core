// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIAuditLogger.sol";
import "./NovaNetStaking.sol";

/// @title AI Reward Distribution - AI-Governed Reward System for NovaNet
/// @notice Distributes staking rewards dynamically based on AI-powered validator reputation, stake weight, and network conditions.
contract AIRewardDistribution is Ownable, ReentrancyGuard {
    
    struct RewardInfo {
        address recipient;
        uint256 amount;
        uint256 timestamp;
        bytes32 quantumHash;
    }

    uint256 public baseRewardRate = 5; // Base percentage rate for rewards
    uint256 public dynamicReputationMultiplier = 15; // AI-adjusted reputation weight
    uint256 public dynamicPerformanceMultiplier = 10; // AI-driven performance weight
    uint256 public totalDistributedRewards;

    mapping(address => uint256) public lastClaimedReward;
    mapping(address => RewardInfo) public rewardHistory;

    NovaNetStaking public stakingContract;
    AIValidatorReputation public reputationContract;
    AIAuditLogger public auditLogger;

    event RewardDistributed(address indexed recipient, uint256 amount, uint256 timestamp, bytes32 quantumHash);
    event RewardParametersUpdated(uint256 baseRewardRate, uint256 dynamicReputationMultiplier, uint256 dynamicPerformanceMultiplier);

    constructor(
        address _stakingContract,
        address _reputationContract,
        address _auditLogger
    ) {
        stakingContract = NovaNetStaking(_stakingContract);
        reputationContract = AIValidatorReputation(_reputationContract);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice AI-powered staking reward calculation.
    function calculateReward(address _staker, uint256 _rewardPool) public view returns (uint256) {
        uint256 stakedAmount = stakingContract.getStakeAmount(_staker);
        uint256 reputationScore = reputationContract.getReputation(_staker);

        // AI-Weighted Reward Calculation
        uint256 baseReward = (stakedAmount * baseRewardRate) / 100;
        uint256 aiWeightedBonus = (baseReward * reputationScore * dynamicReputationMultiplier) / 10000;
        uint256 totalReward = baseReward + aiWeightedBonus;

        return totalReward > _rewardPool ? _rewardPool : totalReward;
    }

    /// @notice Distributes rewards across all stakers using AI-powered ranking.
    function distributeRewards() external onlyOwner nonReentrant {
        address[] memory stakers = stakingContract.getStakers();
        uint256 rewardPool = address(this).balance / 10; // Allocate 10% of contract balance for rewards

        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 reward = calculateReward(stakers[i], rewardPool);
            if (reward > 0) {
                payable(stakers[i]).transfer(reward);
                lastClaimedReward[stakers[i]] = block.timestamp;
                totalDistributedRewards += reward;

                bytes32 quantumHash = generateQuantumHash(stakers[i], reward, block.timestamp);

                rewardHistory[stakers[i]] = RewardInfo({
                    recipient: stakers[i],
                    amount: reward,
                    timestamp: block.timestamp,
                    quantumHash: quantumHash
                });

                // AI Audit Logging
                auditLogger.logAudit("Reward", "Validator Reward Distributed", reward, stakers[i]);

                emit RewardDistributed(stakers[i], reward, block.timestamp, quantumHash);
            }
        }
    }

    /// @notice AI-enhanced reward adjustment model.
    function adjustAIRewardMultipliers(uint256 networkLoadFactor) external onlyOwner {
        require(networkLoadFactor >= 1 && networkLoadFactor <= 100, "Invalid network factor.");

        // Dynamic adjustment based on network conditions
        dynamicReputationMultiplier = 15 + (networkLoadFactor / 10); 
        dynamicPerformanceMultiplier = 10 + (networkLoadFactor / 20);

        emit RewardParametersUpdated(baseRewardRate, dynamicReputationMultiplier, dynamicPerformanceMultiplier);
    }

    /// @dev Generates a quantum-secure hash for reward logs.
    function generateQuantumHash(address recipient, uint256 amount, uint256 timestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            sha256(abi.encodePacked(recipient, amount)),
            keccak256(abi.encodePacked(timestamp))
        ));
    }

    /// @notice Returns total distributed rewards.
    function getTotalDistributedRewards() external view returns (uint256) {
        return totalDistributedRewards;
    }

    /// @notice Retrieves a recipient's last reward information.
    function getRewardInfo(address recipient) external view returns (RewardInfo memory) {
        return rewardHistory[recipient];
    }
}
