const { ethers } = require("hardhat");

async function main() {
    console.log("\n🚀 Deploying NovaNet Smart Contracts...");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // 🛠 Deploy AI Audit Logger
    console.log("\n🔹 Deploying AIAuditLogger...");
    const AIAuditLogger = await ethers.getContractFactory("AIAuditLogger");
    const auditLogger = await AIAuditLogger.deploy();
    await auditLogger.deployed();
    console.log("✅ AIAuditLogger deployed at:", auditLogger.address);

    // 🛠 Deploy AI Validator Reputation
    console.log("\n🔹 Deploying AIValidatorReputation...");
    const AIValidatorReputation = await ethers.getContractFactory("AIValidatorReputation");
    const reputationContract = await AIValidatorReputation.deploy();
    await reputationContract.deployed();
    console.log("✅ AIValidatorReputation deployed at:", reputationContract.address);

    // 🛠 Deploy NovaNet Validator Contract
    console.log("\n🔹 Deploying NovaNetValidator...");
    const NovaNetValidator = await ethers.getContractFactory("NovaNetValidator");
    const validatorContract = await NovaNetValidator.deploy(reputationContract.address, auditLogger.address);
    await validatorContract.deployed();
    console.log("✅ NovaNetValidator deployed at:", validatorContract.address);

    // 🛠 Deploy AI Voting Model
    console.log("\n🔹 Deploying AIVotingModel...");
    const AIVotingModel = await ethers.getContractFactory("AIVotingModel");
    const votingModel = await AIVotingModel.deploy(reputationContract.address, auditLogger.address);
    await votingModel.deployed();
    console.log("✅ AIVotingModel deployed at:", votingModel.address);

    // 🛠 Deploy AI Governance Fraud Detection
    console.log("\n🔹 Deploying AIGovernanceFraudDetection...");
    const AIGovernanceFraudDetection = await ethers.getContractFactory("AIGovernanceFraudDetection");
    const fraudDetection = await AIGovernanceFraudDetection.deploy(auditLogger.address);
    await fraudDetection.deployed();
    console.log("✅ AIGovernanceFraudDetection deployed at:", fraudDetection.address);

    // 🛠 Deploy NovaNet Treasury
    console.log("\n🔹 Deploying NovaNetTreasury...");
    const NovaNetTreasury = await ethers.getContractFactory("NovaNetTreasury");
    const treasuryContract = await NovaNetTreasury.deploy(auditLogger.address);
    await treasuryContract.deployed();
    console.log("✅ NovaNetTreasury deployed at:", treasuryContract.address);

    // 🛠 Deploy AI Validator Selection
    console.log("\n🔹 Deploying AIValidatorSelection...");
    const AIValidatorSelection = await ethers.getContractFactory("AIValidatorSelection");
    const validatorSelection = await AIValidatorSelection.deploy(validatorContract.address, reputationContract.address, auditLogger.address);
    await validatorSelection.deployed();
    console.log("✅ AIValidatorSelection deployed at:", validatorSelection.address);

    // 🛠 Deploy AI Slashing Monitor
    console.log("\n🔹 Deploying AISlashingMonitor...");
    const AISlashingMonitor = await ethers.getContractFactory("AISlashingMonitor");
    const slashingMonitor = await AISlashingMonitor.deploy(validatorContract.address, reputationContract.address, auditLogger.address);
    await slashingMonitor.deployed();
    console.log("✅ AISlashingMonitor deployed at:", slashingMonitor.address);

    // 🛠 Deploy AI Reward Distribution
    console.log("\n🔹 Deploying AIRewardDistribution...");
    const AIRewardDistribution = await ethers.getContractFactory("AIRewardDistribution");
    const rewardDistribution = await AIRewardDistribution.deploy(auditLogger.address);
    await rewardDistribution.deployed();
    console.log("✅ AIRewardDistribution deployed at:", rewardDistribution.address);

    // 🛠 Deploy NovaNet Governance
    console.log("\n🔹 Deploying NovaNetGovernance...");
    const NovaNetGovernance = await ethers.getContractFactory("NovaNetGovernance");
    const governanceContract = await NovaNetGovernance.deploy(treasuryContract.address, fraudDetection.address, auditLogger.address);
    await governanceContract.deployed();
    console.log("✅ NovaNetGovernance deployed at:", governanceContract.address);

    // 🛠 Deploy NovaNet Bridge
    console.log("\n🔹 Deploying NovaNetBridge...");
    const NovaNetBridge = await ethers.getContractFactory("NovaNetBridge");
    const bridgeContract = await NovaNetBridge.deploy();
    await bridgeContract.deployed();
    console.log("✅ NovaNetBridge deployed at:", bridgeContract.address);

    // 🛠 Deploy NovaNet Oracle
    console.log("\n🔹 Deploying NovaNetOracle...");
    const NovaNetOracle = await ethers.getContractFactory("NovaNetOracle");
    const oracleContract = await NovaNetOracle.deploy();
    await oracleContract.deployed();
    console.log("✅ NovaNetOracle deployed at:", oracleContract.address);

    // ✅ Contract Deployment Summary
    console.log("\n🚀 NovaNet Smart Contracts Successfully Deployed!");
    console.log("\n🔹 Contract Addresses:");
    console.log("📜 AIAuditLogger:", auditLogger.address);
    console.log("📜 AIValidatorReputation:", reputationContract.address);
    console.log("📜 NovaNetValidator:", validatorContract.address);
    console.log("📜 AIVotingModel:", votingModel.address);
    console.log("📜 AIGovernanceFraudDetection:", fraudDetection.address);
    console.log("📜 NovaNetTreasury:", treasuryContract.address);
    console.log("📜 AIValidatorSelection:", validatorSelection.address);
    console.log("📜 AISlashingMonitor:", slashingMonitor.address);
    console.log("📜 AIRewardDistribution:", rewardDistribution.address);
    console.log("📜 NovaNetGovernance:", governanceContract.address);
    console.log("📜 NovaNetBridge:", bridgeContract.address);
    console.log("📜 NovaNetOracle:", oracleContract.address);
}

// 🔹 Execute Deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment Failed!", error);
        process.exit(1);
    });
