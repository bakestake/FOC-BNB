import {ethers, upgrades} from "hardhat";
import {getSelector} from "../../scripts/selectors";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {
  DiamondCutFacet__factory,
  GetterSetterFacet__factory,
} from "../../types";
import {AddressLike, Contract} from "ethers";
import {getDeployedAddressesForChain} from "../../scripts/libraries/getDeployedAddresses";
import {getConstants} from "../../scripts/libraries/getConstants";

export const deployFixture = async (
  supraRouter: string,
  boosterSeed: number,
  charSeed: number
) => {
  const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

  const Informant = await ethers.getContractFactory("SNBInformant");
  const informant = await upgrades.deployProxy(Informant, [boosterSeed, ""], {
    initializer: "initialize",
    kind: "uups",
  });
  const informantAddress = await informant.getAddress();

  const Stoner = await ethers.getContractFactory("SNBStoner");
  const stoner = await upgrades.deployProxy(Stoner, [boosterSeed, ""], {
    initializer: "initialize",
    kind: "uups",
  });
  const stonerAddress = await stoner.getAddress();

  const Buds = await ethers.getContractFactory("SNBBuds");
  const buds = await upgrades.deployProxy(
    Buds,
    [supraRouter, informantAddress, stonerAddress],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  const budsAddress = await buds.getAddress();

  const Vault = await ethers.getContractFactory("BudsVault");
  const vault = await upgrades.deployProxy(Vault, [budsAddress], {
    initializer: "initialize",
    kind: "uups",
  });
  const vaultAddress = await vault.getAddress();

  const Xp = await ethers.getContractFactory("SNBXP");
  const xp = await upgrades.deployProxy(Xp, [vaultAddress], {
    initializer: "initialize",
    kind: "uups",
  });
  const xpAddress = await xp.getAddress();

  const Farmer = await ethers.getContractFactory("SNBFarmer");
  const farmer = await upgrades.deployProxy(
    Farmer,
    [charSeed, xpAddress, ["", "", "", "", "", "", "", "", "", ""]],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  const farmerAddress = await farmer.getAddress();

  const Narc = await ethers.getContractFactory("SNBNarc");
  const narc = await upgrades.deployProxy(
    Narc,
    [charSeed, xpAddress, ["", "", "", "", "", "", "", "", "", ""]],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  const narcAddress = await narc.getAddress();

  return {
    owner,
    addr1,
    addr2,
    addr3,
    addr4,
    xpAddress,
    vaultAddress,
    budsAddress,
    farmerAddress,
    narcAddress,
    informantAddress,
    stonerAddress,
  };
};
