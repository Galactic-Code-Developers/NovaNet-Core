// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIProposalScoring.sol";
import "./AIAuditLogger.sol";
import "./AITreasuryAdjuster.sol";
import "./AIVotingModel.sol";
import "./AIValidatorSelection.sol";
import "./NovaNetValidator.sol";

contract NovaNetGovernance is Ownable, ReentrancyGuard {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 aiScore; // AI-powered proposal ranking
        bool executed;
        ProposalType proposalType;
        uint256 fundAmount;
        address payable recipient;
        mapping(address => bool) voted;
    }

    enum ProposalType { GENERAL, SLASH_VALIDATOR, TREASURY_ALLOCATION, PARAMETER_UPDATE, NETWORK_UPGRADE }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    AIProposalScoring public proposalScoring;
    AIAuditLogger public auditLogger;
    AITreasuryAdjuster public treasuryAdjuster;
    AIVotingModel public votingModel;
    AIValidatorSelection public validatorSelection;
    NovaNetValidator public validatorContract;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 aiScore);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed id);
    event AIProposalAudit(uint256 indexed proposalId, string auditEntry);

    constructor(
        address _proposalScoring,
        address _auditLogger,
        address _treasuryAdjuster,
        address _votingModel,
        address _validatorSelection,
        address _validatorContract
    ) {
        proposalScoring = AIProposalScoring(_proposalScoring);
        auditLogger = AIAuditLogger(_auditLogger);
        treasuryAdjuster = AITreasuryAdjuster(_treasuryAdjuster);
        votingModel = AIVotingModel(_votingModel);
        validatorSelection = AIValidatorSelection(_validatorSelection);
        validatorContract = NovaNetValidator(_validatorContract);
    }

    /// @notice Creates a new governance proposal with AI scoring.
    function submitProposal(
        string memory _description,
        uint256 _duration,
        ProposalType _type,
        uint256 _fundAmount,
        address payable _recipient
    ) external nonReentrant {
        proposalCount++;
        uint256 aiScore = proposalScoring.calculateAIScore(_description, _type, _fundAmount);

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + _duration;
        newProposal.aiScore = aiScore;
        newProposal.executed = false;
        newProposal.proposalType = _type;
        newProposal.fundAmount = _fundAmount;
        newProposal.recipient = _recipient;

        // AI Audit Logging
        string memory auditEntry = string(
            abi.encodePacked(
                "Proposal ID: ", uintToString(proposalCount),
                " | AI Score: ", uintToString(aiScore),
                " | Type: ", proposalTypeToString(_type),
                " | Description: ", _description
            )
        );
        auditLogger.logGovernanceAction(proposalCount, auditEntry);
        emit AIProposalAudit(proposalCount, auditEntry);

        emit ProposalCreated(proposalCount, msg.sender, _description, aiScore);
    }

    /// @notice Allows validators and delegators to vote on proposals.
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.voted[msg.sender], "Already voted");

        uint256 votingPower = votingModel.getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit VoteCasted(_proposalId, msg.sender, _support, votingPower);
    }

    /// @notice Executes proposals based on voting results and AI-driven impact assessment.
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.SLASH_VALIDATOR) {
            validatorContract.slashValidator(proposal.recipient, proposal.fundAmount);
        } else if (proposal.proposalType == ProposalType.TREASURY_ALLOCATION) {
            uint256 aiAdjustedFunds = treasuryAdjuster.adjustTreasuryAllocation(proposal.fundAmount, proposal.aiScore);
            payable(proposal.recipient).transfer(aiAdjustedFunds);
        } else if (proposal.proposalType == ProposalType.PARAMETER_UPDATE) {
            validatorContract.updateEpochBlockCount(proposal.fundAmount);
        } else if (proposal.proposalType == ProposalType.NETWORK_UPGRADE) {
            // Implement upgrade logic
        }

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Returns proposal details.
    function getProposal(uint256 _proposalId) external view returns (
        address proposer, string memory description, uint256 votesFor, uint256 votesAgainst, bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.proposer, proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }

    /// @notice Converts a proposal type to a string.
    function proposalTypeToString(ProposalType _type) internal pure returns (string memory) {
        if (_type == ProposalType.GENERAL) return "GENERAL";
        if (_type == ProposalType.SLASH_VALIDATOR) return "SLASH_VALIDATOR";
        if (_type == ProposalType.TREASURY_ALLOCATION) return "TREASURY_ALLOCATION";
        if (_type == ProposalType.PARAMETER_UPDATE) return "PARAMETER_UPDATE";
        if (_type == ProposalType.NETWORK_UPGRADE) return "NETWORK_UPGRADE";
        return "UNKNOWN";
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
