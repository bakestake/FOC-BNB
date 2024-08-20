import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";

task("cc-stake")
.addParam("from")
.addParam("to")
.addParam("amount")
.addParam("token")
.setAction(async (taskArgs, hre) => {
    try{
        if(taskArgs.amount == 0 && taskArgs.token == 0){
            throw new Error("Invalid data");
        }

        const constants = await getConstants(taskArgs.to);

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.from)

        const contractInst = await hre.ethers.getContractAt("CrossChainFacet", deployedAddresses?.Staking || "");

        const BudsInst = await hre.ethers.getContractAt("Buds", deployedAddresses?.BudsToken || "");

        const FarmerInst = await hre.ethers.getContractAt("Farmer", deployedAddresses?.Farmer || "");

        if(taskArgs.amount != 0){
            console.log("Getting token approval")
            await BudsInst.approve(deployedAddresses?.Staking || "", hre.ethers.parseEther(taskArgs.amount));
        }

        if(taskArgs.token != 0){
            console.log("Getting NFT approval")
            await FarmerInst.approve(deployedAddresses?.Staking || "", taskArgs.token, {gasLimit:"1500000"});
        }

        console.log("Adding stake")

        console.log(hre.ethers.parseEther(taskArgs.amount), taskArgs.token, BigInt(constants?.endpointId || ""))

        const tx = await contractInst.crossChainStake(hre.ethers.parseEther(taskArgs.amount), taskArgs.token, BigInt(constants?.endpointId || ""), {gasLimit:2500000, value:hre.ethers.parseEther("0.9")});

        await tx.wait();

    }catch(error){
        console.log("Failed to stake : ",error)
        throw new Error((<Error>error).message);
    }
    
})