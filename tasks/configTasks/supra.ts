import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("supra")
.addParam("chain")
.addParam("fund")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("ISupraDeposite", constants?.supraDeposite || "");

        console.log("whitelisting")

        await contractInst.addContractToWhitelist(deployedAddresses?.Staking || "");

        console.log("Whitelisted");

        if(taskArgs.fund != 0){
            console.log("Funding")

            await contractInst.depositFundClient({value: hre.ethers.parseEther(taskArgs.fund)});

            console.log("Funded")
        }
        

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})