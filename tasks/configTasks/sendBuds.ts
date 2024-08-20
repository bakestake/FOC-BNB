import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("send-buds")
.addParam("chain")
.addParam("amount")
.addParam("to")
.setAction(async (taskArgs, hre) => {
    try{

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const BudsInst = await hre.ethers.getContractAt("Buds", deployedAddresses?.BudsToken || "");

        const tx = await BudsInst.transfer(taskArgs.to, hre.ethers.parseEther(taskArgs.amount));

        await tx.wait();

        console.log("sent :", taskArgs.amount)
        console.log("to :", taskArgs.to)
        
    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }

})