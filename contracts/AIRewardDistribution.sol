// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIAuditLogger.sol";
import "./NovaNetStaking.sol";

contract AIRewardDistribution is Ownable, ReentrancyGuard {
    struct RewardInfo {
        address recipient;
        uint256 amount;
        uint256 timestamp;
    }

    uint256 public baseRewardRate = 5; // Base reward percentage
    uint256 public reputationMultiplier = 20; // Extra rewards for high reputation
    uint256 public performanceMultiplier = 15; // Extra rewards for high-performing validators
    uint256 public totalDistributedRewards;

    mapping(address => uint256) public lastClaimedReward;
    RewardInfo[] public rewardHistory;

    NovaNetStaking public stakingContract;
    AIValidatorReputation public reputationContract;
    AIAuditLogger public auditLogger;

    event RewardDistributed(address indexed recipient, uint256 amount, uint256 timestamp);
    event RewardParametersUpdated(uint256 baseRewardRate, uint256 reputationMultiplier, uint256 performanceMultiplier);

    constructor(
        address _stakingContract,
        address _reputationContract,
        address _auditLogger
    ) {
        stakingContract = NovaNetStaking(_stakingContract);
        reputationContract = AIValidatorReputation(_reputationContract);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice AI-driven calculation of staking rewards.
    function calculateReward(address _staker, uint256 _rewardPool) public view returns (uint256) {
        uint256 stakedAmount = stakingContract.getStakeAmount(_staker);
        uint256 reputationScore = reputationContract.getReputation(_staker);
        
        uint256 baseReward = (stakedAmount * baseRewardRate) / 100;
        uint256 reputationBonus = (baseReward * reputationScore * reputationMultiplier) / 10000;
        uint256 totalReward = baseReward + reputationBonus;

        if (totalReward > _rewardPool) {
            totalReward = _rewardPool;
        }

        return totalReward;
    }

    /// @notice Distributes staking rewards based on AI scoring.
    function distributeRewards() external onlyOwner nonReentrant {
        address[] memory stakers = stakingContract.getStakers();
        uint256 rewardPool = address(this).balance / 10; // 10% of contract balance allocated for rewards

        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 reward = calculateReward(stakers[i], rewardPool);
            if (reward > 0) {
                payable(stakers[i]).transfer(reward);
                lastClaimedReward[stakers[i]] = block.timestamp;
                totalDistributedRewards += reward;

                rewardHistory.push(RewardInfo({
                    recipient: stakers[i],
                    amount: reward,
                    timestamp: block.timestamp
                }));

                // AI Audit Logging
                string memory auditEntry = string(
                    abi.encodePacked(
                        "Reward Distributed: ", uintToString(reward),
                        " | Recipient: ", toAsciiString(stakers[i])
                    )
                );
                auditLogger.logGovernanceAction(rewardHistory.length, auditEntry);

                emit RewardDistributed(stakers[i], reward, block.timestamp);
            }
        }
    }

    /// @notice Updates reward distribution parameters.
    function updateRewardParameters(uint256 _baseRate, uint256 _reputationMultiplier, uint256 _performanceMultiplier) external onlyOwner {
        require(_baseRate > 0 && _reputationMultiplier > 0 && _performanceMultiplier > 0, "Values must be greater than zero.");
        baseRewardRate = _baseRate;
        reputationMultiplier = _reputationMultiplier;
        performanceMultiplier = _performanceMultiplier;

        emit RewardParametersUpdated(_baseRate, _reputationMultiplier, _performanceMultiplier);
    }

    /// @notice Returns total distributed rewards.
    function getTotalDistributedRewards() external view returns (uint256) {
        return totalDistributedRewards;
    }

    /// @notice Returns the reward history.
    function getRewardHistory() external view returns (RewardInfo[] memory) {
        return rewardHistory;
    }

    /// @notice Converts an address to a string.
    function toAsciiString(address _addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_addr);
        bytes memory hexString = new bytes(42);

        hexString[0] = "0";
        hexString[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            bytes1 byteValue = addressBytes[i];
            hexString[2 + (i * 2)] = byteToHexChar(uint8(byteValue) / 16);
            hexString[3 + (i * 2)] = byteToHexChar(uint8(byteValue) % 16);
        }

        return string(hexString);
    }

    /// @notice Converts a byte to a hex character.
    function byteToHexChar(uint8 _byte) internal pure returns (bytes1) {
        if (_byte < 10) {
            return bytes1(uint8(_byte) + 48); // ASCII '0' to '9'
        } else {
            return bytes1(uint8(_byte) + 87); // ASCII 'a' to 'f'
        }
    }

    /// @notice Converts a uint256 to a string.
    function uintToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) return "0";
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}
