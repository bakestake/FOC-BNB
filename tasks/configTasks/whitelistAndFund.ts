import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";

task("fund-vault")
.addParam("chain")
.addParam("amount")
.setAction(async (taskArgs, hre) => {
    try{

        const accounts = await hre.ethers.getSigners();
        const contractOwner = accounts[0];

        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        console.log("creating contract instances");

        const BudsInst = await hre.ethers.getContractAt("Buds", deployedAddresses?.BudsToken || "");
        const BudsVaultInst = await hre.ethers.getContractAt("BudsVault", deployedAddresses?.budsVault || "");

        console.log("whitelisting");
        const tx2 = await BudsVaultInst.whitelistContracts([deployedAddresses?.Staking || ""])

        await tx2.wait();   

        if(taskArgs.amount != 0){
            console.log("buds approval");
            const tx = await BudsInst.approve(deployedAddresses?.budsVault || "", hre.ethers.parseEther(taskArgs.amount));

            console.log("funding");
            const tx3 = await BudsVaultInst.deposite(contractOwner.address, hre.ethers.parseEther(taskArgs.amount),{gasLimit:"1500000"})

            await tx.wait();

            console.log("funded :", taskArgs.amount)
        }
        
    }catch(error){
        console.log("Failed to unstake : ",error)
        throw new Error((<Error>error).message);
    }

})