import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("mint-narc")
.addParam("chain")
.addParam("address")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("Narc", deployedAddresses?.Narcs || "");

        console.log("Minting")

        await contractInst.safeMint(taskArgs.address);

        console.log("Minted")

    }catch(error){
        console.log("Failed to mint farmer : ",error)
        throw new Error((<Error>error).message);
    }
    
})