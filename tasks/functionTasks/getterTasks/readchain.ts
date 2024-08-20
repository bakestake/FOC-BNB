import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";

task("get-no-chains")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("GetterSetterFacet", deployedAddresses?.Staking || "");

        console.log("getting chain no")

        const chains = await contractInst.getNoOfChains();

        console.log(chains)

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})