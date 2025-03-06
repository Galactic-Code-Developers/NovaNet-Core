📌 Recommended Directory & File Structure
Directory / File
Purpose
contracts/
Contains core Solidity smart contracts for NovaNet.
contracts/NovaNetConsensus.sol
Implements hybrid consensus (Q-DPoS + AI Optimizations).
contracts/NovaNetValidator.sol
Manages validator registration & staking.
contracts/NovaNetSlashing.sol
Handles misbehavior penalties & validator slashing.
contracts/NovaNetGovernance.sol
AI-driven on-chain governance and voting.
contracts/NovaNetTreasury.sol
Manages fund allocations & treasury reserves.
contracts/NovaNetStaking.sol
Staking & delegation smart contract for validators & delegators.
contracts/NovaNetOracle.sol
Off-chain data integration for smart contracts.
contracts/NovaNetBridge.sol
Cross-chain bridge to Ethereum, Polkadot, and Cosmos.
contracts/AIVotingModel.sol
AI-powered governance proposal ranking & voting weight.
contracts/AIRewardDistribution.sol
AI-driven staking rewards & treasury funding.
contracts/AISlashingMonitor.sol
AI-powered misbehavior monitoring & automatic slashing.
contracts/AIGovernanceFraudDetection.sol
Detects vote manipulation & governance fraud.
contracts/AIValidatorSelection.sol
AI-driven validator ranking & selection.
contracts/AIAuditLogger.sol
Stores AI-driven governance actions for transparency.
rpc/
Contains configuration files for NovaNet RPC Nodes.
rpc/config.toml
RPC configuration file (Ports, security, and access control).
rpc/run_rpc.sh
Bash script to start the RPC node.
test/
Contains unit tests & integration tests for NovaNet.
test/NovaNetConsensus.test.js
Tests consensus finality & block production.
test/NovaNetValidator.test.js
Tests staking, slashing, and validator elections.
test/NovaNetGovernance.test.js
Tests governance proposal lifecycle.
test/NovaNetTreasury.test.js
Ensures correct treasury fund distribution.
test/AIVotingModel.test.js
Verifies AI-powered voting & scoring system.
scripts/
Scripts for deployment, monitoring, and contract interaction.
scripts/deploy.js
Deploys smart contracts to testnet & mainnet.
scripts/monitor.js
Monitors validator performance in real time.
scripts/gas-analysis.js
Runs gas efficiency tests for contract execution.
scripts/slashing-checker.js
Detects malicious validators & applies slashing penalties.
config/
Contains network configurations & environment variables.
config/env.testnet
NovaNet testnet environment settings.
config/env.mainnet
NovaNet mainnet environment settings.
hardhat.config.js
Hardhat configuration for Solidity development & deployment.
package.json
Node.js dependencies for Hardhat, Mocha, Chai, and testing tools.
README.md
Documentation on how to run NovaNet-Core.
Dockerfile
Containerized NovaNet node setup for deployment.
Makefile
Automates building, testing, and deploying NovaNet.
