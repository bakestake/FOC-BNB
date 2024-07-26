import {task} from "hardhat/config";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getSelector} from "../../scripts/selectors";
import {getConstants} from "../../scripts/libraries/getConstants";

task("raid-facet")
  .addParam("chain")
  .setAction(async (args, hre) => {
    const signer = await hre.ethers.getSigners();
    const diamondAddress =
      (await getDeployedAddressesForChain(args.chain)?.Staking) || "";

    const cutContract = await hre.ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );

    let cut = [];

    if(args.chain == "beraTestnet"){
      const chainFacet = await hre.ethers.getContractFactory("RaidHandlerAlt");
      const facet = await chainFacet.deploy();
      await facet.waitForDeployment();

      console.log("Deployed on:", facet.target);

      cut.push({
        facetAddress: facet.target,
        action: FacetCutAction.Add,
        functionSelectors: getSelector("RaidHandlerAlt"),
      });
    }else{
      const chainFacet = await hre.ethers.getContractFactory("RaidHandler");
      const facet = await chainFacet.deploy();
      await facet.waitForDeployment();

      console.log("Deployed on:", facet.target);
      cut.push({
        facetAddress: facet.target,
        action: FacetCutAction.Replace,
        functionSelectors: getSelector("RaidHandler"),
      });
    }

    console.log("Cutting diamond ");

    let tx = await cutContract.diamondCut(cut, hre.ethers.ZeroAddress, hre.ethers.id(""));
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for Raid handler Facet on : ", args.chain);
  });
