// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";


library LzState {

    struct LZstate {
        bytes32 CROSS_CHAIN_RAID_MESSAGE;
        bytes32 CROSS_CHAIN_STAKE_MESSAGE;
        bytes32 CROSS_CHAIN_NFT_TRANSFER;
        bytes32 CROSS_CHAIN_BUDS_TRANSFER;

        ILayerZeroEndpointV2 endpoint;

        mapping(uint32 eid => bytes32 peer) peers;
    }

    bytes32 constant GLOBAL_LZ_STORAGE_POSITION = keccak256("diamond.standard.global.LzState.storage");

    function getStorage() internal pure returns (LZstate storage ds) {
        bytes32 position = GLOBAL_LZ_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

}