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
    

}