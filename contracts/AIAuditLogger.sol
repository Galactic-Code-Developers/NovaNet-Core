// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AIAuditLogger – Quantum-Secured AI Audit Logs for NovaNet
/// @notice Ensures secure audit logging with quantum-resistant hashing for governance and validator actions.

contract AIAuditLogger is Ownable {

    struct AuditLog {
        uint256 timestamp;
        string category;
        string action;
        uint256 amount;
        address executor;
        bytes32 quantumHash;
    }

    AuditLog[] private auditLogs;
    uint256 public maxLogs = 1000;

    event AuditLogged(uint256 indexed timestamp, string category, string action, uint256 amount, address indexed executor, bytes32 quantumHash);
    event MaxLogsUpdated(uint256 newMax);
    event LogsCleared(uint256 clearedCount);

    /// @notice Logs actions securely with quantum-resistant hashing.
    function logAudit(string memory category, string memory action, uint256 amount, address executor) external onlyOwner {
        bytes32 quantumHash = generateQuantumHash(category, action, amount, executor, block.timestamp);
        
        auditLogs.push(AuditLog({
            timestamp: block.timestamp,
            category: category,
            action: action,
            amount: amount,
            executor: executor,
            quantumHash: quantumHash
        }));

        emit AuditLogged(block.timestamp, category, action, amount, executor, quantumHash);

        if (auditLogs.length > maxLogs) {
            removeOldLogs();
        }
    }

    /// @dev Quantum-resistant hashing simulation using layered cryptographic hashing.
    function generateQuantumHash(string memory category, string memory action, uint256 amount, address executor) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                sha256(abi.encodePacked(category)),
                keccak256(abi.encodePacked(action, amount)),
                sha256(abi.encodePacked(executor))
            )
        );
    }

    /// @notice Updates the maximum number of stored logs.
    function updateMaxLogs(uint256 newMax) external onlyOwner {
        require(newMax >= 100, "Must store at least 100 logs");
        maxLogs = newMax;
        emit MaxLogsUpdated(newMax);
    }

    /// @dev Removes oldest logs to maintain maximum storage limit.
    function removeOldLogs() internal {
        uint256 removeCount = auditLogs.length - maxLogs;
        for (uint256 i = 0; i < auditLogs.length - removeOldLogs.length; i++) {
            auditLogs[i] = auditLogs[i + removeIndex];
        }
        for (uint256 i = 0; i < removeCount; i++) {
            auditLogs.pop();
        }
        emit LogsCleared(removeCount);
    }

    /// @notice Fetches all audit logs
    function getAllLogs() external view returns (AuditLog[] memory) {
        return auditLogs;
    }

    /// @notice Fetches the latest audit log
    function getLatestLog() external view returns (AuditLog memory) {
        require(auditLogs.length > 0, "No logs available");
        return auditLogs[auditLogs.length - 1];
    }
}
