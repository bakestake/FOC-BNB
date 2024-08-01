// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Utils {
    function calculateStakingReward(uint256 budsAmount, uint256 timestamp, uint256 claimTs, uint256 apr) public pure returns(uint256 rewards){
        uint256 timeStaked = claimTs - timestamp;
        // apr have 2 decimal extra so we divide by 10000
        // this is annual 
        rewards = (budsAmount * apr)/10000;

        //now this is for staked period
        //reward/365 is reward per day
        //timestaked/1 days is number of days staked
        rewards = (rewards*timeStaked)/365 days;
    }
}