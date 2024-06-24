// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISupraRouter } from "../../interfaces/ISupraRouter.sol";
import "../lib/LibDiamond.sol";
import "../lib/LidGlobalDataState.sol";

contract RaidHandler {

    function sendRaidResult(uint256 _nonce, uint256[] memory _rngList) external {
        require(msg.sender == address(LibGlobalVarState.interfaceStore()._supraRouter));

        LibGlobalVarState.Raid memory latestRaid = LibGlobalVarState.Raid({
            raider: LibGlobalVarState.arrayStore().raiderQueue[0].raider,
            isBoosted: LibGlobalVarState.arrayStore().raiderQueue[0].isBoosted,
            stakers: LibGlobalVarState.arrayStore().raiderQueue[0].stakers,
            local: LibGlobalVarState.arrayStore().raiderQueue[0].local,
            global: LibGlobalVarState.arrayStore().raiderQueue[0].global,
            noOfChains: LibGlobalVarState.arrayStore().raiderQueue[0].noOfChains,
            isCustom: LibGlobalVarState.arrayStore().raiderQueue[0].isCustom,
            riskLevel: LibGlobalVarState.arrayStore().raiderQueue[0].riskLevel
        });

        for (uint256 i = 0; i < LibGlobalVarState.arrayStore().raiderQueue.length - 1; i++) {
            LibGlobalVarState.arrayStore().raiderQueue[i] = LibGlobalVarState.arrayStore().raiderQueue[i + 1];
        }
        LibGlobalVarState.arrayStore().raiderQueue.pop();

        if (latestRaid.stakers == 0) {
            LibGlobalVarState.finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                latestRaid.isCustom,
                latestRaid.riskLevel,
                LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
            );
        }

        uint256 randomPercent = (_rngList[0] % 100) + 4;

        uint256 globalGSPC = (latestRaid.global / latestRaid.noOfChains) / latestRaid.stakers;
        uint256 localGSPC = latestRaid.local / latestRaid.stakers;

        if (localGSPC < globalGSPC) {
            if (calculateRaidSuccess(randomPercent, 4, latestRaid.riskLevel, latestRaid.raider, latestRaid.isBoosted, latestRaid.isCustom)) {
                LibGlobalVarState.finalizeRaid(
                    latestRaid.raider,
                    true,
                    latestRaid.isBoosted,
                    latestRaid.isCustom,
                    latestRaid.riskLevel,
                    LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
                );
                return;
            }
            LibGlobalVarState.finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                latestRaid.isCustom,
                latestRaid.riskLevel,
                LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        if (calculateRaidSuccess(randomPercent, 4, latestRaid.riskLevel, latestRaid.raider, latestRaid.isBoosted, latestRaid.isCustom)) {
            LibGlobalVarState.finalizeRaid(
                latestRaid.raider,
                true,
                latestRaid.isBoosted,
                latestRaid.isCustom,
                latestRaid.riskLevel,
                LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        LibGlobalVarState.finalizeRaid(
            latestRaid.raider,
            false,
            latestRaid.isBoosted,
            latestRaid.isCustom,
            latestRaid.riskLevel,
            LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
        );
        return;
    }

    function calculateRaidSuccess(
        uint256 randomPercent,
        uint256 factor,
        uint256 riskLevel,
        address raider,
        bool isBoosted,
        bool isCustom
    ) internal view returns (bool) {
        if (isBoosted) {
            if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 4) {
                factor = 3;
            } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 3) {
                factor = 2;
            } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 2) {
                factor = 1;
            } else {
                factor = 1;
            }
            if (randomPercent % factor == 0) {
                return true;
            }
        } else if (randomPercent % factor == 0) {
            return true;
        }
        return false;
    }
}
