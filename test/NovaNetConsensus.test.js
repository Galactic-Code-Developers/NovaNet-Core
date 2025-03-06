const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NovaNetConsensus", function () {
    let Consensus, consensus;
    let ValidatorContract, validatorContract;
    let AIValidatorReputation, reputationContract;
    let AIAuditLogger, auditLogger;
    let owner, validator1, validator2, validator3, maliciousValidator;

    before(async function () {
        [owner, validator1, validator2, validator3, maliciousValidator] = await ethers.getSigners();

        // Deploy AI Audit Logger
        AIAuditLogger = await ethers.getContractFactory("AIAuditLogger");
        auditLogger = await AIAuditLogger.deploy();
        await auditLogger.deployed();

        // Deploy AI Validator Reputation
        AIValidatorReputation = await ethers.getContractFactory("AIValidatorReputation");
        reputationContract = await AIValidatorReputation.deploy();
        await reputationContract.deployed();

        // Deploy Validator Contract
        ValidatorContract = await ethers.getContractFactory("NovaNetValidator");
        validatorContract = await ValidatorContract.deploy(reputationContract.address, auditLogger.address);
        await validatorContract.deployed();

        // Deploy NovaNet Consensus Mechanism
        Consensus = await ethers.getContractFactory("NovaNetConsensus");
        consensus = await Consensus.deploy(validatorContract.address, reputationContract.address, auditLogger.address);
        await consensus.deployed();
    });

    describe("🔹 Validator Registration & AI Ranking", function () {
        it("Should allow validators to register and stake", async function () {
            await validatorContract.connect(validator1).registerValidator({ value: ethers.utils.parseEther("10") });
            await validatorContract.connect(validator2).registerValidator({ value: ethers.utils.parseEther("15") });
            await validatorContract.connect(validator3).registerValidator({ value: ethers.utils.parseEther("12") });

            expect(await validatorContract.isValidator(validator1.address)).to.be.true;
            expect(await validatorContract.isValidator(validator2.address)).to.be.true;
            expect(await validatorContract.isValidator(validator3.address)).to.be.true;
        });

        it("Should calculate AI-powered validator ranking", async function () {
            let rankedValidators = await consensus.rankValidators();
            expect(rankedValidators.length).to.equal(3);
        });

        it("Should select the best validator using AI", async function () {
            let bestValidator = await consensus.selectBestValidator();
            expect(bestValidator).to.not.equal(ethers.constants.AddressZero);
        });
    });

    describe("🔹 AI-Driven Validator Rotation", function () {
        it("Should rotate validators at the end of each epoch", async function () {
            let currentValidator = await consensus.selectBestValidator();
            await network.provider.send("evm_mine"); // Simulate block mining

            await consensus.rotateValidators();
            let newValidator = await consensus.selectBestValidator();

            expect(newValidator).to.not.equal(currentValidator);
        });
    });

    describe("🔹 AI Fraud Detection & Slashing", function () {
        it("Should detect fraudulent validator activity", async function () {
            await validatorContract.connect(maliciousValidator).registerValidator({ value: ethers.utils.parseEther("20") });

            let fraudScoreBefore = await reputationContract.getReputation(maliciousValidator.address);
            await consensus.detectFraudulentValidator(maliciousValidator.address);

            let fraudScoreAfter = await reputationContract.getReputation(maliciousValidator.address);
            expect(fraudScoreAfter).to.be.lessThan(fraudScoreBefore);
        });

        it("Should slash fraudulent validators", async function () {
            let balanceBefore = await ethers.provider.getBalance(maliciousValidator.address);
            await consensus.slashValidator(maliciousValidator.address);
            let balanceAfter = await ethers.provider.getBalance(maliciousValidator.address);

            expect(balanceAfter).to.be.lessThan(balanceBefore);
        });
    });

    describe("🔹 Governance-Based Validator Selection", function () {
        it("Should allow governance to override validator selection", async function () {
            await consensus.connect(owner).forceSelectValidator(validator3.address);
            let bestValidator = await consensus.selectBestValidator();
            expect(bestValidator).to.equal(validator3.address);
        });
    });
});
