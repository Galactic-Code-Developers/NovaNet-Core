const { ethers } = require("ethers");
require("dotenv").config();

// Load Environment Variables
const NOVANET_RPC_URL = process.env.NOVANET_RPC_URL || "https://testnet.novanet.io/rpc";
const PRIVATE_KEY = process.env.PRIVATE_KEY; // Required for signing transactions (if needed)

// Initialize Provider
const provider = new ethers.providers.JsonRpcProvider(NOVANET_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract Addresses (Replace with deployed contract addresses)
const AI_AUDIT_LOGGER_ADDRESS = "<AIAuditLogger_ADDRESS>";
const NOVA_NET_VALIDATOR_ADDRESS = "<NovaNetValidator_ADDRESS>";
const NOVA_NET_GOVERNANCE_ADDRESS = "<NovaNetGovernance_ADDRESS>";
const NOVA_NET_TREASURY_ADDRESS = "<NovaNetTreasury_ADDRESS>";
const AI_VOTING_MODEL_ADDRESS = "<AIVotingModel_ADDRESS>";
const AI_SLASHING_MONITOR_ADDRESS = "<AISlashingMonitor_ADDRESS>";

// ABI Imports (Replace with compiled ABI files)
const AIAuditLoggerABI = require("../artifacts/contracts/AIAuditLogger.sol/AIAuditLogger.json").abi;
const NovaNetValidatorABI = require("../artifacts/contracts/NovaNetValidator.sol/NovaNetValidator.json").abi;
const NovaNetGovernanceABI = require("../artifacts/contracts/NovaNetGovernance.sol/NovaNetGovernance.json").abi;
const NovaNetTreasuryABI = require("../artifacts/contracts/NovaNetTreasury.sol/NovaNetTreasury.json").abi;
const AIVotingModelABI = require("../artifacts/contracts/AIVotingModel.sol/AIVotingModel.json").abi;
const AISlashingMonitorABI = require("../artifacts/contracts/AISlashingMonitor.sol/AISlashingMonitor.json").abi;

// Initialize Contract Instances
const auditLogger = new ethers.Contract(AI_AUDIT_LOGGER_ADDRESS, AIAuditLoggerABI, provider);
const validatorContract = new ethers.Contract(NOVA_NET_VALIDATOR_ADDRESS, NovaNetValidatorABI, provider);
const governanceContract = new ethers.Contract(NOVA_NET_GOVERNANCE_ADDRESS, NovaNetGovernanceABI, provider);
const treasuryContract = new ethers.Contract(NOVA_NET_TREASURY_ADDRESS, NovaNetTreasuryABI, provider);
const votingContract = new ethers.Contract(AI_VOTING_MODEL_ADDRESS, AIVotingModelABI, provider);
const slashingMonitor = new ethers.Contract(AI_SLASHING_MONITOR_ADDRESS, AISlashingMonitorABI, provider);

// 🚀 Real-Time Event Monitoring

// 🔹 Monitor AI Governance Events
governanceContract.on("ProposalCreated", (id, proposer, description, aiScore) => {
    console.log(`📜 New Proposal Created: ID ${id}`);
    console.log(`   🏛 Proposer: ${proposer}`);
    console.log(`   📝 Description: ${description}`);
    console.log(`   🤖 AI Score: ${aiScore}`);
});

governanceContract.on("ProposalExecuted", (id) => {
    console.log(`✅ Proposal Executed: ID ${id}`);
});

// 🔹 Monitor Voting Events
votingContract.on("VoteCasted", (id, voter, support, power) => {
    console.log(`🗳 Vote Casted: Proposal ${id}`);
    console.log(`   👤 Voter: ${voter}`);
    console.log(`   👍 Support: ${support}`);
    console.log(`   ⚖ Voting Power: ${power}`);
});

// 🔹 Monitor Validator Events
validatorContract.on("ValidatorRegistered", (validator, stake) => {
    console.log(`🛡 Validator Registered: ${validator}`);
    console.log(`   💰 Staked Amount: ${ethers.utils.formatEther(stake)} NOVA`);
});

validatorContract.on("SlashingTriggered", (validator, reason) => {
    console.log(`⚠️ Validator Slashed: ${validator}`);
    console.log(`   🚨 Reason: ${reason}`);
});

// 🔹 Monitor Treasury Transactions
treasuryContract.on("FundsAllocated", (recipient, amount) => {
    console.log(`💰 Treasury Funds Allocated`);
    console.log(`   🏦 Recipient: ${recipient}`);
    console.log(`   💵 Amount: ${ethers.utils.formatEther(amount)} NOVA`);
});

// 🔹 Monitor AI Fraud Detection
slashingMonitor.on("FraudDetected", (suspect, fraudScore) => {
    console.log(`🚨 Fraudulent Activity Detected!`);
    console.log(`   ⚠️ Suspect: ${suspect}`);
    console.log(`   🔎 AI Fraud Score: ${fraudScore}`);
});

// 🔹 AI Audit Logs
auditLogger.on("AuditLogged", (timestamp, category, action, amount, executor) => {
    console.log(`📝 Audit Log Recorded:`);
    console.log(`   🕒 Timestamp: ${new Date(timestamp * 1000).toLocaleString()}`);
    console.log(`   📌 Category: ${category}`);
    console.log(`   🎯 Action: ${action}`);
    console.log(`   💰 Amount: ${ethers.utils.formatEther(amount)} NOVA`);
    console.log(`   🔍 Executor: ${executor}`);
});

// 🚀 Start Monitoring
console.log("\n🔍 NovaNet Blockchain Monitoring is LIVE...");
console.log("🔹 Tracking Governance, Validators, Treasury, and Fraud Detection Events...\n");

// Keep Process Alive
process.on("SIGINT", () => {
    console.log("\n🛑 Stopping NovaNet Monitor...");
    process.exit();
});
