// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISupraRouter } from "../../interfaces/ISupraRouter.sol";
import "../lib/LibDiamond.sol";
import "../lib/LidGlobalDataState.sol";

contract RaidHandler {

    function sendRaidResult(uint256 _nonce, uint256[] memory _rngList) external {
        require(msg.sender == address(LibGlobalVarState.interfaceStore()._supraRouter));

        LibGlobalVarState.Raid memory latestRaid =LibGlobalVarState.arrayStore().raiderQueue[0];

        for (uint256 i = 0; i < LibGlobalVarState.arrayStore().raiderQueue.length - 1; i++) {
            LibGlobalVarState.arrayStore().raiderQueue[i] = LibGlobalVarState.arrayStore().raiderQueue[i + 1];
        }
        LibGlobalVarState.arrayStore().raiderQueue.pop();

        if (latestRaid.stakers == 0) {
            LibGlobalVarState.finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                latestRaid.riskLevel,
                LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        uint256 randomPercent = (_rngList[0] % 100) + 4;

        uint256 globalGSPC = (latestRaid.global / latestRaid.noOfChains) / latestRaid.stakers;
        uint256 localGSPC = latestRaid.local / latestRaid.stakers;

        bool raidSuccess;
        uint256 successThreshold = (localGSPC < globalGSPC) ? 10 : 8;

        raidSuccess = LibGlobalVarState.calculateRaidSuccess(
            randomPercent,
            successThreshold,
            latestRaid.riskLevel,
            latestRaid.raider,
            latestRaid.isBoosted
        );

        LibGlobalVarState.finalizeRaid(
            latestRaid.raider,
            raidSuccess,
            latestRaid.isBoosted,
            latestRaid.riskLevel,
            LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
        );

    }

}
