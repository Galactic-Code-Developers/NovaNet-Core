const { ethers } = require("hardhat");
require("dotenv").config();

// NovaNet RPC & Wallet Setup
const NOVANET_RPC_URL = process.env.NOVANET_RPC_URL || "https://testnet.novanet.io/rpc";
const PRIVATE_KEY = process.env.PRIVATE_KEY; // Required for signing transactions (if needed)

// Initialize Provider & Wallet Signer
const provider = new ethers.providers.JsonRpcProvider(NOVANET_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Smart Contract Addresses (Replace with deployed addresses)
const NOVANET_VALIDATOR_ADDRESS = "<NovaNetValidator_ADDRESS>";
const AI_VALIDATOR_REPUTATION_ADDRESS = "<AIValidatorReputation_ADDRESS>";
const AI_SLASHING_MONITOR_ADDRESS = "<AISlashingMonitor_ADDRESS>";
const AI_AUDIT_LOGGER_ADDRESS = "<AIAuditLogger_ADDRESS>";

// ABI Imports (Replace with compiled ABI files)
const NovaNetValidatorABI = require("../artifacts/contracts/NovaNetValidator.sol/NovaNetValidator.json").abi;
const AIValidatorReputationABI = require("../artifacts/contracts/AIValidatorReputation.sol/AIValidatorReputation.json").abi;
const AISlashingMonitorABI = require("../artifacts/contracts/AISlashingMonitor.sol/AISlashingMonitor.json").abi;
const AIAuditLoggerABI = require("../artifacts/contracts/AIAuditLogger.sol/AIAuditLogger.json").abi;

// Initialize Contracts
const validatorContract = new ethers.Contract(NOVANET_VALIDATOR_ADDRESS, NovaNetValidatorABI, wallet);
const reputationContract = new ethers.Contract(AI_VALIDATOR_REPUTATION_ADDRESS, AIValidatorReputationABI, wallet);
const slashingMonitor = new ethers.Contract(AI_SLASHING_MONITOR_ADDRESS, AISlashingMonitorABI, wallet);
const auditLogger = new ethers.Contract(AI_AUDIT_LOGGER_ADDRESS, AIAuditLoggerABI, wallet);

// 🚀 Real-Time Validator Monitoring & Slashing Detection
async function monitorSlashingConditions() {
    console.log("\n🔍 Monitoring Validator Performance for Slashing Conditions...");

    const validators = await validatorContract.getValidators();

    for (const validator of validators) {
        try {
            let uptime = await validatorContract.getValidatorUptime(validator);
            let reputation = await reputationContract.getReputation(validator);
            let performance = await validatorContract.getPerformance(validator);

            console.log(`\n🛡 Validator: ${validator}`);
            console.log(`   ⏳ Uptime: ${uptime}%`);
            console.log(`   ⭐ Reputation Score: ${reputation}`);
            console.log(`   🚀 Performance Rating: ${performance}`);

            // Check if Validator Meets Slashing Criteria
            if (uptime < 80 || reputation < 50 || performance < 40) {
                console.log(`⚠️ Slashing Triggered for Validator: ${validator}`);
                await slashingMonitor.triggerSlashing(validator);
                await auditLogger.logGovernanceAction(
                    `Validator Slashed: ${validator} | Uptime: ${uptime}% | Reputation: ${reputation} | Performance: ${performance}`
                );
            }
        } catch (error) {
            console.error(`❌ Error Checking Validator ${validator}:`, error.message);
        }
    }

    console.log("\n✅ Slashing Conditions Checked & Updated.");
}

// 🚀 Run Slashing Monitor
monitorSlashingConditions()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Slashing Monitor Failed!", error);
        process.exit(1);
    });
