// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIGovernanceFraudDetection.sol";
import "./AIValidatorSelection.sol";
import "./NovaNetStaking.sol";

contract NovaNetSlashing is Ownable, ReentrancyGuard {
    struct SlashingRecord {
        address validator;
        uint256 penaltyAmount;
        uint256 blockNumber;
        string reason;
    }

    mapping(address => uint256) public validatorSlashingCount;
    mapping(address => SlashingRecord[]) public slashingHistory;

    uint256 public minPenalty = 100 ether; // Minimum slashing penalty
    uint256 public maxPenalty = 5000 ether; // Maximum slashing penalty

    AIValidatorReputation public reputationContract;
    AIGovernanceFraudDetection public fraudDetection;
    AIValidatorSelection public validatorSelection;
    NovaNetStaking public stakingContract;

    event ValidatorSlashed(address indexed validator, uint256 penalty, string reason);
    event SlashingPenaltyUpdated(uint256 minPenalty, uint256 maxPenalty);
    event SlashingAppealSuccessful(address indexed validator, uint256 restoredAmount);
    event ReputationAdjusted(address indexed validator, uint256 newReputationScore);

    constructor(
        address _reputationContract,
        address _fraudDetection,
        address _validatorSelection,
        address _stakingContract
    ) {
        reputationContract = AIValidatorReputation(_reputationContract);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
        validatorSelection = AIValidatorSelection(_validatorSelection);
        stakingContract = NovaNetStaking(_stakingContract);
    }

    /// @notice AI-driven slashing mechanism for validators violating network rules.
    function slashValidator(address _validator, uint256 _penalty, string memory _reason) external onlyOwner {
        require(_penalty >= minPenalty && _penalty <= maxPenalty, "Penalty out of allowed range");
        require(stakingContract.getStakedAmount(_validator) >= _penalty, "Insufficient stake for slashing");

        // Apply penalty
        stakingContract.slashStake(_validator, _penalty);
        validatorSlashingCount[_validator]++;
        slashingHistory[_validator].push(SlashingRecord({
            validator: _validator,
            penaltyAmount: _penalty,
            blockNumber: block.number,
            reason: _reason
        }));

        // Adjust reputation based on slashing events
        uint256 newReputation = reputationContract.adjustReputation(_validator, _penalty);
        emit ReputationAdjusted(_validator, newReputation);

        emit ValidatorSlashed(_validator, _penalty, _reason);
    }

    /// @notice Allows governance to update slashing penalty ranges.
    function updateSlashingPenalty(uint256 _minPenalty, uint256 _maxPenalty) external onlyOwner {
        require(_minPenalty > 0 && _maxPenalty >= _minPenalty, "Invalid penalty range");
        minPenalty = _minPenalty;
        maxPenalty = _maxPenalty;
        emit SlashingPenaltyUpdated(_minPenalty, _maxPenalty);
    }

    /// @notice Allows a validator to appeal slashing penalties.
    function appealSlashing(address _validator, uint256 _penalty) external onlyOwner {
        require(validatorSlashingCount[_validator] > 0, "No slashing records for validator");
        
        // Restore part of the slashed amount if appeal is valid
        uint256 restoredAmount = _penalty / 2;
        stakingContract.restoreStake(_validator, restoredAmount);
        validatorSlashingCount[_validator]--;

        emit SlashingAppealSuccessful(_validator, restoredAmount);
    }

    /// @notice Returns slashing history of a validator.
    function getSlashingHistory(address _validator) external view returns (SlashingRecord[] memory) {
        return slashingHistory[_validator];
    }
}
