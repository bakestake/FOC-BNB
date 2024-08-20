import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../../scripts/libraries/getDeployedAddresses";

task("whitelist")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain("beraTestnet")

        const contractInst = await hre.ethers.getContractAt("IGauge", "0x8d7e98e3e447f12bda3d4efc97acbe278a969e0b");

        console.log("getting whitelist in bera gauge")

        const tx = await contractInst.whitelistIncentiveToken(deployedAddresses?.stBuds || "", 1, {gasLimit:1500000})
        await tx.wait();

        console.log("tx hash", tx.hash);

    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})