// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AITreasuryAdjuster.sol";
import "./AIBudgetOptimizer.sol";
import "./AIReserveManager.sol";
import "./AIAuditLogger.sol";
import "./AIProposalScoring.sol";
import "./AITreasurySimulator.sol";
import "./QuantumSecureHasher.sol";
import "./QuantumEntangledBridge.sol";
import "./AIGovernanceFraudDetection.sol";

contract NovaNetTreasury is Ownable, ReentrancyGuard {
    struct FundAllocation {
        address recipient;
        uint256 amount;
        uint256 timestamp;
        string reason;
        string quantumHash; // Quantum-secure verification
    }

    uint256 public totalTreasuryBalance;
    uint256 public minReserveThreshold = 10_000 ether; // Minimum treasury reserve
    uint256 public maxAllocationPerProposal = 5_000 ether; // Max allocation for any single proposal

    mapping(address => uint256) public entityAllocations;
    FundAllocation[] public allocationHistory;

    AITreasuryAdjuster public treasuryAdjuster;
    AIBudgetOptimizer public budgetOptimizer;
    AIReserveManager public reserveManager;
    AITreasurySimulator public treasurySimulator;
    QuantumSecureHasher public quantumHasher;
    QuantumEntangledBridge public quantumBridge;
    AIAuditLogger public auditLogger;
    AIProposalScoring public proposalScoring;
    AIGovernanceFraudDetection public fraudDetection;

    event TreasuryFunded(address indexed sender, uint256 amount);
    event FundsAllocated(address indexed recipient, uint256 amount, string reason, string quantumHash);
    event TreasuryReserveUpdated(uint256 newReserveThreshold);
    event MaxAllocationUpdated(uint256 newMaxAllocation);
    event TreasuryFraudDetected(address indexed suspect, uint256 flaggedAmount, string reason);

    constructor(
        address _treasuryAdjuster,
        address _budgetOptimizer,
        address _reserveManager,
        address _treasurySimulator,
        address _quantumHasher,
        address _quantumBridge,
        address _auditLogger,
        address _proposalScoring,
        address _fraudDetection
    ) {
        treasuryAdjuster = AITreasuryAdjuster(_treasuryAdjuster);
        budgetOptimizer = AIBudgetOptimizer(_budgetOptimizer);
        reserveManager = AIReserveManager(_reserveManager);
        treasurySimulator = AITreasurySimulator(_treasurySimulator);
        quantumHasher = QuantumSecureHasher(_quantumHasher);
        quantumBridge = QuantumEntangledBridge(_quantumBridge);
        auditLogger = AIAuditLogger(_auditLogger);
        proposalScoring = AIProposalScoring(_proposalScoring);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
    }

    /// @notice Adds funds to the treasury.
    function depositFunds() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        totalTreasuryBalance += msg.value;
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /// @notice Allocates funds using AI-optimized decision making.
    function allocateFunds(address payable _recipient, uint256 _amount, string memory _reason) external onlyOwner nonReentrant {
        require(_amount > 0, "Allocation must be greater than zero.");
        require(_amount <= totalTreasuryBalance, "Insufficient treasury balance.");
        require(_amount <= maxAllocationPerProposal, "Exceeds max allocation limit.");

        // AI-Powered Approval Based on Budget & Reserve Status
        uint256 aiAdjustedAmount = treasuryAdjuster.adjustTreasuryAllocation(_amount);
        uint256 optimizedAmount = budgetOptimizer.optimizeBudgetAllocation(aiAdjustedAmount);
        require(optimizedAmount > 0, "AI has rejected this allocation.");

        // Reserve Check
        require(totalTreasuryBalance - optimizedAmount >= minReserveThreshold, "Insufficient reserves after allocation.");

        // Treasury Stability Check via AI Simulation
        require(treasurySimulator.simulateImpact(totalTreasuryBalance, optimizedAmount), "AI rejects this transaction due to long-term instability risk.");

        // Transfer Funds
        totalTreasuryBalance -= optimizedAmount;
        _recipient.transfer(optimizedAmount);

        // Quantum-Secure Hashing for Data Integrity
        string memory quantumHash = quantumHasher.generateQuantumHash(_recipient, optimizedAmount, _reason);

        allocationHistory.push(FundAllocation({
            recipient: _recipient,
            amount: optimizedAmount,
            timestamp: block.timestamp,
            reason: _reason,
            quantumHash: quantumHash
        }));

        // AI Governance Audit Logging
        string memory auditEntry = string(
            abi.encodePacked(
                "Treasury Allocation: ", uintToString(optimizedAmount),
                " | Recipient: ", toAsciiString(_recipient),
                " | Reason: ", _reason
            )
        );
        auditLogger.logGovernanceAction(allocationHistory.length, auditEntry);

        emit FundsAllocated(_recipient, optimizedAmount, _reason, quantumHash);
    }

    /// @notice AI-driven fraud detection for treasury mismanagement.
    function detectTreasuryFraud(address _suspect, uint256 _flaggedAmount, string memory _reason) external onlyOwner {
        require(fraudDetection.detectFraudulentActivity(_suspect, _flaggedAmount), "No fraud detected.");

        emit TreasuryFraudDetected(_suspect, _flaggedAmount, _reason);
    }

    /// @notice Updates the treasury reserve threshold.
    function updateReserveThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Reserve threshold must be greater than zero.");
        minReserveThreshold = _newThreshold;
        emit TreasuryReserveUpdated(_newThreshold);
    }

    /// @notice Updates the maximum allocation limit per proposal.
    function updateMaxAllocation(uint256 _newMax) external onlyOwner {
        require(_newMax > 0, "Max allocation must be greater than zero.");
        maxAllocationPerProposal = _newMax;
        emit MaxAllocationUpdated(_newMax);
    }

    /// @notice Gets the treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return totalTreasuryBalance;
    }

    /// @notice Returns the allocation history.
    function getAllocationHistory() external view returns (FundAllocation[] memory) {
        return allocationHistory;
    }
}
