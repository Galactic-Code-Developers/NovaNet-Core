// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIAuditLogger.sol";
import "./NovaNetValidator.sol";

contract AIValidatorSelection is Ownable, ReentrancyGuard {
    struct ValidatorScore {
        address validator;
        uint256 performanceScore;
        uint256 reputationScore;
        uint256 totalScore;
    }

    mapping(address => uint256) public lastSelectedEpoch;
    uint256 public validatorReputationWeight = 40; // Percentage weight given to reputation in selection
    uint256 public validatorPerformanceWeight = 60; // Percentage weight given to performance
    uint256 public epochInterval = 100; // Blocks per validator rotation

    NovaNetValidator public validatorContract;
    AIValidatorReputation public reputationContract;
    AIAuditLogger public auditLogger;

    event ValidatorRanked(address indexed validator, uint256 totalScore);
    event BestValidatorSelected(address indexed bestValidator);
    event ValidatorSelectionParametersUpdated(uint256 reputationWeight, uint256 performanceWeight, uint256 epochInterval);

    constructor(
        address _validatorContract,
        address _reputationContract,
        address _auditLogger
    ) {
        validatorContract = NovaNetValidator(_validatorContract);
        reputationContract = AIValidatorReputation(_reputationContract);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice Calculates AI-driven ranking for validators.
    function rankValidators() public view returns (ValidatorScore[] memory) {
        address[] memory validators = validatorContract.getActiveValidators();
        ValidatorScore[] memory scores = new ValidatorScore[](validators.length);

        for (uint256 i = 0; i < validators.length; i++) {
            uint256 performanceScore = validatorContract.getPerformance(validators[i]);
            uint256 reputationScore = reputationContract.getReputation(validators[i]);

            uint256 totalScore = (performanceScore * validatorPerformanceWeight / 100) + 
                                 (reputationScore * validatorReputationWeight / 100);

            scores[i] = ValidatorScore(validators[i], performanceScore, reputationScore, totalScore);
        }

        return scores;
    }

    /// @notice Selects the best validator based on AI rankings.
    function selectBestValidator() public returns (address) {
        ValidatorScore[] memory scores = rankValidators();
        address bestValidator = address(0);
        uint256 highestScore = 0;

        for (uint256 i = 0; i < scores.length; i++) {
            if (scores[i].totalScore > highestScore) {
                highestScore = scores[i].totalScore;
                bestValidator = scores[i].validator;
            }
        }

        lastSelectedEpoch[bestValidator] = block.number;
        
        // AI Audit Logging
        string memory auditEntry = string(
            abi.encodePacked(
                "Validator Selected: ", toAsciiString(bestValidator),
                " | Total Score: ", uintToString(highestScore)
            )
        );
        auditLogger.logGovernanceAction(block.number, auditEntry);

        emit BestValidatorSelected(bestValidator);
        return bestValidator;
    }

    /// @notice Updates AI-based validator selection parameters.
    function updateSelectionParameters(uint256 _reputationWeight, uint256 _performanceWeight, uint256 _epochInterval) external onlyOwner {
        require(_reputationWeight + _performanceWeight == 100, "Total must equal 100%.");
        require(_epochInterval >= 50, "Epoch interval must be at least 50 blocks.");

        validatorReputationWeight = _reputationWeight;
        validatorPerformanceWeight = _performanceWeight;
        epochInterval = _epochInterval;

        emit ValidatorSelectionParametersUpdated(_reputationWeight, _performanceWeight, _epochInterval);
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
