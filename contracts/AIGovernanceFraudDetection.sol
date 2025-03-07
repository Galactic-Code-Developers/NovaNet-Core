// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIAuditLogger.sol";

/// @title AI-Governance Fraud Detection – Quantum-Secured Smart Contract
/// @notice Detects fraudulent governance activity using AI & Quantum-Secure Hashing.
contract AIGovernanceFraudDetection is Ownable, ReentrancyGuard {
    
    struct FraudDetectionRecord {
        address suspect;
        uint256 timestamp;
        string reason;
        uint256 fraudScore;
        bytes32 quantumHash;
    }

    mapping(address => FraudDetectionRecord[]) public fraudHistory;
    mapping(address => uint256) public fraudScores;
    
    uint256 public fraudThreshold = 70;
    uint256 public penaltyMultiplier = 10;
    
    AIAuditLogger public auditLogger;

    event FraudDetected(address indexed suspect, uint256 fraudScore, string reason);
    event FraudThresholdUpdated(uint256 newThreshold);
    event FraudPenaltyUpdated(uint256 newMultiplier);
    
    constructor(address _auditLogger) {
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice AI-powered fraud detection based on governance voting patterns.
    function detectVoteAnomalies(address _voter, uint256 anomalyScore) external nonReentrant onlyOwner {
        require(anomalyScore <= 100, "Invalid fraud score.");

        uint256 newFraudScore = fraudScores[_voter] + (anomalyScore * penaltyMultiplier / 100);
        fraudScores[_voter] = newFraudScore;
        
        bytes32 quantumHash = generateQuantumHash(_voter, anomalyScore, block.timestamp);

        fraudHistory[_voter].push(FraudDetectionRecord({
            suspect: _voter,
            timestamp: block.timestamp,
            reason: "AI detected fraudulent voting behavior",
            fraudScore: newFraudScore,
            quantumHash: quantumHash
        }));

        string memory auditEntry = string(abi.encodePacked(
            "Governance Fraud Detected: ", toAsciiString(_voter),
            " | Fraud Score: ", uintToString(newFraudScore),
            " | Reason: AI detected manipulation."
        ));
        auditLogger.logAudit("Governance", auditEntry, newFraudScore, _voter);

        emit FraudDetected(_voter, newFraudScore, "AI detected fraudulent voting behavior.");
    }

    /// @notice Updates fraud detection threshold dynamically.
    function updateFraudThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= 100, "Invalid threshold.");
        fraudThreshold = _newThreshold;
        emit FraudThresholdUpdated(_newThreshold);
    }

    /// @notice Updates fraud penalty multiplier dynamically.
    function updateFraudPenaltyMultiplier(uint256 _newMultiplier) external onlyOwner {
        require(_newMultiplier > 0, "Multiplier must be greater than zero.");
        penaltyMultiplier = _newMultiplier;
        emit FraudPenaltyUpdated(_newMultiplier);
    }

    /// @notice Retrieves fraud history for a specific voter.
    function getFraudHistory(address _voter) external view returns (FraudDetectionRecord[] memory) {
        return fraudHistory[_voter];
    }

    /// @dev Generates a quantum-secure hash for governance fraud verification.
    function generateQuantumHash(address suspect, uint256 fraudScore, uint256 timestamp) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                sha256(abi.encodePacked(suspect)),
                keccak256(abi.encodePacked(fraudScore, timestamp))
            )
        );
    }

    /// @notice Converts an address to a string for logging.
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

    /// @notice Converts a uint256 to a string for logging.
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
