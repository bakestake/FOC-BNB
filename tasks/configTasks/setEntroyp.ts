import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("set-pyth")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain);

        const contractInst = await hre.ethers.getContractAt("RaidHandlerAlt", deployedAddresses?.Staking || "");

        console.log("setting")

        await contractInst.setEntropy(constants?.pyth || "",{gasLimit:"1500000"})

        console.log("done")

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})