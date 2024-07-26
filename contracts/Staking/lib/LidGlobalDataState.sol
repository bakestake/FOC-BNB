// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBudsToken} from "../../interfaces/IBudsToken.sol";
import {IChars} from "../../interfaces/IChars.sol";
import {IBoosters} from "../../interfaces/IBooster.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";
import {ISupraRouter} from "../../interfaces/ISupraRouter.sol";
import {IBudsVault} from "../../interfaces/IBudsVault.sol";
import {IAsset} from "../../interfaces/IAsset.sol";
import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

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
    error InsufficientBalance();
    error InvalidParams();
    error InvalidTokenNumber();

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
    event Burned(string mintedBooster, address owner, uint256 amount);
    event Raided(
        address indexed raider,
        bool isSuccess,
        bool isBoosted,
        uint256 rewardTaken,
        uint256 boostsUsedInLastSevenDays
    );
    event CrossChainNFTTransfer(
        bytes32 indexed messageId,
        uint32 chainSelector,
        uint256 tokenId,
        address from,
        address to
    );
    event CrossChainBudsTransfer(
        bytes32 indexed messageId,
        uint32 chainSelector,
        uint256 amount,
        address from,
        address to
    );
    event crossChainReceptionFailed(bytes32 indexed messageId, bytes reason);
    event recoveredFailedReceipt(bytes32 indexed messageId);


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
    }

    struct Burners {
        address sender;
        uint256 amount;
    }
    
    struct Raid {
        address raider;
        bool isBoosted;
        uint256 stakers;
        uint256 local;
        uint256 global;
        uint256 noOfChains;
        uint256 riskLevel;
    }

    struct Interfaces {
        IBudsToken _budsToken;
        IAsset _farmerToken;
        IAsset _narcToken;
        IAsset _stonerToken;
        IAsset _informantToken;
        IRaidHandler _raidHandler;
        IBudsVault _budsVault;
        ISupraRouter _supraRouter;
        IEntropy entropy;
    }

    struct Integers {
        uint256 baseAPR;
        uint256 globalStakedBudsCount;
        uint256 localStakedBudsCount;
        uint256 noOfChains;
        uint256 previousLiquidityProvisionTimeStamp;
        uint256 totalStakedFarmers;
        uint256 raidFees;
        uint256 numberOfStakers;
        uint256 budsLostToRaids;
        uint32 myChainID;
    }

    struct Addresses {
        address payable treasuryWallet;
    }

    struct ByteStore {
        bytes32 CROSS_CHAIN_RAID_MESSAGE;
        bytes32 CROSS_CHAIN_STAKE_MESSAGE;
        bytes32 CROSS_CHAIN_NFT_TRANSFER;
        bytes32 CROSS_CHAIN_BUDS_TRANSFER;
        bytes4 GetLocalSelector;
    }

    struct Arrays {
        address[] stakerAddresses;
        Raid[] raiderQueue;
        Burners[] burnQue;
    }

    struct Mappings {
        mapping(address => Stake[]) stakeRecord;
        mapping(address => uint256) stakedFarmer;
        mapping(address => uint256[]) boosts;
        mapping(address => uint256) rewards;
        mapping(address => uint256[]) lastRaidBoost;
        mapping(uint8 => IAsset) tokenByTokenNumber;
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
        // Define a large constant for precision
        uint256 precisionFactor = 1000000;

        // Calculate the average staked buds across all chains
        uint256 globalStakedAVG = LibGlobalVarState.intStore().globalStakedBudsCount / LibGlobalVarState.intStore().noOfChains;

        // Calculate the adjustment factor using integer arithmetic
        uint256 localStakedBuds = LibGlobalVarState.intStore().localStakedBudsCount;

        // Handle division by zero case
        if (localStakedBuds == 0) {
            return LibGlobalVarState.intStore().baseAPR * 100;
        }

        uint256 adjustmentFactor = (globalStakedAVG * precisionFactor) / localStakedBuds;

        // Calculate the APR using integer arithmetic
        uint256 baseAPR = LibGlobalVarState.intStore().baseAPR;
        uint256 calculatedAPR = (baseAPR * adjustmentFactor) / precisionFactor;

        // Enforce APR boundaries
        if (calculatedAPR < 10) return 10 * 100;
        if (calculatedAPR > 200) return 200 * 100;

        return calculatedAPR * 100;

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
        uint256 nonce = LibGlobalVarState.interfaceStore()._supraRouter.generateRequest(
            "sendRaidResult(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
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
        uint256 nonce = LibGlobalVarState.interfaceStore()._supraRouter.generateRequest(
            "sendRaidResult(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
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