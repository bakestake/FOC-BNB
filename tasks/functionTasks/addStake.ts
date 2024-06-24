import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("stake")
.addParam("chain")
.addParam("amount")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("ChainFacet", deployedAddresses?.Staking || "");

        const BudsInst = await hre.ethers.getContractAt("SNBBuds", deployedAddresses?.BudsToken || "");

        console.log("Getting approval")

        await BudsInst.approve(deployedAddresses?.Staking || "", hre.ethers.parseEther(taskArgs.amount));

        console.log("Adding stake")

        await contractInst.addStake(hre.ethers.parseEther(taskArgs.amount),0);

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})