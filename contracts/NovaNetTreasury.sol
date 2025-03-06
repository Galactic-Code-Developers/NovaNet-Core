// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AITreasuryAdjuster.sol";
import "./AIBudgetOptimizer.sol";
import "./AIReserveManager.sol";
import "./AIAuditLogger.sol";
import "./AIProposalScoring.sol";

contract NovaNetTreasury is Ownable, ReentrancyGuard {
    struct FundAllocation {
        address recipient;
        uint256 amount;
        uint256 timestamp;
        string reason;
    }

    uint256 public totalTreasuryBalance;
    uint256 public minReserveThreshold = 10_000 ether; // Minimum treasury reserve
    uint256 public maxAllocationPerProposal = 5_000 ether; // Max allocation for any single proposal

    mapping(address => uint256) public entityAllocations;
    FundAllocation[] public allocationHistory;

    AITreasuryAdjuster public treasuryAdjuster;
    AIBudgetOptimizer public budgetOptimizer;
    AIReserveManager public reserveManager;
    AIAuditLogger public auditLogger;
    AIProposalScoring public proposalScoring;

    event TreasuryFunded(address indexed sender, uint256 amount);
    event FundsAllocated(address indexed recipient, uint256 amount, string reason);
    event TreasuryReserveUpdated(uint256 newReserveThreshold);
    event MaxAllocationUpdated(uint256 newMaxAllocation);

    constructor(
        address _treasuryAdjuster,
        address _budgetOptimizer,
        address _reserveManager,
        address _auditLogger,
        address _proposalScoring
    ) {
        treasuryAdjuster = AITreasuryAdjuster(_treasuryAdjuster);
        budgetOptimizer = AIBudgetOptimizer(_budgetOptimizer);
        reserveManager = AIReserveManager(_reserveManager);
        auditLogger = AIAuditLogger(_auditLogger);
        proposalScoring = AIProposalScoring(_proposalScoring);
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

        // Transfer Funds
        totalTreasuryBalance -= optimizedAmount;
        _recipient.transfer(optimizedAmount);

        allocationHistory.push(FundAllocation({
            recipient: _recipient,
            amount: optimizedAmount,
            timestamp: block.timestamp,
            reason: _reason
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

        emit FundsAllocated(_recipient, optimizedAmount, _reason);
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
