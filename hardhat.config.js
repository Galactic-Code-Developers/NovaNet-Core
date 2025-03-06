require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("hardhat-gas-reporter");
require("solidity-coverage");

// Load Environment Variables
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NOVANET_RPC_TESTNET = process.env.NOVANET_RPC_TESTNET || "https://testnet-rpc.novanet.io";
const NOVANET_RPC_MAINNET = process.env.NOVANET_RPC_MAINNET || "https://rpc.novanet.io";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY; // For contract verification

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            allowUnlimitedContractSize: false,
            forking: {
                url: NOVANET_RPC_TESTNET,
                blockNumber: 100000, // Adjust as needed
            }
        },
        testnet: {
            url: NOVANET_RPC_TESTNET,
            accounts: [PRIVATE_KEY],
            chainId: 1030,
            gas: "auto",
            gasPrice: 5000000000, // 5 Gwei
        },
        mainnet: {
            url: NOVANET_RPC_MAINNET,
            accounts: [PRIVATE_KEY],
            chainId: 2030,
            gas: "auto",
            gasPrice: 5000000000, // 5 Gwei
        }
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 40000,
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        outputFile: "gas-report.txt",
        noColors: true,
    }
};
