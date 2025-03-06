import { ethers } from "ethers";

const NOVANET_RPC_URL = "https://testnet-rpc.novanet.io";
const VALIDATOR_CONTRACT_ADDRESS = "0xValidatorContractAddress";
const VALIDATOR_ABI = require("../artifacts/contracts/NovaNetValidator.sol/NovaNetValidator.json").abi;

export async function fetchValidators() {
    const provider = new ethers.providers.JsonRpcProvider(NOVANET_RPC_URL);
    const contract = new ethers.Contract(VALIDATOR_CONTRACT_ADDRESS, VALIDATOR_ABI, provider);
    
    const validators = await contract.getValidators();
    const validatorDetails = await Promise.all(validators.map(async (validator) => {
        const uptime = await contract.getValidatorUptime(validator);
        const reputation = await contract.getValidatorReputation(validator);
        return { validator, uptime: uptime.toString(), reputation: reputation.toString() };
    }));

    return validatorDetails;
}
