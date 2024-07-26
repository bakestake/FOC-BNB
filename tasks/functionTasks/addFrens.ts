import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";
import {getChains} from "../../constants/getChains"
import ethers from 'ethers'

task("set-peers")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("CrossChainFacet", deployedAddresses?.Staking || "");

        const chains = getChains();

        for(let i = 0; i < chains.length; i++){
            if(taskArgs.chain == chains[i]) continue

            console.log("Setting peer")

            const constants = await getConstants(chains[i]);

            const targetChainAddresses = await getDeployedAddressesForChain(chains[i])

            console.log(constants?.endpointId || "", targetChainAddresses?.Staking || "")

            console.log(hre.ethers.zeroPadValue(targetChainAddresses?.Staking || "", 32))

            const tx = await contractInst.setPeer(constants?.endpointId || "", hre.ethers.zeroPadValue(targetChainAddresses?.Staking || "", 32), {gasLimit:2500000});

            await tx.wait();

            console.log("Done")
        }

    }catch(error){
        console.log("Failed to set peers : ",error)
        throw new Error((<Error>error).message);
    }
    
})