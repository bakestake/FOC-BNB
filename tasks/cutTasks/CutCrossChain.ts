import {task} from "hardhat/config";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getSelector} from "../../scripts/selectors";
import {getConstants} from "../../scripts/libraries/getConstants";

task("cross-chain-facet")
  .addParam("chain")
  .setAction(async (args, hre) => {
    const signer = await hre.ethers.getSigners();
    const diamondAddress =
      (await getDeployedAddressesForChain(args.chain)?.Staking) || "";

    const cutContract = await hre.ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );

    const DiamondInit = await hre.ethers.getContractFactory("LzInit");
    const diamondInit = await DiamondInit.deploy();
    await diamondInit.waitForDeployment();
    console.log("DiamondInit deployed:", diamondInit.target);

    const chainFacet = await hre.ethers.getContractFactory("CrossChainFacet");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    let cut = [];

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Replace,
      functionSelectors: getSelector("CrossChainFacet"),
    });

    console.log("Cutting diamond ");

    const constants = await getConstants(args.chain);

    console.log("initializing");
    let functionCall = diamondInit.interface.encodeFunctionData("init", [constants?.lzEndpoint]);

    let tx = await cutContract.diamondCut(cut, diamondInit.target, functionCall, {gasLimit:2500000});
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for chain Facet on : ", args.chain);
  });
