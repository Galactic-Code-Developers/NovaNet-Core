// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AIAuditLogger is Ownable, ReentrancyGuard {
    struct AuditLog {
        uint256 timestamp;
        string category;
        string action;
        uint256 amount;
        address executor;
    }

    AuditLog[] public auditLogs;
    uint256 public maxLogs = 1000; // Maximum logs before cleanup
    mapping(uint256 => AuditLog) public indexedLogs;

    event AuditLogged(uint256 timestamp, string category, string action, uint256 amount, address indexed executor);
    event MaxLogsUpdated(uint256 newMaxLogs);
    event LogsCleared(uint256 removedCount);

    /// @notice Logs governance, validator, and treasury actions for AI-based audit analysis.
    function logGovernanceAction(uint256 _actionId, string memory _actionDescription) external onlyOwner {
        _logAction("Governance", _actionDescription, 0, msg.sender);
    }

    function logValidatorAction(address _validator, string memory _actionDescription, uint256 _amount) external onlyOwner {
        _logAction("Validator", _actionDescription, _amount, _validator);
    }

    function logTreasuryAction(string memory _actionDescription, uint256 _amount, address _recipient) external onlyOwner {
        _logAction("Treasury", _actionDescription, _amount, _recipient);
    }

    /// @notice Internal function to store audit logs.
    function _logAction(string memory _category, string memory _action, uint256 _amount, address _executor) internal {
        AuditLog memory newLog = AuditLog({
            timestamp: block.timestamp,
            category: _category,
            action: _action,
            amount: _amount,
            executor: _executor
        });

        auditLogs.push(newLog);
        indexedLogs[auditLogs.length] = newLog;

        // Limit log size to prevent excessive storage consumption
        if (auditLogs.length > maxLogs) {
            removeOldestLog();
        }

        emit AuditLogged(block.timestamp, _category, _action, _amount, _executor);
    }

    /// @notice Sets the maximum number of stored logs.
    function updateMaxLogs(uint256 _newMax) external onlyOwner {
        require(_newMax > 100, "Minimum log storage must be at least 100.");
        maxLogs = _newMax;
        emit MaxLogsUpdated(_newMax);
    }

    /// @notice Removes the oldest audit log to maintain storage efficiency.
    function removeOldestLog() internal {
        require(auditLogs.length > 0, "No logs to remove.");
        uint256 logsRemoved = auditLogs.length - maxLogs;
        for (uint256 i = 0; i < logsRemoved; i++) {
            delete indexedLogs[i];
        }
        auditLogs = auditLogs[logsRemoved:]; // Trims the array
        emit LogsCleared(logsRemoved);
    }

    /// @notice Retrieves all stored audit logs.
    function getAllLogs() external view returns (AuditLog[] memory) {
        return auditLogs;
    }

    /// @notice Retrieves a specific log by index.
    function getLogByIndex(uint256 _index) external view returns (AuditLog memory) {
        require(_index < auditLogs.length, "Log index out of bounds.");
        return indexedLogs[_index];
    }

    /// @notice Retrieves the most recent audit log.
    function getLatestLog() external view returns (AuditLog memory) {
        require(auditLogs.length > 0, "No logs available.");
        return auditLogs[auditLogs.length - 1];
    }
}
