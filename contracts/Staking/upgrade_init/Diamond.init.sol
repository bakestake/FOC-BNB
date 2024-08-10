// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../lib/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { LibGlobalVarState } from "../lib/LidGlobalDataState.sol";
import { IBoosters } from "../../interfaces/IBooster.sol";
import { IBudsToken } from "../../interfaces/IBudsToken.sol";
import { IStBuds } from "../../interfaces/IStBuds.sol";
import { IChars } from "../../interfaces/IChars.sol";
import { IBudsVault } from "../../interfaces/IBudsVault.sol";
import { ISupraRouter } from "../../interfaces/ISupraRouter.sol";
import { OApp, MessagingFee, Origin } from "../../lzSupport/OAppUp.sol";
import {QueryResponse} from "../../wormholeSupport/QueryResponse.sol";
import {IAsset} from "../../interfaces/IAsset.sol";
import "wormhole-solidity-sdk/interfaces/IWormhole.sol";


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is QueryResponse {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(
        address[6] memory _tokenAddresses,
        address _wormhole,
        address budsVault,
        address supra,
        address _treasuryWallet,
        uint32 chainId
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibGlobalVarState.bytesStore().GetLocalSelector = bytes4(hex"4269e94c");

        LibGlobalVarState.intStore().baseAPR = 50;
        LibGlobalVarState.intStore().noOfChains = 6;
        LibGlobalVarState.intStore().raidFees = 5000000000000000;
        LibGlobalVarState.intStore().myChainID = chainId;

        LibGlobalVarState.addressStore().treasuryWallet = payable(_treasuryWallet);

        LibGlobalVarState.interfaceStore()._budsToken = IBudsToken(_tokenAddresses[0]);
        LibGlobalVarState.interfaceStore()._farmerToken = IAsset(_tokenAddresses[1]);
        LibGlobalVarState.interfaceStore()._narcToken = IAsset(_tokenAddresses[2]);
        LibGlobalVarState.interfaceStore()._stonerToken = IAsset(_tokenAddresses[3]);
        LibGlobalVarState.interfaceStore()._informantToken = IAsset(_tokenAddresses[4]);
        LibGlobalVarState.interfaceStore()._budsVault = IBudsVault(budsVault);
        LibGlobalVarState.interfaceStore()._supraRouter = ISupraRouter(supra);
        LibGlobalVarState.interfaceStore()._stBuds = IStBuds(_tokenAddresses[5]);

        LibGlobalVarState.mappingStore().tokenByTokenNumber[1] = LibGlobalVarState.interfaceStore()._stonerToken;
        LibGlobalVarState.mappingStore().tokenByTokenNumber[2] = LibGlobalVarState.interfaceStore()._informantToken;
        LibGlobalVarState.mappingStore().tokenByTokenNumber[3] = LibGlobalVarState.interfaceStore()._farmerToken;
        LibGlobalVarState.mappingStore().tokenByTokenNumber[4] = LibGlobalVarState.interfaceStore()._narcToken;


        wormhole = IWormhole(_wormhole);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}