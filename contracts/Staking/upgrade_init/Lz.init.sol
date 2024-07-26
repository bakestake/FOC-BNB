// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OApp, MessagingFee, Origin } from "../../lzSupport/OAppUp.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import {LzState} from "../lib/Lz.sol";

contract LzInit is OApp {

    function init(address lzEndpoint) external {
        LzState.getStorage().CROSS_CHAIN_RAID_MESSAGE = bytes32("CROSS_CHAIN_RAID_MESSAGE");
        LzState.getStorage().CROSS_CHAIN_STAKE_MESSAGE = bytes32("CROSS_CHAIN_STAKE_MESSAGE");
        LzState.getStorage().CROSS_CHAIN_NFT_TRANSFER = bytes32("CROSS_CHAIN_NFT_TRANSFER");
        LzState.getStorage().CROSS_CHAIN_BUDS_TRANSFER = bytes32("CROSS_CHAIN_BUDS_TRANSFER");

        __OApp_Init(lzEndpoint, msg.sender);
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {}

    function endpoint() external view override returns (ILayerZeroEndpointV2 iEndpoint) {}

    function peers(uint32 _eid) external view override returns (bytes32 peer) {}
}