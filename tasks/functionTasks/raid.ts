import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("raid")
.addParam("chain")
.addParam("token")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("ChainFacet", deployedAddresses?.Staking || "");

        const InformantInst = await hre.ethers.getContractAt("Informant", deployedAddresses?.Informant || "");

        if(taskArgs.token != 0){
            console.log("Getting approval")
            await InformantInst.approve(deployedAddresses?.Staking || "", taskArgs.token);
        }

        console.log("raiding")

        await contractInst.raid(taskArgs.token, {value:hre.ethers.parseEther("0.005"), gasLimit:"1500000"});

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})