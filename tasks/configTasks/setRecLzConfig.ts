import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";
import { tasks } from "hardhat";

task("rec-config")
.addParam("chain")
.addParam("to")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain);

        const toConstant = await getConstants(taskArgs.to);

        const contractInst = await hre.ethers.getContractAt("ILayerZeroEndpointV2", constants?.lzEndpoint || "");

        console.log("setting rec lib")
        console.log(toConstant?.endpointId)
        // await contractInst.setSendLibrary(deployedAddresses?.Staking || "", toConstant?.endpointId || "", constants?.sendLib||"",{gasLimit:1500000})

        const encoder = new hre.ethers.AbiCoder();

        const configTypeUlnStruct = [
            "uint64", "uint8", "uint8", "uint8", "address[]", "address[]"
        ];

        const executorConfig= [
            toConstant?.endpointId,
            1,
            encoder.encode(
                configTypeExecutorStruct,
                [
                    100000, // maxMessageSize
                    constants?.executor // executorAddress
                ]
            )
        ]

        await contractInst.setConfig(
            deployedAddresses?.Staking, 
            constants?.recLib2, 
            [
                sendConfig
            ]
        )

        console.log("done setting rec lib")

    }catch(error){
        console.log("Failed to raid : ",error)
        throw new Error((<Error>error).message);
    }
    
})