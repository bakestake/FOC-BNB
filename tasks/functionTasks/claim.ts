import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("claim")
.addParam("chain")
.addParam("index")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("ChainFacet", deployedAddresses?.Staking || "");

        console.log("unstaking")

        await contractInst.claimRewards(taskArgs.index);

        console.log("unstake done")
    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})