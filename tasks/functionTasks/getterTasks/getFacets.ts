import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";

task("get-facets")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("DiamondLoupeFacet", deployedAddresses?.Staking || "");

        console.log("getting facets")

        const res = await contractInst.facets();

        console.log(res)

    }catch(error){
        console.log("Failed to get facets : ",error)
        throw new Error((<Error>error).message);
    }
})