import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";

task("get-gauge-list")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain("beraTestnet")

        const contractInst = await hre.ethers.getContractAt("IGauge", "0x8d7E98e3E447F12BDA3D4Efc97acBE278a969e0B");

        console.log("getting whitelist in bera gauge")

        // const list = await contractInst.getWhitelistedTokens();

        // console.log(list)

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})