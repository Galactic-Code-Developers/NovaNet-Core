// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIGovernanceFraudDetection.sol";
import "./AIAuditLogger.sol";

contract NovaNetBridge is Ownable, ReentrancyGuard {
    struct BridgeTransaction {
        uint256 id;
        address sender;
        address recipient;
        uint256 amount;
        string targetChain;
        string transactionHash;
        bool completed;
    }

    mapping(uint256 => BridgeTransaction) public bridgeTransactions;
    uint256 public bridgeTransactionCounter;
    mapping(string => bool) public supportedChains;
    mapping(address => bool) public bridgeOperators;
    uint256 public bridgeFee = 0.01 ether; // Fee required for bridging

    AIGovernanceFraudDetection public fraudDetection;
    AIAuditLogger public auditLogger;

    event BridgeInitiated(uint256 indexed transactionId, address indexed sender, uint256 amount, string targetChain);
    event BridgeCompleted(uint256 indexed transactionId, address indexed recipient, string transactionHash);
    event BridgeOperatorApproved(address indexed operator);
    event BridgeOperatorRemoved(address indexed operator);
    event BridgeFeeUpdated(uint256 newFee);

    constructor(address _fraudDetection, address _auditLogger) {
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
        auditLogger = AIAuditLogger(_auditLogger);
        supportedChains["Ethereum"] = true;
        supportedChains["Polkadot"] = true;
        supportedChains["Cosmos"] = true;
        supportedChains["NovaNet"] = true;
    }

    /// @notice Initiates a cross-chain bridge transfer.
    function initiateBridge(address _recipient, uint256 _amount, string memory _targetChain) external payable nonReentrant {
        require(supportedChains[_targetChain], "Unsupported chain.");
        require(msg.value >= bridgeFee, "Insufficient bridge fee.");
        require(_amount > 0, "Amount must be greater than zero.");

        bridgeTransactionCounter++;
        bridgeTransactions[bridgeTransactionCounter] = BridgeTransaction({
            id: bridgeTransactionCounter,
            sender: msg.sender,
            recipient: _recipient,
            amount: _amount,
            targetChain: _targetChain,
            transactionHash: "",
            completed: false
        });

        // AI Audit Logging for Transparency
        string memory auditEntry = string(
            abi.encodePacked(
                "Bridge Transaction ID: ", uintToString(bridgeTransactionCounter),
                " | Sender: ", toAsciiString(msg.sender),
                " | Recipient: ", toAsciiString(_recipient),
                " | Target Chain: ", _targetChain,
                " | Amount: ", uintToString(_amount)
            )
        );
        auditLogger.logGovernanceAction(bridgeTransactionCounter, auditEntry);

        emit BridgeInitiated(bridgeTransactionCounter, msg.sender, _amount, _targetChain);
    }

    /// @notice Completes a cross-chain bridge transfer.
    function completeBridge(uint256 _transactionId, string memory _transactionHash) external nonReentrant {
        require(bridgeOperators[msg.sender], "Unauthorized bridge operator.");
        require(bridgeTransactions[_transactionId].id == _transactionId, "Invalid transaction ID.");
        require(!bridgeTransactions[_transactionId].completed, "Transaction already completed.");

        bridgeTransactions[_transactionId].completed = true;
        bridgeTransactions[_transactionId].transactionHash = _transactionHash;

        payable(bridgeTransactions[_transactionId].recipient).transfer(bridgeTransactions[_transactionId].amount);

        emit BridgeCompleted(_transactionId, bridgeTransactions[_transactionId].recipient, _transactionHash);
    }

    /// @notice Approves a new bridge operator.
    function approveBridgeOperator(address _operator) external onlyOwner {
        require(!bridgeOperators[_operator], "Operator already approved.");
        bridgeOperators[_operator] = true;
        emit BridgeOperatorApproved(_operator);
    }

    /// @notice Removes a bridge operator.
    function removeBridgeOperator(address _operator) external onlyOwner {
        require(bridgeOperators[_operator], "Operator not found.");
        bridgeOperators[_operator] = false;
        emit BridgeOperatorRemoved(_operator);
    }

    /// @notice Updates the bridge fee.
    function updateBridgeFee(uint256 _newFee) external onlyOwner {
        require(_newFee > 0, "Fee must be greater than zero.");
        bridgeFee = _newFee;
        emit BridgeFeeUpdated(_newFee);
    }

    /// @notice Checks if a chain is supported.
    function isSupportedChain(string memory _chain) external view returns (bool) {
        return supportedChains[_chain];
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
