const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NovaNetGovernance", function () {
    let GovernanceContract, governanceContract;
    let AIGovernanceFraudDetection, fraudDetection;
    let AIAuditLogger, auditLogger;
    let TreasuryContract, treasuryContract;
    let owner, proposer, validator1, validator2, maliciousActor;

    before(async function () {
        [owner, proposer, validator1, validator2, maliciousActor] = await ethers.getSigners();

        // Deploy AI Audit Logger
        AIAuditLogger = await ethers.getContractFactory("AIAuditLogger");
        auditLogger = await AIAuditLogger.deploy();
        await auditLogger.deployed();

        // Deploy AI Fraud Detection
        AIGovernanceFraudDetection = await ethers.getContractFactory("AIGovernanceFraudDetection");
        fraudDetection = await AIGovernanceFraudDetection.deploy(auditLogger.address);
        await fraudDetection.deployed();

        // Deploy Treasury
        TreasuryContract = await ethers.getContractFactory("NovaNetTreasury");
        treasuryContract = await TreasuryContract.deploy();
        await treasuryContract.deployed();

        // Deploy Governance Contract
        GovernanceContract = await ethers.getContractFactory("NovaNetGovernance");
        governanceContract = await GovernanceContract.deploy(treasuryContract.address, fraudDetection.address, auditLogger.address);
        await governanceContract.deployed();
    });

    describe("🔹 Proposal Submission & AI Evaluation", function () {
        it("Should allow valid proposals to be submitted", async function () {
            await governanceContract.connect(proposer).submitProposal(
                "Increase validator rewards",
                100,
                ethers.utils.parseEther("500"),
                proposer.address
            );
            let proposal = await governanceContract.proposals(1);
            expect(proposal.proposer).to.equal(proposer.address);
        });

        it("Should assign an AI score to proposals", async function () {
            let proposal = await governanceContract.proposals(1);
            expect(proposal.aiScore).to.be.greaterThan(0);
        });

        it("Should reject proposals that do not meet AI evaluation threshold", async function () {
            await expect(
                governanceContract.connect(maliciousActor).submitProposal(
                    "Drastically lower security levels",
                    50,
                    ethers.utils.parseEther("10000"),
                    maliciousActor.address
                )
            ).to.be.revertedWith("AI evaluation failed");
        });
    });

    describe("🔹 AI-Powered Voting & Reputation-Based Weights", function () {
        it("Should allow validators to vote on proposals", async function () {
            await governanceContract.connect(validator1).vote(1, true);
            await governanceContract.connect(validator2).vote(1, false);

            let proposal = await governanceContract.proposals(1);
            expect(proposal.votesFor).to.be.greaterThan(0);
            expect(proposal.votesAgainst).to.be.greaterThan(0);
        });

        it("Should assign dynamic vote weights based on AI reputation scoring", async function () {
            let voteWeight1 = await governanceContract.getVotingPower(validator1.address);
            let voteWeight2 = await governanceContract.getVotingPower(validator2.address);
            expect(voteWeight1).to.not.equal(voteWeight2);
        });

        it("Should prevent double voting", async function () {
            await expect(governanceContract.connect(validator1).vote(1, true)).to.be.revertedWith("Already voted");
        });
    });

    describe("🔹 Proposal Execution & Treasury Fund Allocation", function () {
        it("Should allow valid proposals to be executed", async function () {
            await ethers.provider.send("evm_increaseTime", [86400]); // Fast forward time
            await governanceContract.connect(owner).executeProposal(1);
            let proposal = await governanceContract.proposals(1);
            expect(proposal.executed).to.be.true;
        });

        it("Should allocate treasury funds to approved proposals", async function () {
            let balanceBefore = await ethers.provider.getBalance(proposer.address);
            await governanceContract.connect(owner).executeProposal(1);
            let balanceAfter = await ethers.provider.getBalance(proposer.address);
            expect(balanceAfter).to.be.greaterThan(balanceBefore);
        });
    });

    describe("🔹 AI Fraud Detection in Governance", function () {
        it("Should detect fraudulent governance activities", async function () {
            let fraudScoreBefore = await fraudDetection.fraudScores(maliciousActor.address);
            await fraudDetection.detectVoteAnomalies(maliciousActor.address);
            let fraudScoreAfter = await fraudDetection.fraudScores(maliciousActor.address);
            expect(fraudScoreAfter).to.be.greaterThan(fraudScoreBefore);
        });

        it("Should penalize fraudulent voters", async function () {
            await governanceContract.slashFraudulentVoter(maliciousActor.address);
            let fraudScore = await fraudDetection.fraudScores(maliciousActor.address);
            expect(fraudScore).to.equal(0); // Fraud score reset after slashing
        });
    });

    describe("🔹 Governance-Controlled Slashing & Network Parameter Adjustments", function () {
        it("Should allow governance to update slashing penalties", async function () {
            await governanceContract.connect(owner).updateSlashingPenalty(0.1);
            let penaltyRate = await governanceContract.getSlashingPenalty();
            expect(penaltyRate).to.equal(0.1);
        });

        it("Should allow governance to update network parameters", async function () {
            await governanceContract.connect(owner).updateNetworkParameter(1, 500);
            let newParam = await governanceContract.getNetworkParameter(1);
            expect(newParam).to.equal(500);
        });
    });
});
