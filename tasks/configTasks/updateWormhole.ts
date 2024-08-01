import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("set-wormhole-address")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("StateUpdate", deployedAddresses?.Staking || "");

        console.log("setting worhmole address")

        await contractInst.changeWormholeAddress(constants?.wormhole || "");

    }catch(error){
        console.log("Failed to set address : ",error)
        throw new Error((<Error>error).message);
    }
    
})