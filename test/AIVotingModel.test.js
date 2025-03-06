const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AIVotingModel", function () {
    let VotingContract, votingContract;
    let AIAuditLogger, auditLogger;
    let AIValidatorReputation, reputationContract;
    let owner, validator1, validator2, delegator1, delegator2, maliciousVoter;

    before(async function () {
        [owner, validator1, validator2, delegator1, delegator2, maliciousVoter] = await ethers.getSigners();

        // Deploy AI Audit Logger
        AIAuditLogger = await ethers.getContractFactory("AIAuditLogger");
        auditLogger = await AIAuditLogger.deploy();
        await auditLogger.deployed();

        // Deploy AI Validator Reputation Contract
        AIValidatorReputation = await ethers.getContractFactory("AIValidatorReputation");
        reputationContract = await AIValidatorReputation.deploy();
        await reputationContract.deployed();

        // Deploy Voting Model Contract
        VotingContract = await ethers.getContractFactory("AIVotingModel");
        votingContract = await VotingContract.deploy(reputationContract.address, auditLogger.address);
        await votingContract.deployed();
    });

    describe("🔹 AI Reputation-Weighted Voting Power", function () {
        it("Should assign voting power based on AI reputation", async function () {
            await reputationContract.setReputation(validator1.address, 80);
            await reputationContract.setReputation(validator2.address, 60);
            await reputationContract.setReputation(delegator1.address, 50);

            let power1 = await votingContract.getVotingPower(validator1.address);
            let power2 = await votingContract.getVotingPower(validator2.address);
            let power3 = await votingContract.getVotingPower(delegator1.address);

            expect(power1).to.be.greaterThan(power2);
            expect(power2).to.be.greaterThan(power3);
        });
    });

    describe("🔹 Proposal Submission & Voting", function () {
        it("Should allow proposals to be submitted", async function () {
            await votingContract.connect(validator1).submitProposal("Increase staking rewards", 500);
            let proposal = await votingContract.proposals(1);
            expect(proposal.description).to.equal("Increase staking rewards");
        });

        it("Should allow validators and delegators to vote", async function () {
            await votingContract.connect(validator1).vote(1, true);
            await votingContract.connect(validator2).vote(1, false);
            await votingContract.connect(delegator1).vote(1, true);

            let proposal = await votingContract.proposals(1);
            expect(proposal.votesFor).to.be.greaterThan(0);
            expect(proposal.votesAgainst).to.be.greaterThan(0);
        });

        it("Should prevent duplicate votes", async function () {
            await expect(votingContract.connect(validator1).vote(1, true)).to.be.revertedWith("Already voted");
        });

        it("Should apply AI-weighted voting adjustments", async function () {
            let adjustedPower1 = await votingContract.getAdjustedVoteWeight(validator1.address, true);
            let adjustedPower2 = await votingContract.getAdjustedVoteWeight(validator2.address, false);
            expect(adjustedPower1).to.be.greaterThan(adjustedPower2);
        });
    });

    describe("🔹 AI Fraud Detection in Voting", function () {
        it("Should detect fraudulent voters", async function () {
            await votingContract.detectFraudulentVoter(maliciousVoter.address);
            let fraudScore = await votingContract.getFraudScore(maliciousVoter.address);
            expect(fraudScore).to.be.greaterThan(0);
        });

        it("Should prevent fraudulent voters from participating", async function () {
            await expect(votingContract.connect(maliciousVoter).vote(1, true)).to.be.revertedWith("Voter flagged for fraud");
        });
    });

    describe("🔹 Proposal Execution", function () {
        it("Should allow governance to execute successful proposals", async function () {
            await ethers.provider.send("evm_increaseTime", [7200]); // Simulate voting duration
            await votingContract.executeProposal(1);
            let proposal = await votingContract.proposals(1);
            expect(proposal.executed).to.be.true;
        });

        it("Should reject execution of failed proposals", async function () {
            await votingContract.connect(validator1).submitProposal("Reduce staking requirements", 200);
            await votingContract.connect(validator2).vote(2, false);
            await votingContract.connect(validator1).vote(2, false);

            await ethers.provider.send("evm_increaseTime", [7200]); // Simulate voting duration
            await expect(votingContract.executeProposal(2)).to.be.revertedWith("Proposal not approved");
        });
    });

    describe("🔹 AI Governance Transparency & Logging", function () {
        it("Should store all voting records in AI Audit Logger", async function () {
            let logs = await auditLogger.getAllLogs();
            expect(logs.length).to.be.greaterThan(0);
        });

        it("Should allow retrieval of voting history for audits", async function () {
            let history = await votingContract.getVotingHistory(validator1.address);
            expect(history.length).to.be.greaterThan(0);
        });
    });
});
