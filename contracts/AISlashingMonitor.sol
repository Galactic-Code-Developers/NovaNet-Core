// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIAuditLogger.sol";
import "./AIValidatorReputation.sol";
import "./NovaNetStaking.sol";

contract AISlashingMonitor is Ownable, ReentrancyGuard {
    struct SlashingRecord {
        address validator;
        uint256 penaltyAmount;
        uint256 timestamp;
        string reason;
    }

    mapping(address => uint256) public validatorOffenseCount;
    mapping(address => SlashingRecord[]) public slashingHistory;
    uint256 public minPenalty = 100 ether; // Minimum slashing penalty
    uint256 public maxPenalty = 5000 ether; // Maximum slashing penalty

    NovaNetStaking public stakingContract;
    AIValidatorReputation public reputationContract;
    AIAuditLogger public auditLogger;

    event ValidatorSlashed(address indexed validator, uint256 penalty, string reason);
    event SlashingAppealSuccessful(address indexed validator, uint256 restoredAmount);
    event SlashingPenaltyUpdated(uint256 minPenalty, uint256 maxPenalty);

    constructor(
        address _stakingContract,
        address _reputationContract,
        address _auditLogger
    ) {
        stakingContract = NovaNetStaking(_stakingContract);
        reputationContract = AIValidatorReputation(_reputationContract);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice AI-powered slashing mechanism for validators violating network rules.
    function slashValidator(address _validator, uint256 _penalty, string memory _reason) external onlyOwner {
        require(_penalty >= minPenalty && _penalty <= maxPenalty, "Penalty out of allowed range");
        require(stakingContract.getStakeAmount(_validator) >= _penalty, "Insufficient stake for slashing");

        // Apply penalty
        stakingContract.slashStake(_validator, _penalty);
        validatorOffenseCount[_validator]++;
        slashingHistory[_validator].push(SlashingRecord({
            validator: _validator,
            penaltyAmount: _penalty,
            timestamp: block.timestamp,
            reason: _reason
        }));

        // AI Audit Logging
        string memory auditEntry = string(
            abi.encodePacked(
                "Validator Slashed: ", toAsciiString(_validator),
                " | Penalty: ", uintToString(_penalty),
                " | Reason: ", _reason
            )
        );
        auditLogger.logGovernanceAction(slashingHistory[_validator].length, auditEntry);

        emit ValidatorSlashed(_validator, _penalty, _reason);
    }

    /// @notice Allows a validator to appeal slashing penalties.
    function appealSlashing(address _validator, uint256 _penalty) external onlyOwner {
        require(validatorOffenseCount[_validator] > 0, "No slashing records for validator.");
        
        // Restore part of the slashed amount if appeal is valid
        uint256 restoredAmount = _penalty / 2;
        stakingContract.restoreStake(_validator, restoredAmount);
        validatorOffenseCount[_validator]--;

        emit SlashingAppealSuccessful(_validator, restoredAmount);
    }

    /// @notice Updates slashing penalty ranges via governance.
    function updateSlashingPenalty(uint256 _minPenalty, uint256 _maxPenalty) external onlyOwner {
        require(_minPenalty > 0 && _maxPenalty >= _minPenalty, "Invalid penalty range.");
        minPenalty = _minPenalty;
        maxPenalty = _maxPenalty;
        emit SlashingPenaltyUpdated(_minPenalty, _maxPenalty);
    }

    /// @notice Returns slashing history of a validator.
    function getSlashingHistory(address _validator) external view returns (SlashingRecord[] memory) {
        return slashingHistory[_validator];
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
