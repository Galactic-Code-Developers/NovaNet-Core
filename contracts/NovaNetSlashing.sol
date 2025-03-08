// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIGovernanceFraudDetection.sol";
import "./AIValidatorSelection.sol";
import "./AISlashingPredictor.sol";
import "./AIReputationRecovery.sol";
import "./QuantumSecureHasher.sol";
import "./QuantumEntangledBridge.sol";
import "./NovaNetStaking.sol";

contract NovaNetSlashing is Ownable, ReentrancyGuard {
    struct SlashingRecord {
        address validator;
        uint256 penaltyAmount;
        uint256 blockNumber;
        string reason;
        string quantumHash; // Quantum-secure verification
    }

    mapping(address => uint256) public validatorSlashingCount;
    mapping(address => SlashingRecord[]) public slashingHistory;
    mapping(address => bool) public flaggedValidators;

    uint256 public minPenalty = 100 ether; // Minimum slashing penalty
    uint256 public maxPenalty = 5000 ether; // Maximum slashing penalty

    AIValidatorReputation public reputationContract;
    AIGovernanceFraudDetection public fraudDetection;
    AIValidatorSelection public validatorSelection;
    AISlashingPredictor public slashingPredictor;
    AIReputationRecovery public reputationRecovery;
    QuantumSecureHasher public quantumHasher;
    QuantumEntangledBridge public quantumBridge;
    NovaNetStaking public stakingContract;

    event ValidatorSlashed(address indexed validator, uint256 penalty, string reason, string quantumHash);
    event SlashingPenaltyUpdated(uint256 minPenalty, uint256 maxPenalty);
    event SlashingAppealSuccessful(address indexed validator, uint256 restoredAmount);
    event ReputationAdjusted(address indexed validator, uint256 newReputationScore);
    event ValidatorFlagged(address indexed validator, string reason);

    constructor(
        address _reputationContract,
        address _fraudDetection,
        address _validatorSelection,
        address _slashingPredictor,
        address _reputationRecovery,
        address _quantumHasher,
        address _quantumBridge,
        address _stakingContract
    ) {
        reputationContract = AIValidatorReputation(_reputationContract);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
        validatorSelection = AIValidatorSelection(_validatorSelection);
        slashingPredictor = AISlashingPredictor(_slashingPredictor);
        reputationRecovery = AIReputationRecovery(_reputationRecovery);
        quantumHasher = QuantumSecureHasher(_quantumHasher);
        quantumBridge = QuantumEntangledBridge(_quantumBridge);
        stakingContract = NovaNetStaking(_stakingContract);
    }

    /// @notice AI-powered slashing mechanism with quantum security.
    function slashValidator(address _validator, uint256 _penalty, string memory _reason) external onlyOwner {
        require(_penalty >= minPenalty && _penalty <= maxPenalty, "Penalty out of allowed range");
        require(stakingContract.getStakedAmount(_validator) >= _penalty, "Insufficient stake for slashing");

        // Quantum-Secure Hashing for Data Integrity
        string memory quantumHash = quantumHasher.generateQuantumHash(_validator, _penalty, _reason);

        // Apply penalty
        stakingContract.slashStake(_validator, _penalty);
        validatorSlashingCount[_validator]++;
        slashingHistory[_validator].push(SlashingRecord({
            validator: _validator,
            penaltyAmount: _penalty,
            blockNumber: block.number,
            reason: _reason,
            quantumHash: quantumHash
        }));

        // Adjust reputation based on slashing events
        uint256 newReputation = reputationContract.adjustReputation(_validator, _penalty);
        emit ReputationAdjusted(_validator, newReputation);

        emit ValidatorSlashed(_validator, _penalty, _reason, quantumHash);
    }

    /// @notice AI-powered predictive slashing warning.
    function flagValidator(address _validator) external onlyOwner {
        bool isRisky = slashingPredictor.detectValidatorRisk(_validator);
        require(isRisky, "Validator not flagged for risky behavior.");

        flaggedValidators[_validator] = true;
        emit ValidatorFlagged(_validator, "AI-Predicted high-risk behavior detected.");
    }

    /// @notice Allows governance to update slashing penalty ranges.
    function updateSlashingPenalty(uint256 _minPenalty, uint256 _maxPenalty) external onlyOwner {
        require(_minPenalty > 0 && _maxPenalty >= _minPenalty, "Invalid penalty range");
        minPenalty = _minPenalty;
        maxPenalty = _maxPenalty;
        emit SlashingPenaltyUpdated(_minPenalty, _maxPenalty);
    }

    /// @notice AI-powered slashing appeal mechanism.
    function appealSlashing(address _validator, uint256 _penalty) external onlyOwner {
        require(validatorSlashingCount[_validator] > 0, "No slashing records for validator");
        
        // Use AI to determine if validator should be restored
        bool shouldRestore = reputationRecovery.shouldRestoreReputation(_validator);
        require(shouldRestore, "Validator does not meet appeal conditions.");

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
