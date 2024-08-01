import { task } from "hardhat/config";
import { getDeployedAddressesForChain } from "../../scripts/libraries/getDeployedAddresses";
import { getConstants } from "../../scripts/libraries/getConstants";
import { tasks } from "hardhat";

task("send-config")
.addParam("chain")
.addParam("to")
.setAction(async (taskArgs, hre) => {
    try{
        const deployedAddresses = await getDeployedAddressesForChain(taskArgs.chain)

        const constants = await getConstants(taskArgs.chain);

        const toConstant = await getConstants(taskArgs.to);

        const contractInst = await hre.ethers.getContractAt("ILayerZeroEndpointV2", constants?.lzEndpoint || "");

        console.log("setting send lib")
        console.log(toConstant?.endpointId)

        const encoder = new hre.ethers.AbiCoder();

        const configTypeUlnStruct = [
            "uint64", "uint8", "uint8", "uint8", "address[]", "address[]"
        ];
        const configTypeExecutorStruct = [
            "uint32", "address"
        ];

        const sendConfig = [
            toConstant?.endpointId,
            2,
            encoder.encode(
                configTypeUlnStruct,
                [2,1,1,1,constants?.dvn, constants?.dvn]
            )
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

        await contractInst.setSendLibrary(deployedAddresses?.Staking || "", toConstant?.endpointId || "", constants?.sendLib2||"",{gasLimit:1500000})

        await contractInst.setConfig(
            deployedAddresses?.Staking, 
            constants?.sendLib2, 
            [
                executorConfig
            ],
            {
                gasLimit:1500000
            }
        )

        console.log("done setting send lib")

    }catch(error){
        console.log("Failed to set send config : ",error)
        throw new Error((<Error>error).message);
    }
    
})