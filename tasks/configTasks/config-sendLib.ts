import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";
import { tasks } from "hardhat";

task("set-sendlib")
.addParam("chain")
.addParam("to")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain);

        const toConstant = await getConstants(taskArgs.to);

        const contractInst = await hre.ethers.getContractAt("ILayerZeroEndpointV2", constants?.lzEndpoint || "");

        console.log("setting rec lib")
        console.log(toConstant?.endpointId)
        await contractInst.setSendLibrary(deployedAddresses?.Staking || "", toConstant?.endpointId || "", constants?.sendLib||"",{gasLimit:1500000})

        console.log("done setting rec lib")

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})