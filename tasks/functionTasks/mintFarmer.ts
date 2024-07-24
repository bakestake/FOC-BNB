import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("mint-farmer")
.addParam("chain")
.addParam("address")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("Farmer", deployedAddresses?.Farmer || "");

        console.log("Minting")

        await contractInst.safeMint(taskArgs.address);

        console.log("Minted")

    }catch(error){
        console.log("Failed to mint farmer : ",error)
        throw new Error((<Error>error).message);
    }
    
})