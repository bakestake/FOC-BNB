import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";

task("stake-gauge")
.addParam("amount")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain("beraTestnet")

        const contractInst = await hre.ethers.getContractAt("StBuds", deployedAddresses?.stBuds || "");

        console.log("staking in bera gauge")

        const tx1 = contractInst.approve(deployedAddresses?.stBuds || "", hre.ethers.parseEther(taskArgs.amount));

        (await tx1).wait();

        console.log("tx1 hash:",(await tx1).hash)

        const tx = contractInst.stakeInBeraGauge(hre.ethers.parseEther(taskArgs.amount),{gasLimit:1500000});

        (await tx).wait();

        console.log("tx hash:",(await tx).hash)

        console.log("staked in gauge:", taskArgs.amount)

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})