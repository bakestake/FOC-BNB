import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("stake")
.addParam("chain")
.addParam("amount")
.addParam("token")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("ChainFacet", deployedAddresses?.Staking || "");

        const BudsInst = await hre.ethers.getContractAt("Buds", deployedAddresses?.BudsToken || "");

        const FarmerInst = await hre.ethers.getContractAt("Farmer", deployedAddresses?.Farmer || "");

        if(taskArgs.token != 0){
            console.log("Getting NFT approval")
            const tx = await FarmerInst.approve(deployedAddresses?.Staking || "", taskArgs.token, {gasLimit:"1500000"});
            await tx.wait();
        }

        console.log("Getting approval")

        const tx2 = await BudsInst.approve(deployedAddresses?.Staking || "", hre.ethers.parseEther(taskArgs.amount));
        await tx2.wait();

        console.log("Adding stake")

        await contractInst.addStake(hre.ethers.parseEther(taskArgs.amount), taskArgs.token, {gasLimit:1500000});

    }catch(error){
        console.log("Failed to add stake : ",error)
        throw new Error((<Error>error).message);
    }
    
})
