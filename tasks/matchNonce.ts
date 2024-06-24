import { task } from 'hardhat/config'
import { getProviderURLs } from './utils/getProviderUrl'
import { ethers } from 'ethers';

task('match', 'matches nonce')
    .addParam('n', 'number of transactions')
    .addParam('chain')
    .setAction(async (taskArgs, hre) => {

        const providerURL = getProviderURLs(taskArgs.chain);
        
        if (!providerURL) {
            console.error(`Provider URL for chain ${taskArgs.chain} not found`);
            return;
        }

        const signer = new ethers.Wallet(process.env.PRIVATE_KEY||"", new ethers.JsonRpcProvider(providerURL))

        for (let i = 0; i < taskArgs.n; i++) {
            const tx = await signer.sendTransaction({
            to: signer.address, // Self-send transaction
            value: ethers.parseEther("0"), // Small amount to keep fees low
            });

            // Wait for transaction to be mined
            // await tx.wait();
        }

        console.log(`Updated nonce: ${signer}`);

})
