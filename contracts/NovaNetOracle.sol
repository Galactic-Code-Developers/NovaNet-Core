// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIAuditLogger.sol";
import "./AIGovernanceFraudDetection.sol";

contract NovaNetOracle is Ownable, ReentrancyGuard {
    struct DataRequest {
        uint256 requestId;
        address requester;
        string dataQuery;
        string response;
        bool fulfilled;
        uint256 timestamp;
    }

    mapping(uint256 => DataRequest) public dataRequests;
    uint256 public requestCounter;
    mapping(address => bool) public approvedDataProviders;
    uint256 public dataProviderFee = 0.01 ether; // Fee required to submit data

    AIAuditLogger public auditLogger;
    AIGovernanceFraudDetection public fraudDetection;

    event DataRequested(uint256 indexed requestId, address indexed requester, string dataQuery);
    event DataFulfilled(uint256 indexed requestId, address indexed provider, string response);
    event DataProviderApproved(address indexed provider);
    event DataProviderRemoved(address indexed provider);
    event OracleFeeUpdated(uint256 newFee);

    constructor(address _auditLogger, address _fraudDetection) {
        auditLogger = AIAuditLogger(_auditLogger);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
    }

    /// @notice Allows users to request off-chain data.
    function requestData(string memory _query) external payable nonReentrant {
        require(msg.value >= dataProviderFee, "Insufficient fee provided.");
        requestCounter++;

        dataRequests[requestCounter] = DataRequest({
            requestId: requestCounter,
            requester: msg.sender,
            dataQuery: _query,
            response: "",
            fulfilled: false,
            timestamp: block.timestamp
        });

        emit DataRequested(requestCounter, msg.sender, _query);
    }

    /// @notice Allows approved providers to fulfill a data request.
    function fulfillRequest(uint256 _requestId, string memory _response) external nonReentrant {
        require(approvedDataProviders[msg.sender], "Unauthorized data provider.");
        require(dataRequests[_requestId].requestId == _requestId, "Invalid request ID.");
        require(!dataRequests[_requestId].fulfilled, "Request already fulfilled.");

        dataRequests[_requestId].response = _response;
        dataRequests[_requestId].fulfilled = true;

        // AI Audit Logging for Transparency
        string memory auditEntry = string(
            abi.encodePacked(
                "Oracle Data Request ID: ", uintToString(_requestId),
                " | Provider: ", toAsciiString(msg.sender),
                " | Response: ", _response
            )
        );
        auditLogger.logGovernanceAction(_requestId, auditEntry);

        emit DataFulfilled(_requestId, msg.sender, _response);
    }

    /// @notice Approves a new oracle data provider.
    function approveDataProvider(address _provider) external onlyOwner {
        require(!approvedDataProviders[_provider], "Provider already approved.");
        approvedDataProviders[_provider] = true;
        emit DataProviderApproved(_provider);
    }

    /// @notice Removes an oracle data provider.
    function removeDataProvider(address _provider) external onlyOwner {
        require(approvedDataProviders[_provider], "Provider not found.");
        approvedDataProviders[_provider] = false;
        emit DataProviderRemoved(_provider);
    }

    /// @notice Updates the oracle fee for requesting data.
    function updateOracleFee(uint256 _newFee) external onlyOwner {
        require(_newFee > 0, "Fee must be greater than zero.");
        dataProviderFee = _newFee;
        emit OracleFeeUpdated(_newFee);
    }

    /// @notice Retrieves a completed oracle response.
    function getOracleResponse(uint256 _requestId) external view returns (string memory) {
        require(dataRequests[_requestId].fulfilled, "Request not yet fulfilled.");
        return dataRequests[_requestId].response;
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
