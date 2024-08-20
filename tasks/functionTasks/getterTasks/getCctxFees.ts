import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../../scripts/libraries/getConstants";

task("get-fees")
.addParam("from")
.addParam("to")
.setAction(async (taskArgs, hre) => {
    try{
       
        const constants = await getConstants(taskArgs.to);

        const constFrom = await getConstants(taskArgs.from);

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.from)

        const contractInst = await hre.ethers.getContractAt("CrossChainFacet", deployedAddresses?.Staking || "");

        // const endpointContractInst = await hre.ethers.getContractAt("ILayerZeroEndpointV2", constFrom?.lzEndpoint || "");

        console.log("querying")

        const data = await contractInst.getCctxFees(constants?.endpointId || "" , 1000, 0, "0x066a697f575ca96AafA54D3b6eC1a33A062B83bd", {gasLimit:2_500_000});

        console.log(data)

    }catch(error){
        console.log("Failed to read : ",error)
        throw new Error((<Error>error).message);
    }
    
})