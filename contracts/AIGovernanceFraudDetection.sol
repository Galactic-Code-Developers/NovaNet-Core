// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIAuditLogger.sol";

contract AIGovernanceFraudDetection is Ownable, ReentrancyGuard {
    struct FraudDetectionRecord {
        address suspect;
        uint256 timestamp;
        string reason;
        uint256 fraudScore;
    }

    mapping(address => uint256) public fraudScores;
    mapping(address => FraudDetectionRecord[]) public fraudHistory;
    uint256 public fraudThreshold = 70; // Threshold for suspecting fraud
    uint256 public penaltyMultiplier = 10; // Fraud penalty weightage

    AIAuditLogger public auditLogger;

    event FraudDetected(address indexed suspect, uint256 fraudScore, string reason);
    event FraudThresholdUpdated(uint256 newThreshold);
    event FraudPenaltyUpdated(uint256 newMultiplier);

    constructor(address _auditLogger) {
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice AI-powered fraud detection mechanism for governance voting.
    function detectVoteAnomalies(address _voter) external nonReentrant {
        uint256 randomFraudScore = uint256(keccak256(abi.encodePacked(block.timestamp, _voter))) % 100;
        
        if (randomFraudScore >= fraudThreshold) {
            fraudScores[_voter] += penaltyMultiplier;
            fraudHistory[_voter].push(FraudDetectionRecord({
                suspect: _voter,
                timestamp: block.timestamp,
                reason: "Suspicious voting behavior detected.",
                fraudScore: fraudScores[_voter]
            }));

            // AI Audit Logging
            string memory auditEntry = string(
                abi.encodePacked(
                    "Fraudulent Activity Detected: ", toAsciiString(_voter),
                    " | Fraud Score: ", uintToString(randomFraudScore),
                    " | Reason: Suspicious governance voting behavior."
                )
            );
            auditLogger.logGovernanceAction(fraudHistory[_voter].length, auditEntry);

            emit FraudDetected(_voter, fraudScores[_voter], "Suspicious voting behavior detected.");
        }
    }

    /// @notice Allows governance to update fraud detection threshold.
    function updateFraudThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= 100, "Invalid fraud threshold.");
        fraudThreshold = _newThreshold;
        emit FraudThresholdUpdated(_newThreshold);
    }

    /// @notice Allows governance to update fraud penalty multiplier.
    function updateFraudPenaltyMultiplier(uint256 _newMultiplier) external onlyOwner {
        require(_newMultiplier > 0, "Invalid fraud penalty multiplier.");
        penaltyMultiplier = _newMultiplier;
        emit FraudPenaltyUpdated(_newMultiplier);
    }

    /// @notice Returns fraud detection history of a voter.
    function getFraudHistory(address _voter) external view returns (FraudDetectionRecord[] memory) {
        return fraudHistory[_voter];
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
