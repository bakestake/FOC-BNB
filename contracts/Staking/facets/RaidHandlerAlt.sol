// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
// import "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
// import "../lib/LibDiamond.sol";
// import "../lib/LidGlobalDataState.sol";

// contract RaidHandlerAlt {

//     function raidPool(
//         uint256 tokenId,
//         address _raider,
//         uint256 noOfStakers,
//         uint256 localBuds,
//         uint256 globalBuds,
//         uint256 _noOfChains
//     ) external {
//         if (tokenId != 0) {
//             for (uint256 i = 0; i < LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length; i++) {
//                 if (block.timestamp - LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] > 7 days) {
//                     LibGlobalVarState.mappingStore().lastRaidBoost[_raider][i] = LibGlobalVarState.mappingStore().lastRaidBoost[_raider][LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length - 1];
//                     LibGlobalVarState.mappingStore().lastRaidBoost[_raider].pop();
//                 }
//             }
//             if (LibGlobalVarState.mappingStore().lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
//             LibGlobalVarState.mappingStore().lastRaidBoost[_raider].push(block.timestamp);
//         }
//         LibGlobalVarState.arrayStore().raiderQueue.push(
//             LibGlobalVarState.Raid({
//                 raider: _raider,
//                 isBoosted: tokenId != 0,
//                 stakers: noOfStakers,
//                 local: localBuds,
//                 global: globalBuds,
//                 noOfChains: _noOfChains
//             })
//         );
//         uint256 nonce = LibGlobalVarState.interfaceStore()._supraRouter.generateRequest(
//             "sendRaidResult(uint256,uint256[])",
//             1,
//             1,
//             0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
//         );
//     }

//     function sendRaidResult(uint256 _nonce, uint256[] memory _rngList) external {
//         require(msg.sender == address(LibGlobalVarState.interfaceStore()._supraRouter));

//         LibGlobalVarState.Raid memory latestRaid = LibGlobalVarState.Raid({
//             raider: LibGlobalVarState.arrayStore().raiderQueue[0].raider,
//             isBoosted: LibGlobalVarState.arrayStore().raiderQueue[0].isBoosted,
//             stakers: LibGlobalVarState.arrayStore().raiderQueue[0].stakers,
//             local: LibGlobalVarState.arrayStore().raiderQueue[0].local,
//             global: LibGlobalVarState.arrayStore().raiderQueue[0].global,
//             noOfChains: LibGlobalVarState.arrayStore().raiderQueue[0].noOfChains
//         });

//         for (uint256 i = 0; i < LibGlobalVarState.arrayStore().raiderQueue.length - 1; i++) {
//             LibGlobalVarState.arrayStore().raiderQueue[i] = LibGlobalVarState.arrayStore().raiderQueue[i + 1];
//         }
//         LibGlobalVarState.arrayStore().raiderQueue.pop();

//         if (latestRaid.stakers == 0) {
//             LibGlobalVarState.interfaceStore()._stakingContract.finalizeRaid(
//                 latestRaid.raider,
//                 false,
//                 latestRaid.isBoosted,
//                 LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
//             );
//         }

//         uint256 randomPercent = (_rngList[0] % 100) + 4;

//         uint256 globalGSPC = (latestRaid.global / latestRaid.noOfChains) / latestRaid.stakers;
//         uint256 localGSPC = latestRaid.local / latestRaid.stakers;

//         if (localGSPC < globalGSPC) {
//             if (calculateRaidSuccess(randomPercent, 4, latestRaid.raider, latestRaid.isBoosted)) {
//                 LibGlobalVarState.interfaceStore()._stakingContract.finalizeRaid(
//                     latestRaid.raider,
//                     true,
//                     latestRaid.isBoosted,
//                     LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
//                 );
//                 return;
//             }
//             LibGlobalVarState.interfaceStore()._stakingContract.finalizeRaid(
//                 latestRaid.raider,
//                 false,
//                 latestRaid.isBoosted,
//                 LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
//             );
//             return;
//         }

//         if (calculateRaidSuccess(randomPercent, 3, latestRaid.raider, latestRaid.isBoosted)) {
//             LibGlobalVarState.interfaceStore()._stakingContract.finalizeRaid(
//                 latestRaid.raider,
//                 true,
//                 latestRaid.isBoosted,
//                 LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
//             );
//             return;
//         }

//         LibGlobalVarState.interfaceStore()._stakingContract.finalizeRaid(
//             latestRaid.raider,
//             false,
//             latestRaid.isBoosted,
//             LibGlobalVarState.mappingStore().lastRaidBoost[latestRaid.raider].length
//         );
//         return;
//     }

//     function calculateRaidSuccess(
//         uint256 randomPercent,
//         uint256 factor,
//         address raider,
//         bool isBoosted
//     ) internal view returns (bool) {
//         if (isBoosted) {
//             if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 4) {
//                 factor = 3;
//             } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 3) {
//                 factor = 2;
//             } else if (LibGlobalVarState.mappingStore().lastRaidBoost[raider].length == 2) {
//                 factor = 1;
//             } else {
//                 factor = 1;
//             }
//             if (randomPercent % factor == 0) {
//                 return true;
//             }
//         } else if (randomPercent % factor == 0) {
//             return true;
//         }
//         return false;
//     }
// }
