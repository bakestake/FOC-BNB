import {task} from "hardhat/config";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getSelector} from "../../scripts/selectors";

task("chain-facet")
  .addParam("chain")
  .setAction(async (args, hre) => {
    const signer = await hre.ethers.getSigners();
    const diamondAddress =
      (await getDeployedAddressesForChain(args.chain)?.Staking) || "";

    const cutContract = await hre.ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );

    const chainFacet = await hre.ethers.getContractFactory("ChainFacet");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    let cut = [];

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Replace,
      functionSelectors: getSelector("ChainFacet"),
    });
    
    console.log("Cutting diamond ");

    let tx = await cutContract.diamondCut(cut, hre.ethers.ZeroAddress, hre.ethers.id(""),{gasLimit:"2500000"});
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for chain Facet on : ", args.chain);
  });
