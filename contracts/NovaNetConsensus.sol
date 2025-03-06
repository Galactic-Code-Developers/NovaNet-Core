// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorSelection.sol";
import "./AIValidatorReputation.sol";
import "./AISlashingMonitor.sol";
import "./AIGovernanceFraudDetection.sol";
import "./NovaNetStaking.sol";

contract NovaNetConsensus is Ownable, ReentrancyGuard {
    struct Validator {
        address validatorAddress;
        uint256 stakedAmount;
        uint256 lastBlockProduced;
        bool isActive;
    }

    mapping(address => Validator) public validators;
    address[] public activeValidators;
    uint256 public totalStaked;
    uint256 public epochBlockCount = 100; // Epoch cycle for validator rotation

    AIValidatorSelection public validatorSelection;
    AIValidatorReputation public reputationContract;
    AISlashingMonitor public slashingMonitor;
    AIGovernanceFraudDetection public fraudDetection;
    NovaNetStaking public stakingContract;

    event ValidatorRegistered(address indexed validator, uint256 stakeAmount);
    event ValidatorSlashed(address indexed validator, uint256 penalty);
    event ValidatorRemoved(address indexed validator);
    event NewEpochStarted(uint256 epoch, address[] newValidators);
    event BlockProduced(address indexed validator, uint256 blockNumber);
    event EpochUpdated(uint256 epochBlockCount);

    constructor(
        address _validatorSelection,
        address _reputationContract,
        address _slashingMonitor,
        address _fraudDetection,
        address _stakingContract
    ) {
        validatorSelection = AIValidatorSelection(_validatorSelection);
        reputationContract = AIValidatorReputation(_reputationContract);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
        stakingContract = NovaNetStaking(_stakingContract);
    }

    /// @notice Registers a validator into the NovaNet Q-DPoS system.
    function registerValidator(uint256 _stakeAmount) external nonReentrant {
        require(_stakeAmount >= 10_000 ether, "Minimum stake required: 10,000 NOVA");
        require(validators[msg.sender].validatorAddress == address(0), "Validator already registered");

        stakingContract.stake(msg.sender, _stakeAmount);
        totalStaked += _stakeAmount;

        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            stakedAmount: _stakeAmount,
            lastBlockProduced: block.number,
            isActive: true
        });

        activeValidators.push(msg.sender);
        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /// @notice AI-based validator selection process for epoch rotations.
    function startNewEpoch() external onlyOwner {
        address[] memory selectedValidators = validatorSelection.rankValidators();

        require(selectedValidators.length > 0, "No active validators available");

        // Deactivate previous validators
        for (uint256 i = 0; i < activeValidators.length; i++) {
            validators[activeValidators[i]].isActive = false;
        }

        // Activate new selected validators
        activeValidators = selectedValidators;
        for (uint256 i = 0; i < selectedValidators.length; i++) {
            validators[selectedValidators[i]].isActive = true;
        }

        emit NewEpochStarted(block.number / epochBlockCount, selectedValidators);
    }

    /// @notice Records block production and updates last produced block
    function produceBlock() external {
        require(validators[msg.sender].isActive, "Only active validators can produce blocks");
        
        validators[msg.sender].lastBlockProduced = block.number;
        emit BlockProduced(msg.sender, block.number);
    }

    /// @notice AI-powered slashing mechanism for misbehaving validators.
    function slashValidator(address _validator, uint256 _penalty) external onlyOwner {
        require(validators[_validator].isActive, "Validator is not active");
        require(_penalty <= validators[_validator].stakedAmount, "Penalty exceeds stake");

        validators[_validator].stakedAmount -= _penalty;
        totalStaked -= _penalty;

        slashingMonitor.recordSlashing(_validator, _penalty);
        emit ValidatorSlashed(_validator, _penalty);
    }

    /// @notice Removes an inactive or penalized validator from the system.
    function removeValidator(address _validator) external onlyOwner {
        require(validators[_validator].validatorAddress != address(0), "Validator does not exist");
        
        validators[_validator].isActive = false;
        stakingContract.unstake(_validator, validators[_validator].stakedAmount);
        delete validators[_validator];

        for (uint256 i = 0; i < activeValidators.length; i++) {
            if (activeValidators[i] == _validator) {
                activeValidators[i] = activeValidators[activeValidators.length - 1];
                activeValidators.pop();
                break;
            }
        }

        emit ValidatorRemoved(_validator);
    }

    /// @notice Updates the number of blocks per epoch cycle.
    function updateEpochBlockCount(uint256 _newEpochBlockCount) external onlyOwner {
        require(_newEpochBlockCount >= 50, "Minimum epoch block count is 50");
        epochBlockCount = _newEpochBlockCount;
        emit EpochUpdated(_newEpochBlockCount);
    }

    /// @notice Returns the list of active validators.
    function getActiveValidators() external view returns (address[] memory) {
        return activeValidators;
    }

    /// @notice Returns validator details.
    function getValidatorInfo(address _validator) external view returns (
        uint256 stakedAmount, uint256 lastBlockProduced, bool isActive
    ) {
        Validator storage validator = validators[_validator];
        return (validator.stakedAmount, validator.lastBlockProduced, validator.isActive);
    }
}
