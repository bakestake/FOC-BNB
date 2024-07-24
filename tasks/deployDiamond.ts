import {task} from "hardhat/config";
import {
  HardhatRuntimeEnvironment,
  HardhatRuntimeEnvironment as hre,
} from "hardhat/types";


task("deploy-diamond", "Deploys and initializes diamond")
  .addParam("chain")
  .setAction(async (args, hre: HardhatRuntimeEnvironment) => {
    const accounts = await hre.ethers.getSigners();
    const contractOwner = accounts[0];

    // deploy DiamondCutFacet
    const DiamondCutFacet =
      await hre.ethers.getContractFactory("DiamondCutFacet");
    const diamondCutFacet = await DiamondCutFacet.deploy();
    await diamondCutFacet.waitForDeployment();
    console.log("DiamondCutFacet deployed:", diamondCutFacet.target);

    // deploy Diamond
    const Diamond = await hre.ethers.getContractFactory("StakingDiamond");
    const diamond = await Diamond.deploy(
      contractOwner.address,
      diamondCutFacet.target
    );
    await diamond.waitForDeployment();
    console.log("Diamond deployed:", diamond.target);

  });
