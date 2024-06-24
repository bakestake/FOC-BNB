import {task} from "hardhat/config";
import {getDeployedAddressesForChain} from "../scripts/libraries/getDeployedAddresses";
import {FacetCutAction} from "../scripts/getFacetCutAction";
import {getSelector} from "../scripts/selectors";
import {getConstants} from "../scripts/libraries/getConstants";

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

    const chainFacet = await hre.ethers.getContractFactory("CrossChainFacet");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    let cut = [];

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: getSelector("CrossChainFacet"),
    });

    console.log("Cutting diamond ");

    const constants = await getConstants(args.chain);

    console.log("initializing");
    let functionCall = facet.interface.encodeFunctionData("init", [
      constants?.lzEndpoint,
    ]);

    let tx = await cutContract.diamondCut(cut, facet.target, functionCall);
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for chain Facet on : ", args.chain);
  });
