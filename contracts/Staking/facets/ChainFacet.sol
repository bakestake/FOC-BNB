// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";
import {IStaking} from "../../interfaces/IStaking.sol";

import "../lib/LidGlobalDataState.sol";

contract ChainFacet is IERC721Receiver {

    function addStake(uint256 _budsAmount, uint256 _farmerTokenId) public {
        if (_farmerTokenId != 0 && LibGlobalVarState.interfaceStore()._farmerToken.ownerOf(_farmerTokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();
        if(_budsAmount < 1 ether && _farmerTokenId == 0) revert LibGlobalVarState.InvalidData();
        if(_farmerTokenId != 0 && LibGlobalVarState.mappingStore().stakedFarmer[msg.sender] != 0) revert LibGlobalVarState.FarmerStakedAlready();

        LibGlobalVarState.Stake memory stk = LibGlobalVarState.Stake({
            owner: msg.sender,
            timeStamp: block.timestamp,
            budsAmount:_budsAmount
        });
        LibGlobalVarState.intStore().localStakedBudsCount += _budsAmount;
        LibGlobalVarState.intStore().globalStakedBudsCount += _budsAmount;
        if(LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length == 0){
            LibGlobalVarState.intStore().numberOfStakers += 1;
        }
        LibGlobalVarState.mappingStore().stakeRecord[msg.sender].push(stk);

        if(_farmerTokenId != 0){
            LibGlobalVarState.intStore().totalStakedFarmers+=1;
            LibGlobalVarState.mappingStore().stakedFarmer[msg.sender] = _farmerTokenId;
            LibGlobalVarState.interfaceStore()._farmerToken.safeTransferFrom(msg.sender,address(this),_farmerTokenId);  
        }

        if(_budsAmount != 0){
            bool res = LibGlobalVarState.interfaceStore()._budsToken.transferFrom(msg.sender, address(this), _budsAmount);
            require(res);
        } 
        emit LibGlobalVarState.Staked(msg.sender, _farmerTokenId, _budsAmount, block.timestamp, LibGlobalVarState.intStore().localStakedBudsCount, LibGlobalVarState.getCurrentApr()
); 
    }

    function boostStake(uint256 tokenId, uint256 stakeIndex) external {
        if (LibGlobalVarState.interfaceStore()._stonerToken.ownerOf(tokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();
        LibGlobalVarState.Stake memory stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
        if (stk.owner == address(0)) revert LibGlobalVarState.NoStakeFound();

        ///max len of this will be 4
        for (uint8 i = 0; i < LibGlobalVarState.mappingStore().boosts[msg.sender].length; ) {
            if (LibGlobalVarState.mappingStore().boosts[msg.sender][i] > block.timestamp) {
                LibGlobalVarState.mappingStore().boosts[msg.sender][i] = LibGlobalVarState.mappingStore().boosts[msg.sender][LibGlobalVarState.mappingStore().boosts[msg.sender].length - 1];
                LibGlobalVarState.mappingStore().boosts[msg.sender].pop();
            }
            i++;
        }
        // boost rewards
        uint256 len = LibGlobalVarState.mappingStore().boosts[msg.sender].length;
        uint apr =  LibGlobalVarState.getCurrentApr();
        uint rewardAsPerApr = (stk.budsAmount * apr * 7);
        if (len < 4) {
            LibGlobalVarState.mappingStore().boosts[msg.sender].push(block.timestamp + 7 days);
            uint256 amountBoosted = len == 1
                ? ((rewardAsPerApr * 5) / 365 * 10e5)
                : len == 2
                    ? ((rewardAsPerApr *4)/ 365 * 10e5) 
                    : len == 3
                        ? ((rewardAsPerApr*2 )/ 365 * 10e5) 
                        : (rewardAsPerApr / 365 * 10e5);

            stk.budsAmount += amountBoosted;
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex] = stk;
            LibGlobalVarState.interfaceStore()._stonerToken.burnFrom(tokenId);
        } else {
            revert LibGlobalVarState.MaxBoostReached();
        }
    }

    function claimRewards() public {
        uint256 len = LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length;
        if (len == 0) revert LibGlobalVarState.NoStakeFound();

        uint256 rewards = 0;
        for(uint i = 0; i < len; i++){
            LibGlobalVarState.Stake storage stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][i];
            rewards += calculateStakingReward(stk.budsAmount, stk.timeStamp);
            stk.timeStamp = block.timestamp;
        }

        if(LibGlobalVarState.mappingStore().stakedFarmer[msg.sender] != 0){
            rewards += (rewards/100);
        }

        LibGlobalVarState.interfaceStore()._budsVault.sendBudsTo(msg.sender, rewards);
    }

    function unStakeBuds(uint256 _budsAmount) public {
        if(_budsAmount < 1 ether) revert LibGlobalVarState.InvalidData();
        if (block.timestamp - LibGlobalVarState.mappingStore().stakeRecord[msg.sender][0].timeStamp > 1 days) revert ("Claim first");
        
        uint256 len = LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length;
        if (len == 0) revert LibGlobalVarState.NoStakeFound();

        uint256 staked = 0;
        for(uint i = 0; i < len; i++){
            LibGlobalVarState.Stake memory stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][i];
            staked += stk.budsAmount;
            stk.timeStamp = block.timestamp;
        }

        delete LibGlobalVarState.mappingStore().stakeRecord[msg.sender];

        if(_budsAmount > staked) revert LibGlobalVarState.InsufficientStake();

        if(_budsAmount < staked){
            LibGlobalVarState.Stake memory stk = LibGlobalVarState.Stake({
                owner: msg.sender,
                timeStamp: block.timestamp,
                budsAmount: staked - _budsAmount
            });
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender].push(stk);
        }
        
        LibGlobalVarState.intStore().localStakedBudsCount -= _budsAmount;
        LibGlobalVarState.intStore().globalStakedBudsCount -= _budsAmount;

        bool res = LibGlobalVarState.interfaceStore()._budsToken.transfer(msg.sender, _budsAmount);
        require(res);

        emit LibGlobalVarState.UnStaked(
            msg.sender,
            0,
            _budsAmount,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

    function claimAndUnstake() public {
        uint256 len = LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length;
        if (len == 0) revert LibGlobalVarState.NoStakeFound();

        uint256 rewards = 0;
        uint256 staked = 0;
        uint256 tokenIdToSend = LibGlobalVarState.mappingStore().stakedFarmer[msg.sender];

        for(uint i = 0; i < len; i++){
            LibGlobalVarState.Stake memory stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][i];
            rewards += calculateStakingReward(stk.budsAmount, stk.timeStamp);
            staked += stk.budsAmount;
            stk.timeStamp = block.timestamp;
        }

        LibGlobalVarState.intStore().localStakedBudsCount -= staked;
        LibGlobalVarState.intStore().globalStakedBudsCount -= staked;

        delete LibGlobalVarState.mappingStore().stakeRecord[msg.sender];

        if(tokenIdToSend != 0){
            LibGlobalVarState.mappingStore().stakedFarmer[msg.sender] = 0;
            LibGlobalVarState.interfaceStore()._farmerToken.safeTransferFrom(address(this), msg.sender, tokenIdToSend);
        }

        bool res = LibGlobalVarState.interfaceStore()._budsToken.transfer(msg.sender, staked);
        require(res);

        LibGlobalVarState.interfaceStore()._budsVault.sendBudsTo(msg.sender, rewards);

        emit LibGlobalVarState.UnStaked(
            msg.sender,
            tokenIdToSend,
            staked,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

    function unStakeFarmer() public {
        if (LibGlobalVarState.mappingStore().stakedFarmer[msg.sender] == 0) revert LibGlobalVarState.InsufficientStake();
        uint256 tokenIdToSend = LibGlobalVarState.mappingStore().stakedFarmer[msg.sender];

        delete LibGlobalVarState.mappingStore().stakedFarmer[msg.sender];
        LibGlobalVarState.intStore().totalStakedFarmers -= 1;
        LibGlobalVarState.interfaceStore()._farmerToken.safeTransferFrom(address(this), msg.sender, tokenIdToSend);

        emit LibGlobalVarState.UnStaked(
            msg.sender,
            tokenIdToSend,
            0,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

    function raid(uint256 tokenId) external payable {
        if (LibGlobalVarState.interfaceStore()._narcToken.balanceOf(msg.sender) == 0) revert LibGlobalVarState.NotANarc();
        if (msg.value < LibGlobalVarState.intStore().raidFees) revert LibGlobalVarState.InsufficientRaidFees();
        
        if (tokenId != 0) {
            require(LibGlobalVarState.interfaceStore()._informantToken.ownerOf(tokenId) == msg.sender);
            LibGlobalVarState.interfaceStore()._informantToken.burnFrom(tokenId);
        }
        
        LibGlobalVarState.addressStore().treasuryWallet.transfer(msg.value);
        LibGlobalVarState.raidPool(
            tokenId,
            msg.sender
        );
    }

    function raidCustom(uint256 riskLevel, uint256 tokenId) external payable {
        if (LibGlobalVarState.interfaceStore()._narcToken.balanceOf(msg.sender) == 0) revert LibGlobalVarState.NotANarc();
        
        if (tokenId != 0) {
            require(LibGlobalVarState.interfaceStore()._informantToken.ownerOf(tokenId) == msg.sender);
            LibGlobalVarState.interfaceStore()._informantToken.burnFrom(tokenId);
        }
        LibGlobalVarState.addressStore().treasuryWallet.transfer(msg.value);

        LibGlobalVarState.raidPoolCustom(
            tokenId,
            msg.sender,
            riskLevel
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function calculateStakingReward(uint256 budsAmount, uint256 timestamp) internal view returns(uint256 rewards){
        uint256 timeStaked = block.timestamp - timestamp;
        // apr have 2 decimal extra so we divide by 10000
        // this is annual 
        rewards = (budsAmount * LibGlobalVarState.getCurrentApr())/10000;

        //now this is for staked period
        //reward/365 is reward per day
        //timestaked/1 days is number of days staked
        rewards = (rewards*timeStaked)/365 days;
    }

}