import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import axios from "axios"

task("update-global")
.addParam("chain")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const contractInst = await hre.ethers.getContractAt("StateUpdate", deployedAddresses?.Staking || "");

        console.log("querying ")

        const res = await axios.get('http://13.39.24.134:3000/updateGlobalLiquidity', {
            headers: {
                'API-KEY': 'B1q2a3z4w5s-A0p9lh-K5t6f7b-E4r5t6y',
            }
        });
        console.log(res.data.bytes)
        console.log(res.data.sigs)
        console.log("updating ")
        const tx = await contractInst.updateState(
            res.data.bytes,
            res.data.sigs,
            {gasLimit:"2500000"});

        await tx.wait()

    }catch(error){
        console.log("Failed to update liquidity : ",error)
        throw new Error((<Error>error).message);
    }
    
})