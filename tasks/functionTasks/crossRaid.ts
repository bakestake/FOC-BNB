import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("cc-raid")
.addParam("from")
.addParam("to")
.addParam("token")
.setAction(async (taskArgs, hre) => {
    try{
       
        const constants = await getConstants(taskArgs.to);

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.from)

        const contractInst = await hre.ethers.getContractAt("CrossChainFacet", deployedAddresses?.Staking || "");

        const InformantInst = await hre.ethers.getContractAt("Informant", deployedAddresses?.Informant || "");

        if(taskArgs.token != 0){
            console.log("Getting NFT approval")
            await InformantInst.approve(deployedAddresses?.Staking || "", taskArgs.token);
        }

        console.log("raiding")

        await contractInst.crossChainRaid(BigInt(constants?.endpointId || ""), taskArgs.token, {value:hre.ethers.parseEther("0.075"), gasLimit:"2500000"});

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})