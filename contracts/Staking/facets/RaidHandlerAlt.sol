// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IEntropyConsumer } from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import "../lib/LibDiamond.sol";
import "../lib/LidGlobalDataState.sol";

contract RaidHandlerAlt is IEntropyConsumer {

    function getEntropy() internal view override returns (address) {
        return address(LibGlobalVarState.interfaceStore().entropy);
    }

    function entropyCallback(
        uint64 sequenceNumber,
        // If your app uses multiple providers, you can use this argument to
        // distinguish which one is calling the app back.
        address provider,
        bytes32 randomNumber
    ) internal override {
        require(msg.sender == address(LibGlobalVarState.interfaceStore()._supraRouter));

        LibGlobalVarState.Raid memory latestRaid =LibGlobalVarState.arrayStore().raiderQueue[0];

        for (uint256 i = 0; i < LibGlobalVarState.arrayStore().raiderQueue.length - 1; i++) {
            LibGlobalVarState.arrayStore().raiderQueue[i] = LibGlobalVarState.arrayStore().raiderQueue[i + 1];
        }
        LibGlobalVarState.arrayStore().raiderQueue.pop();

        if (latestRaid.stakers == 0) {
            finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                latestRaid.riskLevel,
                LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        uint256 randomPercent = (uint(randomNumber) % 100) + 4;

        uint256 globalGSPC = (latestRaid.global / latestRaid.noOfChains) / latestRaid.stakers;
        uint256 localGSPC = latestRaid.local / latestRaid.stakers;

        bool raidSuccess;
        uint256 successThreshold = (localGSPC < globalGSPC) ? 10 : 8;

        raidSuccess = calculateRaidSuccess(
            randomPercent,
            successThreshold,
            latestRaid.riskLevel,
            latestRaid.raider,
            latestRaid.isBoosted
        );

        finalizeRaid(
            latestRaid.raider,
            raidSuccess,
            latestRaid.isBoosted,
            latestRaid.riskLevel,
            LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
        );

    }

    function calculateRaidSuccess(
        uint256 randomPercent,
        uint256 factor,
        uint256 riskLevel,
        address raider,
        bool isBoosted
    ) internal view returns (bool) {

        if (isBoosted) {
            if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 4) {
                factor -= 1;
            } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 3) {
                factor -= 2;
            } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 2) {
                factor -= 3;
            } else {
                factor -= 4;
            }
        }
        
        if(riskLevel == 3){
            factor += 1;
        }

        if(riskLevel == 1){
            factor -= 1;
        }

        if (randomPercent % factor == 0) {
            return true;
        }
        
        return false;
    }

    function raidPool(uint256 tokenId,address _raider) internal {
        if (tokenId != 0) {
            for (uint256 i = 0; i < LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length; i++) {
                if (block.timestamp - LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] > 7 days) {
                    LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] = LibGlobalVarState.mappingStore().lastRaidBoost[_raider][LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length - 1];
                    LibGlobalVarState.mappingStore().lastRaidBoost[_raider].pop();
                }
            }
            if (LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
            LibGlobalVarState.mappingStore().lastRaidBoost[_raider].push(block.timestamp);
        }
        LibGlobalVarState.arrayStore().raiderQueue.push(
            LibGlobalVarState.Raid({
                raider: _raider,
                isBoosted: tokenId != 0,
                stakers: LibGlobalVarState.arrayStore().stakerAddresses.length,
                local: LibGlobalVarState.intStore().localStakedBudsCount,
                global: LibGlobalVarState.intStore().globalStakedBudsCount,
                noOfChains: LibGlobalVarState.intStore().noOfChains,
                riskLevel: 0
            })
        );

        address provider = LibGlobalVarState.interfaceStore().entropy.getDefaultProvider();

        uint fee = LibGlobalVarState.interfaceStore().entropy.getFee(provider);
        uint64 sequenceNumber = LibGlobalVarState.interfaceStore().entropy.requestWithCallback{value: fee}(provider, keccak256(""));
    }

    function raidPoolCustom(uint256 tokenId, address _raider, uint256 riskLevel) internal {
        if(!LibGlobalVarState.boolStore().isContestOpen) revert LibGlobalVarState.ContestNotOpen();
        if(riskLevel > 3 || riskLevel < 1) revert LibGlobalVarState.InvalidRiskLevel();
        if (tokenId != 0) {
            for (uint256 i = 0; i < LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length; i++) {
                if (block.timestamp - LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] > 7 days) {
                    LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] = LibGlobalVarState.mappingStore().lastRaidBoost[_raider][LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length - 1];
                    LibGlobalVarState.mappingStore().lastRaidBoost[_raider].pop();
                }
            }
            if (LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
            LibGlobalVarState.mappingStore().lastRaidBoost[_raider].push(block.timestamp);
        }
        LibGlobalVarState.arrayStore().raiderQueue.push(
            LibGlobalVarState.Raid({
                raider: _raider,
                isBoosted: tokenId != 0,
                stakers: LibGlobalVarState.arrayStore().stakerAddresses.length,
                local: LibGlobalVarState.intStore().localStakedBudsCount,
                global: LibGlobalVarState.intStore().globalStakedBudsCount,
                noOfChains: LibGlobalVarState.intStore().noOfChains,
                riskLevel: riskLevel
            })
        );
        address provider = LibGlobalVarState.interfaceStore().entropy.getDefaultProvider();

        uint fee = LibGlobalVarState.interfaceStore().entropy.getFee(provider);
        uint64 sequenceNumber = LibGlobalVarState.interfaceStore().entropy.requestWithCallback{value: fee}(provider, keccak256(""));
    }

    function finalizeRaid(address raider, bool isSuccess, bool isboosted, uint256 raidLevel, uint256 _boosts) internal{
        if(isSuccess){
            uint256 payout = distributeRaidingRewards(raider,LibGlobalVarState.interfaceStore()._budsToken.balanceOf(address(this)));
            if(raidLevel == 3){
                payout += (payout*(raidLevel+1))/100;
            }
            if(raidLevel == 1){
                payout -= (payout*(raidLevel+1))/100;
            }
            LibGlobalVarState.intStore().budsLostToRaids += payout;
            emit LibGlobalVarState.Raided(raider,true,isboosted, payout, _boosts);
            return;
        }
        emit LibGlobalVarState.Raided(raider,false,isboosted, 0, _boosts);
    }

    function distributeRaidingRewards(address to, uint256 rewardAmount) internal returns (uint256 rewardPayout) {
        LibGlobalVarState.interfaceStore()._budsToken.burnFrom(address(this), rewardAmount / 100);
        rewardPayout = rewardAmount - (rewardAmount / 100);
        bool res = LibGlobalVarState.interfaceStore()._budsToken.transfer(to, rewardPayout);
        require(res);
        return rewardPayout;
    }

}