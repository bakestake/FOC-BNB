// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBudsToken} from "../../interfaces/IBudsToken.sol";
import {IChars} from "../../interfaces/IChars.sol";
import {IBoosters} from "../../interfaces/IBooster.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";
import {ISupraRouter} from "../../interfaces/ISupraRouter.sol";
import {IBudsVault} from "../../interfaces/IBudsVault.sol";

interface IStaking {
    function finalizeRaid(address raider, bool isSuccess, bool isboosted, uint256 boosts) external;
}

library LibGlobalVarState {
    error ZeroAddress();
    error InvalidData();
    error NotOwnerOfAsset();
    error FarmerStakedAlready();
    error NoStakeFound();
    error MaxBoostReached();
    error InsufficientStake();
    error InsufficientRaidFees();
    error InsufficientFees();
    error NotANarc();
    error InvalidForeignChainID();
    error UnexpectedResultLength();
    error UnexpectedResultMismatch();
    error ContestNotOpen();
    error InvalidRiskLevel();

    event crossChainStakeFailed(bytes32 indexed messageId, bytes reason);
    event recoveredFailedStake(bytes32 indexed messageId);
    event Staked(
        address indexed owner,
        uint256 tokenId,
        uint256 budsAmount,
        uint256 timeStamp,
        uint256 localStakedBudsCount,
        uint256 latestAPR
    );
    event UnStaked(
        address owner,
        uint256 tokenId,
        uint256 budsAmount,
        uint256 timeStamp,
        uint256 localStakedBudsCount,
        uint256 latestAPR
    );
    event RewardsCalculated(uint256 timeStamp, uint256 rewardsDisbursed);
    event Raided(
        address indexed raider,
        bool isSuccess,
        bool isBoosted,
        uint256 rewardTaken,
        uint256 boostsUsedInLastSevenDays
    );

    bytes32 constant GLOBAL_INT_STORAGE_POSITION = keccak256("diamond.standard.global.integer.storage");
    bytes32 constant GLOBAL_ADDRESS_STORAGE_POSITION = keccak256("diamond.standard.global.address.storage");
    bytes32 constant GLOBAL_BYTES_STORAGE_POSITION = keccak256("diamond.standard.global.bytes.storage");
    bytes32 constant GLOBAL_INTERFACES_STORAGE_POSITION = keccak256("diamond.standard.global.interface.storage");
    bytes32 constant GLOBAL_ARR_STORAGE_POSITION = keccak256("diamond.standard.global.arr.storage");
    bytes32 constant GLOBAL_MAP_STORAGE_POSITION = keccak256("diamond.standard.global.map.storage");
    bytes32 constant GLOBAL_BOOLEAN_STORAGE_POSITION = keccak256("diamond.standard.global.bool.storage");

    struct Stake {
        address owner;
        uint256 timeStamp;
        uint256 budsAmount;
        uint256 farmerTokenId;
    }
    
    struct Raid {
        address raider;
        bool isBoosted;
        uint256 stakers;
        uint256 local;
        uint256 global;
        uint256 noOfChains;
        bool isCustom;
        uint256 riskLevel;
    }

    struct Interfaces {
        IBudsToken _budsToken;
        IChars _farmerToken;
        IChars _narcToken;
        IBoosters _stonerToken;
        IBoosters _informantToken;
        IRaidHandler _raidHandler;
        IBudsVault _budsVault;
        ISupraRouter _supraRouter;
        IStaking _stakingContract;
    }

    struct Integers {
        uint256 baseAPR;
        uint256 globalStakedBudsCount;
        uint256 localStakedBudsCount;
        uint256 noOfChains;
        uint256 previousLiquidityProvisionTimeStamp;
        uint256 totalStakedFarmers;
        uint256 raidFees;
        uint32 myChainID;
        uint256 numberOfStakers;
    }

    struct Addresses {
        address payable treasuryWallet;
    }

    struct ByteStore {
        bytes32 CROSS_CHAIN_RAID_MESSAGE;
        bytes32 CROSS_CHAIN_STAKE_MESSAGE;
        bytes4 GetLocalSelector;
    }

    struct Arrays {
        address[] stakerAddresses;
        Raid[] raiderQueue;
    }

    struct Mappings {
        mapping(address => Stake[]) stakeRecord;
        mapping(address => bool) stakedFarmer;
        mapping(address => uint256[]) boosts;
        mapping(address => uint256) rewards;
        mapping(address => uint256[]) lastRaidBoost;
    }

    struct Booleans {
        bool isContestOpen;
    }

    function intStore() internal pure returns (Integers storage ds) {
        bytes32 position = GLOBAL_INT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function boolStore() internal pure returns (Booleans storage ds) {
        bytes32 position = GLOBAL_BOOLEAN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function mappingStore() internal pure returns (Mappings storage ds) {
        bytes32 position = GLOBAL_MAP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function arrayStore() internal pure returns (Arrays storage ds) {
        bytes32 position = GLOBAL_ARR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function bytesStore() internal pure returns (ByteStore storage ds) {
        bytes32 position = GLOBAL_BYTES_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function interfaceStore() internal pure returns (Interfaces storage ds) {
        bytes32 position = GLOBAL_INTERFACES_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function addressStore() internal pure returns (Addresses storage ds) {
        bytes32 position = GLOBAL_ADDRESS_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getCurrentApr() internal view returns (uint256) {
        if (intStore().localStakedBudsCount == 0) return intStore().baseAPR;

        uint256 localStakedBuds = intStore().localStakedBudsCount * 1 ether;
        uint256 globalStakedBuds = intStore().globalStakedBudsCount * 1 ether;

        uint256 globalStakedAVG = globalStakedBuds /intStore().noOfChains;
        uint256 adjustmentFactor;
        uint256 calculatedAPR;

        localStakedBuds = localStakedBuds / 100;
        adjustmentFactor = uint256(globalStakedAVG / localStakedBuds);
        calculatedAPR = (intStore().baseAPR * adjustmentFactor) / 100;

        if (calculatedAPR < 10) return 10 * 100;
        if (calculatedAPR > 200) return 200 * 100;

        return uint256(calculatedAPR) * 100;
    }

    function _onStake(uint256 tokenId, address sender, uint256 _budsAmount) internal {
        if (_budsAmount < 1 ether && tokenId == 0) revert InvalidData();
        if(mappingStore().stakedFarmer[sender]) revert FarmerStakedAlready();
        Stake memory stk = Stake({
            owner: sender,
            timeStamp: block.timestamp,
            budsAmount:_budsAmount,
            farmerTokenId : tokenId
        });
        intStore().localStakedBudsCount += _budsAmount;
        intStore().globalStakedBudsCount += _budsAmount;
        if(mappingStore().stakeRecord[msg.sender].length == 0){
            intStore().numberOfStakers += 1;
        }
        mappingStore().stakeRecord[sender].push(stk);

        if (tokenId != 0) {
            intStore().totalStakedFarmers += 1;
            mappingStore().stakedFarmer[sender] = true;
            interfaceStore()._farmerToken.mintTokenId(address(this), tokenId);
        }

        if (_budsAmount != 0) {
            interfaceStore()._budsToken.mintTo(address(this), _budsAmount);
        }
        emit Staked(
            sender,
            tokenId,
            stk.budsAmount,
            block.timestamp,
            intStore().localStakedBudsCount,
            getCurrentApr()
        );
    }

    function raidPool(uint256 tokenId,address _raider) internal {
        if (tokenId != 0) {
            for (uint256 i = 0; i < mappingStore().lastRaidBoost[_raider].length; i++) {
                if (block.timestamp - mappingStore().lastRaidBoost[_raider][i] > 7 days) {
                    mappingStore().lastRaidBoost[_raider][i] = mappingStore().lastRaidBoost[_raider][mappingStore().lastRaidBoost[_raider].length - 1];
                    mappingStore().lastRaidBoost[_raider].pop();
                }
            }
            if (mappingStore().lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
            mappingStore().lastRaidBoost[_raider].push(block.timestamp);
        }
        arrayStore().raiderQueue.push(
            Raid({
                raider: _raider,
                isBoosted: tokenId != 0,
                stakers: arrayStore().stakerAddresses.length,
                local: intStore().localStakedBudsCount,
                global: intStore().globalStakedBudsCount,
                noOfChains: intStore().noOfChains,
                isCustom: false,
                riskLevel: 0
            })
        );
        uint256 nonce = interfaceStore()._supraRouter.generateRequest(
            "sendRaidResult(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
    }

    function raidPoolCustom(uint256 tokenId, address _raider, uint256 riskLevel) internal {
        if(!boolStore().isContestOpen) revert ContestNotOpen();
        if(riskLevel > 3 || riskLevel < 1) revert InvalidRiskLevel();
        if (tokenId != 0) {
            for (uint256 i = 0; i < mappingStore().lastRaidBoost[_raider].length; i++) {
                if (block.timestamp - mappingStore().lastRaidBoost[_raider][i] > 7 days) {
                    mappingStore().lastRaidBoost[_raider][i] = mappingStore().lastRaidBoost[_raider][mappingStore().lastRaidBoost[_raider].length - 1];
                    mappingStore().lastRaidBoost[_raider].pop();
                }
            }
            if (mappingStore().lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
            mappingStore().lastRaidBoost[_raider].push(block.timestamp);
        }
        arrayStore().raiderQueue.push(
            Raid({
                raider: _raider,
                isBoosted: tokenId != 0,
                stakers: arrayStore().stakerAddresses.length,
                local: intStore().localStakedBudsCount,
                global: intStore().globalStakedBudsCount,
                noOfChains: intStore().noOfChains,
                isCustom: true,
                riskLevel: riskLevel
            })
        );
        uint256 nonce = interfaceStore()._supraRouter.generateRequest(
            "sendRaidResult(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
    }

    // TODO - modify according to new raid mechanism
    function finalizeRaid(address raider, bool isSuccess, bool isboosted, bool isCustom, uint256 raidLevel, uint256 _boosts) internal{
        if(isSuccess){
            uint256 payout = distributeRaidingRewards(raider,interfaceStore()._budsToken.balanceOf(address(this)));
            emit Raided(raider,true,isboosted, payout, _boosts);
            return;
        }
        emit Raided(raider,false,isboosted, 0, _boosts);
    }

    //TODO - Modify according to new raid mechanism
    function distributeRaidingRewards(address to, uint256 rewardAmount) internal returns (uint256 rewardPayout) {
        interfaceStore()._budsToken.burnFrom(address(this), rewardAmount / 100);
        rewardPayout = rewardAmount - (rewardAmount / 100);
        interfaceStore()._budsToken.transfer(to, rewardPayout);
        return rewardPayout;
    }


    function calculateStakingReward(uint256 budsAmount, uint256 timestamp) internal view returns(uint256 rewards){
        uint256 timeStaked = block.timestamp - timestamp;
        // apr have 2 decimal extra so we divide by 10000
        // this is annual 
        rewards = (budsAmount * getCurrentApr())/10000;

        //now this is for staked period
        //reward/365 is reward per day
        //timestaked/1 days is number of days staked
        rewards = (rewards*timeStaked)/365 days;
    }

}