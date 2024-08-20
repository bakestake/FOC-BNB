import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("set-gauge")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain("beraTestnet")

        const contractInst = await hre.ethers.getContractAt("StBuds", deployedAddresses?.stBuds || "");

        console.log("staking in bera gauge")

        const tx = contractInst.setBeraGauge("0x8d7E98e3E447F12BDA3D4Efc97acBE278a969e0B",{gasLimit:1500000});

        (await tx).wait();

        console.log((await tx).hash)
    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }
    
})