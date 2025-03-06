// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIValidatorReputation.sol";
import "./AIGovernanceFraudDetection.sol";

contract AIVotingModel is Ownable, ReentrancyGuard {
    struct Voter {
        uint256 stakeAmount;
        uint256 reputationScore;
        bool hasVoted;
    }

    mapping(address => Voter) public voters;
    mapping(address => address) public delegation;
    uint256 public totalVotingPower;
    uint256 public reputationWeight = 40; // Reputation weight percentage in vote calculation
    uint256 public stakeWeight = 60; // Staking weight percentage in vote calculation

    AIValidatorReputation public reputationContract;
    AIGovernanceFraudDetection public fraudDetection;

    event VoteCast(address indexed voter, uint256 votingPower);
    event VotingParametersUpdated(uint256 reputationWeight, uint256 stakeWeight);
    event DelegationAssigned(address indexed delegator, address indexed delegatee);

    constructor(address _reputationContract, address _fraudDetection) {
        reputationContract = AIValidatorReputation(_reputationContract);
        fraudDetection = AIGovernanceFraudDetection(_fraudDetection);
    }

    /// @notice Registers a voter's stake and reputation for AI-weighted voting.
    function registerVoter(uint256 _stakeAmount) external {
        require(_stakeAmount > 0, "Stake amount must be greater than zero.");

        uint256 reputationScore = reputationContract.getReputation(msg.sender);
        voters[msg.sender] = Voter({
            stakeAmount: _stakeAmount,
            reputationScore: reputationScore,
            hasVoted: false
        });

        totalVotingPower += calculateVotingPower(msg.sender);
    }

    /// @notice Allows voters to delegate their voting power to another address.
    function delegateVote(address _delegatee) external {
        require(voters[msg.sender].stakeAmount > 0, "Must be a registered voter.");
        require(voters[_delegatee].stakeAmount > 0, "Delegatee must be a registered voter.");
        require(delegation[msg.sender] == address(0), "Already delegated.");

        delegation[msg.sender] = _delegatee;
        emit DelegationAssigned(msg.sender, _delegatee);
    }

    /// @notice Casts a vote with AI-optimized weight calculation.
    function castVote(bool _support) external {
        require(voters[msg.sender].stakeAmount > 0, "Must be a registered voter.");
        require(!voters[msg.sender].hasVoted, "Already voted.");

        uint256 votingPower = calculateVotingPower(msg.sender);
        require(votingPower > 0, "No effective voting power.");

        fraudDetection.detectVoteAnomalies(msg.sender);
        voters[msg.sender].hasVoted = true;

        emit VoteCast(msg.sender, votingPower);
    }

    /// @notice AI-powered calculation of voting power.
    function calculateVotingPower(address _voter) public view returns (uint256) {
        Voter storage voter = voters[_voter];
        uint256 weightedStake = (voter.stakeAmount * stakeWeight) / 100;
        uint256 weightedReputation = (voter.reputationScore * reputationWeight) / 100;
        return weightedStake + weightedReputation;
    }

    /// @notice Updates voting weight percentages for reputation and stake.
    function updateVotingParameters(uint256 _reputationWeight, uint256 _stakeWeight) external onlyOwner {
        require(_reputationWeight + _stakeWeight == 100, "Total must equal 100%.");
        reputationWeight = _reputationWeight;
        stakeWeight = _stakeWeight;

        emit VotingParametersUpdated(_reputationWeight, _stakeWeight);
    }

    /// @notice Gets voter information.
    function getVoterInfo(address _voter) external view returns (uint256 stake, uint256 reputation, bool hasVoted) {
        Voter storage voter = voters[_voter];
        return (voter.stakeAmount, voter.reputationScore, voter.hasVoted);
    }
}
