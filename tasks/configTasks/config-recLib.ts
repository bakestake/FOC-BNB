import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("set-reclib")
.addParam("chain")
.addParam("from")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain);

        const fromConst= await getConstants(taskArgs.chain);

        const contractInst = await hre.ethers.getContractAt("ILayerZeroEndpointV2", constants?.lzEndpoint || "");

        console.log("setting rec lib")

        await contractInst.setReceiveLibrary(deployedAddresses?.Staking || "", fromConst?.endpointId || "", constants?.recLib2||"",0, {gasLimit:1500000})

        console.log("done setting rec lib")

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})