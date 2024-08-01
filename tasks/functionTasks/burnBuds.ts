import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("burn-buds")
.addParam("chain")
.addParam("token")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("BurnFacet", deployedAddresses?.Staking || "");

        const BudsInst = await hre.ethers.getContractAt("Buds", deployedAddresses?.BudsToken || "");

        console.log("Getting approval")

        const tx2 = await BudsInst.approve(deployedAddresses?.Staking || "", hre.ethers.parseEther("1000"));
        await tx2.wait();

        console.log("burning buds")

        if(taskArgs.token == 0){
            await contractInst.burnForInformant({gasLimit:1500000});
        }else{
            await contractInst.burnForStoner({gasLimit:1500000})
        }

    }catch(error){
        console.log("Failed to burn buds : ",error)
        throw new Error((<Error>error).message);
    }
    
})