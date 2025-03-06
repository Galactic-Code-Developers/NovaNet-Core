const { ethers } = require("hardhat");
const fs = require("fs");
require("dotenv").config();

// NovaNet RPC & Wallet Setup
const NOVANET_RPC_URL = process.env.NOVANET_RPC_URL || "https://testnet.novanet.io/rpc";
const provider = new ethers.providers.JsonRpcProvider(NOVANET_RPC_URL);
const WALLET_PRIVATE_KEY = process.env.PRIVATE_KEY;

// Wallet Signer
const wallet = new ethers.Wallet(WALLET_PRIVATE_KEY, provider);

// Smart Contract Addresses (Replace with actual deployed addresses)
const NOVANET_GOVERNANCE_ADDRESS = "<NovaNetGovernance_ADDRESS>";
const NOVANET_VALIDATOR_ADDRESS = "<NovaNetValidator_ADDRESS>";
const NOVANET_TREASURY_ADDRESS = "<NovaNetTreasury_ADDRESS>";
const NOVANET_BRIDGE_ADDRESS = "<NovaNetBridge_ADDRESS>";
const NOVANET_VOTING_ADDRESS = "<AIVotingModel_ADDRESS>";

// ABI Imports (Replace with compiled ABI files)
const NovaNetGovernanceABI = require("../artifacts/contracts/NovaNetGovernance.sol/NovaNetGovernance.json").abi;
const NovaNetValidatorABI = require("../artifacts/contracts/NovaNetValidator.sol/NovaNetValidator.json").abi;
const NovaNetTreasuryABI = require("../artifacts/contracts/NovaNetTreasury.sol/NovaNetTreasury.json").abi;
const NovaNetBridgeABI = require("../artifacts/contracts/NovaNetBridge.sol/NovaNetBridge.json").abi;
const AIVotingModelABI = require("../artifacts/contracts/AIVotingModel.sol/AIVotingModel.json").abi;

// Initialize Contracts
const governanceContract = new ethers.Contract(NOVANET_GOVERNANCE_ADDRESS, NovaNetGovernanceABI, wallet);
const validatorContract = new ethers.Contract(NOVANET_VALIDATOR_ADDRESS, NovaNetValidatorABI, wallet);
const treasuryContract = new ethers.Contract(NOVANET_TREASURY_ADDRESS, NovaNetTreasuryABI, wallet);
const bridgeContract = new ethers.Contract(NOVANET_BRIDGE_ADDRESS, NovaNetBridgeABI, wallet);
const votingContract = new ethers.Contract(NOVANET_VOTING_ADDRESS, AIVotingModelABI, wallet);

// 📊 Gas Analysis Function
async function analyzeGasUsage() {
    console.log("\n🚀 Running Gas Analysis on NovaNet Contracts...");

    const gasReport = [];

    // 📝 Function List for Gas Measurement
    const functionCalls = [
        {
            name: "Submit Proposal (Governance)",
            contract: governanceContract,
            method: "submitProposal",
            args: ["Increase validator rewards", 500, ethers.utils.parseEther("50"), wallet.address]
        },
        {
            name: "Vote on Proposal",
            contract: votingContract,
            method: "vote",
            args: [1, true]
        },
        {
            name: "Register Validator",
            contract: validatorContract,
            method: "registerValidator",
            args: [],
            value: ethers.utils.parseEther("10")
        },
        {
            name: "Allocate Treasury Funds",
            contract: treasuryContract,
            method: "allocateFunds",
            args: [wallet.address, ethers.utils.parseEther("100")]
        },
        {
            name: "Bridge Assets",
            contract: bridgeContract,
            method: "bridgeTokens",
            args: [wallet.address, "Ethereum", ethers.utils.parseEther("5")]
        }
    ];

    // 🔹 Execute Gas Analysis for Each Function
    for (const call of functionCalls) {
        try {
            const gasEstimate = await call.contract.estimateGas[call.method](...call.args, { value: call.value || 0 });
            console.log(`✅ ${call.name}: Estimated Gas = ${gasEstimate.toString()}`);

            gasReport.push({
                function: call.name,
                gasUsed: gasEstimate.toString()
            });

        } catch (error) {
            console.log(`❌ Failed to estimate gas for ${call.name}:`, error.message);
        }
    }

    // 🔹 Save Report to JSON
    fs.writeFileSync("gas-report.json", JSON.stringify(gasReport, null, 2));
    console.log("\n📊 Gas Report Saved to `gas-report.json`!");
}

// 🚀 Run Gas Analysis
analyzeGasUsage()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Gas Analysis Failed!", error);
        process.exit(1);
    });
