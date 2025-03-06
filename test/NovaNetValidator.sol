const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NovaNetValidator", function () {
    let ValidatorContract, validatorContract;
    let AIValidatorReputation, reputationContract;
    let AIAuditLogger, auditLogger;
    let owner, validator1, validator2, validator3, delegator, maliciousValidator;

    before(async function () {
        [owner, validator1, validator2, validator3, delegator, maliciousValidator] = await ethers.getSigners();

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
    });

    describe("🔹 Validator Registration & Staking", function () {
        it("Should allow validators to register and stake", async function () {
            await validatorContract.connect(validator1).registerValidator({ value: ethers.utils.parseEther("10") });
            await validatorContract.connect(validator2).registerValidator({ value: ethers.utils.parseEther("15") });
            await validatorContract.connect(validator3).registerValidator({ value: ethers.utils.parseEther("12") });

            expect(await validatorContract.isValidator(validator1.address)).to.be.true;
            expect(await validatorContract.isValidator(validator2.address)).to.be.true;
            expect(await validatorContract.isValidator(validator3.address)).to.be.true;
        });

        it("Should allow validators to increase their stake", async function () {
            await validatorContract.connect(validator1).increaseStake({ value: ethers.utils.parseEther("5") });
            expect(await validatorContract.getStakeAmount(validator1.address)).to.equal(ethers.utils.parseEther("15"));
        });

        it("Should allow validators to withdraw stake within limits", async function () {
            await validatorContract.connect(validator1).withdrawStake(ethers.utils.parseEther("5"));
            expect(await validatorContract.getStakeAmount(validator1.address)).to.equal(ethers.utils.parseEther("10"));
        });

        it("Should not allow non-validators to withdraw stake", async function () {
            await expect(validatorContract.connect(delegator).withdrawStake(ethers.utils.parseEther("1"))).to.be.revertedWith(
                "Not a registered validator"
            );
        });
    });

    describe("🔹 AI Reputation & Performance Adjustments", function () {
        it("Should increase validator reputation for good performance", async function () {
            let reputationBefore = await reputationContract.getReputation(validator1.address);
            await reputationContract.increaseReputation(validator1.address, 10);
            let reputationAfter = await reputationContract.getReputation(validator1.address);
            expect(reputationAfter).to.be.greaterThan(reputationBefore);
        });

        it("Should decrease validator reputation for misbehavior", async function () {
            let reputationBefore = await reputationContract.getReputation(validator2.address);
            await reputationContract.decreaseReputation(validator2.address, 10);
            let reputationAfter = await reputationContract.getReputation(validator2.address);
            expect(reputationAfter).to.be.lessThan(reputationBefore);
        });
    });

    describe("🔹 Validator Reward Distribution", function () {
        it("Should distribute rewards based on AI ranking", async function () {
            await validatorContract.distributeRewards({ value: ethers.utils.parseEther("10") });
            let balanceAfter = await ethers.provider.getBalance(validator1.address);
            expect(balanceAfter).to.be.greaterThan(ethers.utils.parseEther("10"));
        });
    });

    describe("🔹 Slashing & Fraud Prevention", function () {
        it("Should detect fraudulent validator activity", async function () {
            let fraudScoreBefore = await reputationContract.getReputation(maliciousValidator.address);
            await validatorContract.detectMaliciousValidator(maliciousValidator.address);
            let fraudScoreAfter = await reputationContract.getReputation(maliciousValidator.address);
            expect(fraudScoreAfter).to.be.lessThan(fraudScoreBefore);
        });

        it("Should slash fraudulent validators", async function () {
            let balanceBefore = await ethers.provider.getBalance(maliciousValidator.address);
            await validatorContract.slashValidator(maliciousValidator.address);
            let balanceAfter = await ethers.provider.getBalance(maliciousValidator.address);
            expect(balanceAfter).to.be.lessThan(balanceBefore);
        });
    });

    describe("🔹 Governance-Based Validator Management", function () {
        it("Should allow governance to override validator removal", async function () {
            await validatorContract.connect(owner).removeValidator(validator3.address);
            expect(await validatorContract.isValidator(validator3.address)).to.be.false;
        });
    });
});
