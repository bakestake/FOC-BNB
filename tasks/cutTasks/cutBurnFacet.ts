import {task} from "hardhat/config";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getSelector} from "../../scripts/selectors";
import {getConstants} from "../../scripts/libraries/getConstants";

task("burn-facet")
  .addParam("chain")
  .setAction(async (args, hre) => {
    const diamondAddress =
      (await getDeployedAddressesForChain(args.chain)?.Staking) || "";

    console.log("diamond address,", diamondAddress)

    const cutContract = await hre.ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );

    const chainFacet = await hre.ethers.getContractFactory("BurnFacet");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    let cut = [];

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Replace,
      functionSelectors:  getSelector("StateUpdate"),
    });

    console.log("Cutting diamond ");

    const wormhole =  await getConstants(args.chain);

    console.log(wormhole?.wormhole)

    //let functionCall = facet.interface.encodeFunctionData("initStateUpdate", [wormhole?.wormhole]);

    console.log("function call created.. making a cut now")

    let tx = await cutContract.diamondCut(cut, hre.ethers.ZeroAddress, hre.ethers.id(""), {gasLimit: 1500000});
    console.log("Diamond cut tx: ", tx.hash);

    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for chain Facet on : ", args.chain);
  });
