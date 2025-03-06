const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NovaNetTreasury", function () {
    let TreasuryContract, treasuryContract;
    let AIAuditLogger, auditLogger;
    let AITreasuryOptimizer, treasuryOptimizer;
    let owner, validator1, validator2, proposer, maliciousActor;

    before(async function () {
        [owner, validator1, validator2, proposer, maliciousActor] = await ethers.getSigners();

        // Deploy AI Audit Logger
        AIAuditLogger = await ethers.getContractFactory("AIAuditLogger");
        auditLogger = await AIAuditLogger.deploy();
        await auditLogger.deployed();

        // Deploy AI Treasury Optimizer
        AITreasuryOptimizer = await ethers.getContractFactory("AITreasuryOptimizer");
        treasuryOptimizer = await AITreasuryOptimizer.deploy(auditLogger.address);
        await treasuryOptimizer.deployed();

        // Deploy Treasury Contract
        TreasuryContract = await ethers.getContractFactory("NovaNetTreasury");
        treasuryContract = await TreasuryContract.deploy(auditLogger.address, treasuryOptimizer.address);
        await treasuryContract.deployed();

        // Fund Treasury with initial balance
        await owner.sendTransaction({
            to: treasuryContract.address,
            value: ethers.utils.parseEther("5000"),
        });
    });

    describe("🔹 Treasury Fund Management & AI Optimization", function () {
        it("Should receive and hold initial funds", async function () {
            let balance = await ethers.provider.getBalance(treasuryContract.address);
            expect(balance).to.equal(ethers.utils.parseEther("5000"));
        });

        it("Should prevent unauthorized withdrawals", async function () {
            await expect(
                treasuryContract.connect(maliciousActor).withdrawFunds(ethers.utils.parseEther("100"))
            ).to.be.revertedWith("Only governance can allocate funds.");
        });

        it("Should allow governance to allocate funds to proposals", async function () {
            await treasuryContract.connect(owner).allocateFunds(proposer.address, ethers.utils.parseEther("1000"));
            let balance = await ethers.provider.getBalance(proposer.address);
            expect(balance).to.be.greaterThan(ethers.utils.parseEther("1000"));
        });

        it("Should log fund allocation in AI Audit Logger", async function () {
            let logs = await auditLogger.getAllLogs();
            expect(logs.length).to.be.greaterThan(0);
        });

        it("Should reject allocations that exceed treasury balance", async function () {
            await expect(
                treasuryContract.connect(owner).allocateFunds(proposer.address, ethers.utils.parseEther("10000"))
            ).to.be.revertedWith("Insufficient treasury balance.");
        });
    });

    describe("🔹 AI Fraud Detection & Treasury Spending Audits", function () {
        it("Should detect fraudulent fund requests", async function () {
            let fraudScoreBefore = await treasuryOptimizer.getFraudScore(maliciousActor.address);
            await treasuryOptimizer.detectFraudulentRequest(maliciousActor.address);
            let fraudScoreAfter = await treasuryOptimizer.getFraudScore(maliciousActor.address);
            expect(fraudScoreAfter).to.be.greaterThan(fraudScoreBefore);
        });

        it("Should prevent fraudulent transactions", async function () {
            await expect(
                treasuryContract.connect(maliciousActor).allocateFunds(maliciousActor.address, ethers.utils.parseEther("500"))
            ).to.be.revertedWith("AI fraud detection flagged this request.");
        });

        it("Should maintain an on-chain audit log of all transactions", async function () {
            let logs = await auditLogger.getAllLogs();
            expect(logs.length).to.be.greaterThan(0);
        });
    });

    describe("🔹 Validator & Delegator Rewards Payout", function () {
        it("Should distribute validator rewards based on AI ranking", async function () {
            await treasuryContract.connect(owner).distributeValidatorRewards([validator1.address, validator2.address], [500, 700]);
            let balance1 = await ethers.provider.getBalance(validator1.address);
            let balance2 = await ethers.provider.getBalance(validator2.address);
            expect(balance1).to.be.greaterThan(ethers.utils.parseEther("500"));
            expect(balance2).to.be.greaterThan(ethers.utils.parseEther("700"));
        });

        it("Should reject invalid reward allocations", async function () {
            await expect(
                treasuryContract.connect(owner).distributeValidatorRewards([validator1.address], [10000])
            ).to.be.revertedWith("Insufficient treasury balance.");
        });
    });

    describe("🔹 Emergency Reserve & Treasury Protection", function () {
        it("Should maintain a minimum treasury reserve", async function () {
            let reserve = await treasuryContract.getTreasuryReserve();
            expect(reserve).to.be.greaterThan(ethers.utils.parseEther("1000"));
        });

        it("Should prevent allocations that deplete the emergency reserve", async function () {
            await expect(
                treasuryContract.connect(owner).allocateFunds(proposer.address, ethers.utils.parseEther("4000"))
            ).to.be.revertedWith("Cannot allocate funds below reserve threshold.");
        });

        it("Should allow governance to adjust reserve thresholds", async function () {
            await treasuryContract.connect(owner).updateReserveThreshold(ethers.utils.parseEther("800"));
            let newThreshold = await treasuryContract.getReserveThreshold();
            expect(newThreshold).to.equal(ethers.utils.parseEther("800"));
        });
    });
});
