import {AddressLike, Contract} from "ethers";
import {getConstants} from "../../scripts/libraries/getConstants";
import {deployFixture} from "./raiding.fixtures";
import {
  ChainFacet__factory,
  DiamondCutFacet__factory,
  GetterSetterFacet__factory,
  RaidHandler__factory,
  SNBNarc__factory,
} from "../../types";
import {expect} from "chai";
import {ethers} from "hardhat";
import {getSelector} from "../../scripts/selectors";
import {FacetCutAction} from "../../scripts/getFacetCutAction";

describe("Raiding test cases", async function () {
  describe("Raid Test cases", async function () {
    beforeEach(async function () {
      let constants = await getConstants("amoy");
      console.log(constants?.supraRouter)
      const {
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
      } = await deployFixture(constants?.supraRouter, 1, 1);
      
      this.owner = owner;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      this.addr4 = addr4;
      this.xpAddress = xpAddress;
      this.vaultAddress = vaultAddress;
      this.budsAddress = budsAddress;
      this.farmerAddress = farmerAddress;
      this.narcAddress = narcAddress;
      this.informantAddress = informantAddress;
      this.stonerAddress = stonerAddress;

      const diamondCut = await ethers.getContractFactory("DiamondCutFacet");
      const diamondCutInst = await diamondCut.deploy();
      const diamondCutAddress = await diamondCutInst.getAddress();

      const diamond = await ethers.getContractFactory("StakingDiamond");
      const diamondInst = await diamond.deploy(owner, diamondCutAddress);
      const diamondAddress = await diamondInst.getAddress();

      this.diamondAddress = diamondAddress;

      const loupeSelectors = getSelector("DiamondLoupeFacet");
      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");
      const LoupeDeploy = await loupeContract.deploy();
      const loupeAddress = await LoupeDeploy.getAddress();

      const diamondCutContract = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );

      const chainFacet = await ethers.getContractFactory("ChainFacet");
      const chainfacet = await chainFacet.deploy();
      const chainFacetAddress = await chainfacet.getAddress();

      const InitFacet = await ethers.getContractFactory("DiamondInit");
      const InitDeploy = await InitFacet.deploy();
      const initAddress = await InitDeploy.getAddress();

      const getterSetter = await ethers.getContractFactory("GetterSetterFacet");
      const GetterSetter = await getterSetter.deploy();
      const getterSetterAddress = await GetterSetter.getAddress();

      const gsSelectors = getSelector("GetterSetterFacet");
      const chainSelectors = getSelector("ChainFacet");
      const raidSelector = getSelector("RaidHandler");

      const raidhandler = await ethers.getContractFactory("RaidHandler");
      const raidHandler = await raidhandler.deploy();
      const raidHandlerAddress = await raidHandler.getAddress();

      this.raidHandlerAddress = raidHandlerAddress;

      let params = [];
      const tokenAddresses: AddressLike[] = [
        budsAddress as AddressLike,
        farmerAddress as AddressLike,
        narcAddress as AddressLike,
        stonerAddress as AddressLike,
        informantAddress as AddressLike,
      ];
      params.push(tokenAddresses);
      params.push(vaultAddress as AddressLike);
      params.push(constants?.supraRouter as AddressLike);
      params.push(owner.address as AddressLike);
      params.push(80002);

      let functionCall = InitDeploy.interface.encodeFunctionData(
        "init",
        params
      );

      await diamondCutContract.diamondCut(
        [
          {
            facetAddress: loupeAddress,
            action: FacetCutAction.Add,
            functionSelectors: loupeSelectors,
          },
          {
            facetAddress: getterSetterAddress,
            action: FacetCutAction.Add,
            functionSelectors: gsSelectors,
          },
          {
            facetAddress: chainFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: chainSelectors,
          },
          {
            facetAddress: raidHandlerAddress,
            action: FacetCutAction.Add,
            functionSelectors: raidSelector,
          },
        ],
        initAddress,
        functionCall
      );

      const provider =  new ethers.JsonRpcProvider(process.env.RPC_URL_AMOY)

      const supraDepositeInst = await ethers.getContractAt(
        "ISupraDeposite", 
        constants.supraDeposite, 
        new ethers.Wallet(process.env.SUPRA_PRIVATE_KEY || "",provider)
      );


      //await supraDepositeInst.depositFundClient({value:ethers.parseEther("0.05")})


      const tx = await supraDepositeInst.addContractToWhitelist(diamondAddress);


    });

    it("Should revert if sender does not owns a narc", async function () {
      const chainFacetInst = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      await expect(
        chainFacetInst.raid(0, {value: ethers.parseEther("0.5")})
      ).to.be.rejectedWith("NotANarc");
    });

    it("Should revert if less raid fees is given", async function () {
      const chainFacetInst = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const narcInst = new Contract(
        this.narcAddress,
        SNBNarc__factory.abi,
        this.owner
      );

      await narcInst.safeMint(this.addr1);

      await expect(
        chainFacetInst.raid(0, {value: ethers.parseEther("0.0001")})
      ).to.be.rejectedWith("InsufficientRaidFees");
    });

    it("Should make a call to raid handler", async function () {
      const chainFacetInst = new Contract(
        this.diamondAddress,
        ChainFacet__factory.abi,
        this.addr1
      );

      const narcInst = new Contract(
        this.narcAddress,
        SNBNarc__factory.abi,
        this.owner
      );

      const getterSetterInst = new Contract(
        this.diamondAddress,
        GetterSetterFacet__factory.abi,
        this.owner
      );

      await getterSetterInst.setRaidHandler(this.diamondAddress);

      await narcInst.safeMint(this.addr1);

      const reqData = await chainFacetInst.raid(0, {
        value: ethers.parseEther("0.5"),
      });

    });
    // it("Should revert if boosted by non owned informant token", async function () {});
    // it("Shuold be able to boost raid using informant token", async function () {});
    // it("Should revert if more than 4 boosts used in a week", async function () {});
    // it("Should be able to use 4 boosts in a week", async function () {});
  });
});
