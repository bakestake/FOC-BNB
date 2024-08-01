import {task} from "hardhat/config";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getSelector} from "../../scripts/selectors";
import {getConstants} from "../../scripts/libraries/getConstants";
import { AddressLike } from "ethers";

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

    const DiamondInit = await hre.ethers.getContractFactory("DiamondInit");
    const diamondInit = await DiamondInit.deploy();
    await diamondInit.waitForDeployment();
    console.log("DiamondInit deployed:", diamondInit.target);

    const addresses = getDeployedAddressesForChain(args.chain);

    let params = [];
    const constants = await getConstants(args.chain);
    const tokenAddresses: AddressLike[] = [
      addresses?.BudsToken || "",
      addresses?.Farmer || "",
      addresses?.Narcs || "",
      addresses?.Stoner || "",
      addresses?.Informant || "",
    ];
    params.push(tokenAddresses);
    params.push(constants?.wormhole);
    params.push(addresses?.budsVault || "");
    params.push(constants?.supraRouter)
    params.push(constants?.minter || "");
    params.push(constants?.chainId);

    let functionCall = diamondInit.interface.encodeFunctionData("init", params);

    let cut = [];

    const chainFacet = await hre.ethers.getContractFactory("RaidHandler");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Replace,
      functionSelectors: getSelector("RaidHandler"),
    });
    
    console.log("Cutting diamond ");

    let tx = await cutContract.diamondCut(cut, diamondInit.target, functionCall);
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for Raid handler Facet on : ", args.chain);
  });
