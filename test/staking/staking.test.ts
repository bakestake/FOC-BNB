import {ethers} from "hardhat";
import {deployFixture} from "./staking.fixture";
import {getConstants} from "../../scripts/libraries/getConstants";
import {AddressLike, Contract} from "ethers";
import {
  BudsVault__factory,
  ChainFacet__factory,
  DiamondCutFacet__factory,
  GetterSetterFacet__factory,
  SNBBuds__factory,
  SNBFarmer__factory,
  SNBStoner__factory,
  Utils__factory,
} from "../../types";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {getSelector} from "../../scripts/selectors";
import {expect} from "chai";
import {time} from "@nomicfoundation/hardhat-network-helpers";

describe("Same Chain Test cases", async function () {
  let constants = await getConstants("amoy");
  beforeEach(async function () {
    const {
      owner,
      addr1,
      addr2,
      addr3,
      addr4,
      xpAddress,
      vaultAddress,
      budsAddress,
      diamondAddress,
      farmerAddress,
      narcAddress,
      informantAddress,
      stonerAddress,
    } = await deployFixture(constants.supraRouter, 1, 1);
    this.owner = owner;
    this.addr1 = addr1;
    this.addr2 = addr2;
    this.addr3 = addr3;
    this.addr4 = addr4;
    this.diamondAddress = diamondAddress;
    this.xpAddress = xpAddress;
    this.vaultAddress = vaultAddress;
    this.budsAddress = budsAddress;
    this.farmerAddress = farmerAddress;
    this.narcAddress = narcAddress;
    this.informantAddress = informantAddress;
    this.stonerAddress = stonerAddress;

    const chainFacet = await ethers.getContractFactory("ChainFacet");
    const chainfacet = await chainFacet.deploy();
    const chainFacetAddress = await chainfacet.getAddress();

    this.chainFacetAddress = chainFacetAddress;

    const diamondCut = new Contract(
      diamondAddress,
      DiamondCutFacet__factory.abi,
      owner
    );

    const InitFacet = await ethers.getContractFactory("DiamondInit");
    const InitDeploy = await InitFacet.deploy();
    const initAddress = await InitDeploy.getAddress();

    const getterSetter = await ethers.getContractFactory("GetterSetterFacet");
    const GetterSetter = await getterSetter.deploy();
    const getterSetterAddress = await GetterSetter.getAddress();

    const gsSelectors = getSelector("GetterSetterFacet");

    this.getterSetterAddress = getterSetterAddress;

    let params = [];
    const tokenAddresses: AddressLike[] = [
      budsAddress as AddressLike,
      farmerAddress as AddressLike,
      narcAddress as AddressLike,
      stonerAddress as AddressLike,
      informantAddress as AddressLike,
    ];
    params.push(tokenAddresses);
    params.push(this.vaultAddress as AddressLike);
    params.push(constants.supraRouter);
    params.push(owner.address as AddressLike);
    params.push(80002);

    let functionCall = InitDeploy.interface.encodeFunctionData("init", params);

    const chainSelectors = getSelector("ChainFacet");

    await diamondCut.diamondCut(
      [
        {
          facetAddress: chainFacetAddress,
          action: FacetCutAction.Add,
          functionSelectors: chainSelectors,
        },
        {
          facetAddress: getterSetterAddress,
          action: FacetCutAction.Add,
          functionSelectors: gsSelectors,
        },
      ],
      initAddress,
      functionCall
    );
  });
  describe("Stake function Tests", async function () {
    it("Should revert when trying to stake asset not owned", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      await farmerContract.safeMint(this.addr2);

      await expect(
        chainFacet.addStake(ethers.parseEther("0"), 1)
      ).to.be.rejectedWith("NotOwnerOfAsset()");
    });

    it("Should revert when trying to stake with 0 buds and 0 tokenID", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      await expect(
        chainFacet.addStake(ethers.parseEther("0"), 0)
      ).to.be.rejectedWith("InvalidData()");
    });

    it("Should revert when trying to stake more than one farmer", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      await farmerContract.safeMint(this.addr1);

      await farmerContract.safeMint(this.addr1);

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr1
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await farmerContractSpender.approve(this.diamondAddress, 2);

      await chainFacet.addStake(ethers.parseEther("0"), 1);

      await expect(
        chainFacet.addStake(ethers.parseEther("0"), 2)
      ).to.be.rejectedWith("FarmerStakedAlready()");
    });

    it("Should reflect all state changes", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await chainFacet.addStake(ethers.parseEther("10000"), 1);

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );
      const stake = await getterFacet.getUserStakes(this.addr2);

      expect(await getterFacet.getlocalStakedBuds()).to.be.equal(
        ethers.parseEther("10000")
      );

      expect(await getterFacet.getGlobalStakedBuds()).to.be.equal(
        ethers.parseEther("10000")
      );

      expect(stake[0].budsAmount).to.be.equal(ethers.parseEther("10000"));

      expect(stake[0].farmerTokenId).to.be.equal(1);

      expect(stake[0].owner).to.be.equal(this.addr2);
    });

    it("Should keep record of two stakes by one staker separate", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("30000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("30000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("10000"), 1);
      await chainFacet.addStake(ethers.parseEther("20000"), 0);

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );
      const stake = await getterFacet.getUserStakes(this.addr2);

      expect(await getterFacet.getlocalStakedBuds()).to.be.equal(
        ethers.parseEther("30000")
      );

      expect(await getterFacet.getGlobalStakedBuds()).to.be.equal(
        ethers.parseEther("30000")
      );

      expect(stake[0].budsAmount).to.be.equal(ethers.parseEther("10000"));

      expect(stake[0].farmerTokenId).to.be.equal(1);

      expect(stake[0].owner).to.be.equal(this.addr2);

      expect(stake[1].budsAmount).to.be.equal(ethers.parseEther("20000"));

      expect(stake[1].farmerTokenId).to.be.equal(0);

      expect(stake[1].owner).to.be.equal(this.addr2);
    });

    it("Should keep record of two stakes separate", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const chainFacetadr1 = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.transfer(this.addr1, ethers.parseEther("25600"));

      await farmerContract.safeMint(this.addr2);

      await farmerContract.safeMint(this.addr1);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      const budsadr2 = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr1
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      await budsadr2.approve(this.diamondAddress, ethers.parseEther("25600"));

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const farmerContractadr1 = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr1
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await farmerContractadr1.approve(this.diamondAddress, 2);

      await chainFacet.addStake(ethers.parseEther("10000"), 1);
      await chainFacetadr1.addStake(ethers.parseEther("25600"), 2);

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );
      const stake = await getterFacet.getUserStakes(this.addr2);
      const stake2 = await getterFacet.getUserStakes(this.addr1);

      expect(await getterFacet.getlocalStakedBuds()).to.be.equal(
        ethers.parseEther("35600")
      );

      expect(await getterFacet.getGlobalStakedBuds()).to.be.equal(
        ethers.parseEther("35600")
      );

      expect(stake[0].budsAmount).to.be.equal(ethers.parseEther("10000"));

      expect(stake[0].farmerTokenId).to.be.equal(1);

      expect(stake[0].owner).to.be.equal(this.addr2);

      expect(stake2[0].budsAmount).to.be.equal(ethers.parseEther("25600"));

      expect(stake2[0].farmerTokenId).to.be.equal(2);

      expect(stake2[0].owner).to.be.equal(this.addr1);
    });
  });

  describe("Unstake tests", async function () {
    it("Should revert if non-existent stake index is passed", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const chainFacetadr1 = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.transfer(this.addr1, ethers.parseEther("25600"));

      await farmerContract.safeMint(this.addr2);

      await farmerContract.safeMint(this.addr1);

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      const budsadr2 = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr1
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      await budsadr2.approve(this.diamondAddress, ethers.parseEther("25600"));

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const farmerContractadr1 = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr1
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await farmerContractadr1.approve(this.diamondAddress, 2);

      await chainFacet.addStake(ethers.parseEther("10000"), 1);
      await chainFacetadr1.addStake(ethers.parseEther("25600"), 2);

      await time.increase(50 * 86000); // approx 50 days

      await expect(
        chainFacet.unStakeBuds(ethers.parseEther("10000"), 2)
      ).to.be.rejectedWith("");
    });

    it("Should revert when trying to unstake less than 1 bud", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const chainFacetadr1 = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.transfer(this.addr1, ethers.parseEther("25600"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      await farmerContract.safeMint(this.addr1);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      const budsadr2 = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr1
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      await budsadr2.approve(this.diamondAddress, ethers.parseEther("25600"));

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const farmerContractadr1 = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr1
      );

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await farmerContractadr1.approve(this.diamondAddress, 2);

      await chainFacet.addStake(ethers.parseEther("10000"), 1);
      await chainFacetadr1.addStake(ethers.parseEther("25600"), 2);

      await time.increase(50 * 86000); // approx 50 days

      await expect(
        chainFacet.unStakeBuds(ethers.parseEther("0.1"), 2)
      ).to.be.rejectedWith("InvalidData");
    });

    it("Should revert if tried to unstake more than staked amount", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const chainFacetadr1 = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.transfer(this.addr1, ethers.parseEther("25600"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      await farmerContract.safeMint(this.addr1);

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      const budsadr2 = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr1
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      await budsadr2.approve(this.diamondAddress, ethers.parseEther("25600"));

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const farmerContractadr1 = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr1
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);
      await farmerContractadr1.approve(this.diamondAddress, 2);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);
      await chainFacetadr1.addStake(ethers.parseEther("25600"), 2);

      await time.increase(50 * 86000); // approx 50 days

      await expect(
        chainFacet.unStakeBuds(ethers.parseEther("1001"), 0)
      ).to.be.rejectedWith("InsufficientStake");
    });

    it("Should remove stake record when whole stake is unstaked", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      await time.increase(50 * 86000); // approx 50 days


      await chainFacet.claimRewards(0);

      await chainFacet.unStakeFarmer(0);
      await chainFacet.unStakeBuds(ethers.parseEther("1000"), 0);

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );
      const userStake = await getterFacet.getUserStakes(this.addr2);

      expect(await userStake.length).to.be.equal(0);
    });

    it("Should not remove stake record when partial stake is unstaked", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await time.increase(50 * 86000); // approx 50 days

      await chainFacet.claimRewards(0);

      await chainFacet.unStakeBuds(ethers.parseEther("1000"), 0);

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );
      const userStake = await getterFacet.getUserStakes(this.addr2);

      expect(await userStake.length).to.be.equal(1);
      expect(await userStake[0].farmerTokenId).to.be.equal(1);
    });

    it("Should reflect state changes on unstake", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      await time.increase(50 * 86000); // approx 50 days
      await chainFacet.claimRewards(0);

      const localStakedBudsBefore = await getterFacet.getlocalStakedBuds();

      const globalStakedBudsBefore = await getterFacet.getGlobalStakedBuds();

      const totalStakedFamrersBefore =
        await getterFacet.getTotalStakedFarmers();

      await chainFacet.unStakeBuds(ethers.parseEther("1000"), 0);
      await chainFacet.unStakeFarmer(0);

      const localStakedBudsAfter = await getterFacet.getlocalStakedBuds();

      const globalStakedBudsAfter = await getterFacet.getGlobalStakedBuds();

      const totalStakedFamrersAfter = await getterFacet.getTotalStakedFarmers();

      const userStake = await getterFacet.getUserStakes(this.addr2);

      expect(await userStake.length).to.be.equal(0);
      expect(totalStakedFamrersBefore - totalStakedFamrersAfter).to.be.equal(1);
      expect(globalStakedBudsBefore - globalStakedBudsAfter).to.be.equal(
        ethers.parseEther("1000")
      );
      expect(localStakedBudsBefore - localStakedBudsAfter).to.be.equal(
        ethers.parseEther("1000")
      );
    });

    it("should revert if tried to unstake farmer but no farmer staked", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      await chainFacet.addStake(ethers.parseEther("1000"), 0);

      await time.increase(50 * 86000); // approx 50 days

      await chainFacet.claimRewards(0);

      await expect(chainFacet.unStakeFarmer(0)).to.be.rejectedWith(
        "InsufficientStake"
      );

      await chainFacet.unStakeBuds(ethers.parseEther("1000"), 0);
    });

    it("Should reflect state changes on partial unstake", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      await time.increase(50 * 86000); // approx 50 days
      await chainFacet.claimRewards(0);

      const localStakedBudsBefore = await getterFacet.getlocalStakedBuds();

      const globalStakedBudsBefore = await getterFacet.getGlobalStakedBuds();

      const totalStakedFamrersBefore =
        await getterFacet.getTotalStakedFarmers();

      await chainFacet.unStakeBuds(ethers.parseEther("500"), 0);

      const localStakedBudsAfter = await getterFacet.getlocalStakedBuds();

      const globalStakedBudsAfter = await getterFacet.getGlobalStakedBuds();

      const totalStakedFamrersAfter = await getterFacet.getTotalStakedFarmers();

      const userStake = await getterFacet.getUserStakes(this.addr2);

      expect(await userStake.length).to.be.equal(1);
      expect(totalStakedFamrersBefore - totalStakedFamrersAfter).to.be.equal(0);
      expect(globalStakedBudsBefore - globalStakedBudsAfter).to.be.equal(
        ethers.parseEther("500")
      );
      expect(localStakedBudsBefore - localStakedBudsAfter).to.be.equal(
        ethers.parseEther("500")
      );
    });
  });

  describe("Claim Test cases", async function () {
    it("Should not be able to claim if not staked", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      //await chainFacet.addStake(ethers.parseEther("1000"), 1);

      await time.increase(50 * 86000); // approx 50 days

      await expect(chainFacet.claimRewards(0)).to.be.rejectedWith(
        "NoStakeFound"
      );
    });
    it("Should update the stake timestamp", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      await time.increase(50 * 86400); //50 days

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      await chainFacet.claimRewards(0);

      const userStake = await getterFacet.getUserStakes(this.addr2);

      expect(userStake[0].timeStamp).to.be.equal(await time.latest());
    });

    it("Should give correct amount of reward as per APR", async function () {
      const chainFacet = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr2
      );

      const farmerContract = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.owner
      );

      const buds = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.owner
      );

      await buds.transfer(this.addr2, ethers.parseEther("10000"));

      await buds.approve(this.vaultAddress, ethers.parseEther("2000000"));

      await farmerContract.safeMint(this.addr2);

      const budsSpender = new Contract(
        this.budsAddress,
        SNBBuds__factory.abi,
        this.addr2
      );

      await budsSpender.approve(
        this.diamondAddress,
        ethers.parseEther("10000")
      );

      const farmerContractSpender = new Contract(
        this.farmerAddress,
        SNBFarmer__factory.abi,
        this.addr2
      );

      const getterFacet = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      await farmerContractSpender.approve(this.diamondAddress, 1);

      await chainFacet.addStake(ethers.parseEther("1000"), 1);

      const stakeTs = await time.latest();

      await time.increase(50 * 86400); //50 days

      const vaultInst = new Contract(
        this.vaultAddress,
        BudsVault__factory.abi,
        this.owner
      );

      await vaultInst.deposite(ethers.parseEther("2000000"));

      await vaultInst.whitelistContracts([this.diamondAddress]);

      const apr = await getterFacet.getCurrentApr();
      const utils = await ethers.getContractFactory("Utils");
      const Utils = await utils.deploy();
      const utilsAddress = await Utils.getAddress();

      const balanceBefore = await budsSpender.balanceOf(this.addr2);

      await chainFacet.claimRewards(0);

      const claimTs = await time.latest();

      const utilsInst = new Contract(
        utilsAddress,
        Utils__factory.abi,
        this.owner
      );

      const reward = await utilsInst.calculateStakingReward(
        ethers.parseEther("1000"),
        stakeTs,
        claimTs,
        apr
      );

      const balanceAfter = await budsSpender.balanceOf(this.addr2);

      expect(balanceAfter - balanceBefore).to.be.equal(reward);
    });
  });
});
