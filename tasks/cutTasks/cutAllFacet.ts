import {task} from "hardhat/config";
import {
  HardhatRuntimeEnvironment,
  HardhatRuntimeEnvironment as hre,
} from "hardhat/types";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getSelector} from "../../scripts/selectors";
import {getConstants} from "../../scripts/libraries/getConstants";
import {AddressLike} from "ethers";

task("cut-all", "Deploys and initializes diamond")
  .addParam("chain")
  .setAction(async (args, hre: HardhatRuntimeEnvironment) => {
    const accounts = await hre.ethers.getSigners();
    const contractOwner = accounts[0];

    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await hre.ethers.getContractFactory("DiamondInit");
    const diamondInit = await DiamondInit.deploy();
    await diamondInit.waitForDeployment();
    console.log("DiamondInit deployed:", diamondInit.target);

    // deploy facets
    console.log("");
    console.log("Deploying facets");
    const FacetNames = ["DiamondLoupeFacet","ChainFacet","CrossChainFacet","GetterSetterFacet","BurnFacet","StateUpdate","RaidHandler"];
    const cut = [];
    for (const FacetName of FacetNames) {
      const Facet = await hre.ethers.getContractFactory(FacetName);
      const facet = await Facet.deploy();
      await facet.waitForDeployment();
      console.log(`${FacetName} deployed: ${facet.target}`);
      cut.push({
        facetAddress: facet.target,
        action: FacetCutAction.Add,
        functionSelectors: getSelector(FacetName),
      });
    }

    // upgrade diamond with facets
    const addresses = getDeployedAddressesForChain(args.chain);
    // // console.log("");
    console.log("Diamond Cut:", cut);

    const diamondCut = await hre.ethers.getContractAt(
      "IDiamondCut",
      addresses?.Staking ||""
    );

    let params = [];
    const constants = await getConstants(args.chain);
    const tokenAddresses: AddressLike[] = [
      addresses?.BudsToken || "",
      addresses?.Farmer || "",
      addresses?.Narcs || "",
      addresses?.Stoner || "",
      addresses?.Informant || "",
      addresses?.stBuds || ""
    ];
    params.push(tokenAddresses);
    params.push(constants?.wormhole);
    params.push(addresses?.budsVault || "");
    params.push(constants?.supraRouter)
    params.push(constants?.minter || "");
    params.push(constants?.chainId);

    
    console.log("params:",params)
    let tx;
    let receipt;
    // call to init function
    let functionCall = diamondInit.interface.encodeFunctionData("init", params);
    tx = await diamondCut.diamondCut(
      cut,
      diamondInit.target,
      functionCall,
      {gasLimit:5500000}
    );
    console.log("Diamond cut tx: ", tx.hash);
    receipt = await tx.wait();
    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }
    console.log("Completed diamond cut");
  });
