// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/LibDiamond.sol";
import "../lib/LidGlobalDataState.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";

/// TODO - add more setters
contract GetterSetterFacet {
    function setRaidFees(uint256 _raidFees) external {
        LibGlobalVarState.intStore().raidFees = _raidFees;
    }

    function getlocalStakedBuds() public view returns (uint256) {
        return LibGlobalVarState.intStore().localStakedBudsCount;
    }

    function getCurrentApr() public view returns(uint256){
        return LibGlobalVarState.getCurrentApr();
    }

    function getUserStakes(address user) public view returns(LibGlobalVarState.Stake[] memory){
        uint256 len = LibGlobalVarState.mappingStore().stakeRecord[user].length;
        LibGlobalVarState.Stake[] memory stakes = new LibGlobalVarState.Stake[](len);  

        for (uint256 i = 0; i < len; i++) {
            stakes[i] = LibGlobalVarState.mappingStore().stakeRecord[user][i];
        }

        return stakes;
    }

    function getGlobalStakedBuds() public view returns (uint256) {
        return LibGlobalVarState.intStore().globalStakedBudsCount;
    }

    function setGlobalStakedBuds(uint256 liquidity) public {
        LibGlobalVarState.intStore().globalStakedBudsCount = liquidity;
    }

    function getTotalStakedFarmers() public view returns (uint256) {
        return LibGlobalVarState.intStore().totalStakedFarmers;
    }

    function getNumberOfStakers() public view returns (uint256) {
        return LibGlobalVarState.intStore().numberOfStakers;
    }

    function getNoOfChains() external view returns(uint256){
        return LibGlobalVarState.intStore().noOfChains;
    }

    function getBudsLostToRaids() external view returns(uint256){
        return LibGlobalVarState.intStore().budsLostToRaids;
    }

    function getRewardsForUser(address user) external view returns(uint256 rewards){
        LibGlobalVarState.Stake[] memory stake = getUserStakes(user);
        uint256 stakedAmount = 0;
        
        for(uint i = 0; i < stake.length; i++){
            LibGlobalVarState.Stake memory curStake = stake[i];
            stakedAmount += curStake.budsAmount;
        }

        rewards = stakedAmount * getCurrentApr();
    }

    function setNoOfChains(uint256 chains) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.intStore().noOfChains = chains;
    }

    function setRaidHandler(address _address) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.interfaceStore()._raidHandler = IRaidHandler(_address);
    }

    function setTreasury(address payable newAddress) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.addressStore().treasuryWallet = newAddress;
    }

    function transferOwner(address newOwner) external{
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibDiamond.setContractOwner(newOwner);
    } 

    function startContest() external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.boolStore().isContestOpen = true;
    }

    function closeContest() external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.boolStore().isContestOpen = false;
    }

    function withdrawEth() external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        payable(LibDiamond.contractOwner()).transfer(address(this).balance);
    }

}