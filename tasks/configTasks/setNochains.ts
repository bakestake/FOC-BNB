import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("set-no-chains")
.addParam("chain")
.addParam("n")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("GetterSetterFacet", deployedAddresses?.Staking || "");

        console.log("setting chain no")

        await contractInst.setNoOfChains(taskArgs.n);

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})