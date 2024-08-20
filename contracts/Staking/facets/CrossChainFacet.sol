// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { OApp, MessagingFee, Origin } from "../../lzSupport/OAppUp.sol";
import { MessagingReceipt } from "../../lzSupport/OAppSenderUp.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {IStaking} from "../../interfaces/IStaking.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";

import "../lib/LidGlobalDataState.sol";
import {LzState} from "../lib/Lz.sol";


contract CrossChainFacet is OApp {

    using OptionsBuilder for bytes; 

    function changeEndpoint(address _endpoint) external {
        LibDiamond.enforceIsContractOwner();
        LzState.getStorage().endpoint = ILayerZeroEndpointV2(_endpoint);
    }

    function crossChainStake(
        uint256 _budsAmount,
        uint256 _farmerTokenId,
        uint32 destChainId
    ) external payable returns (MessagingReceipt memory receipt) {
        if (_budsAmount == 0 && _farmerTokenId == 0) revert LibGlobalVarState.InvalidData();
        if (
            _farmerTokenId != 0 && LibGlobalVarState.interfaceStore()._farmerToken.ownerOf(_farmerTokenId) != msg.sender
        ) revert LibGlobalVarState.NotOwnerOfAsset();

        if (_budsAmount != 0) {
            LibGlobalVarState.interfaceStore()._budsToken.burnFrom(msg.sender, _budsAmount);
            LibGlobalVarState.intStore().globalStakedBudsCount += _budsAmount;
            LibGlobalVarState.intStore().localStakedBudsCount += _budsAmount;
        }
        if (_farmerTokenId != 0) {
            LibGlobalVarState.interfaceStore()._farmerToken.burnFrom(_farmerTokenId);
        }

        bytes memory payload = abi.encode(
            LzState.getStorage().CROSS_CHAIN_STAKE_MESSAGE,
            abi.encode(_budsAmount, _farmerTokenId, msg.sender)
        );
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_500_000, 0);
        MessagingFee memory ccmFees = _quote(destChainId, payload, options, false);

        if (msg.value < ccmFees.nativeFee) revert LibGlobalVarState.InsufficientFees();

        receipt = _lzSend(destChainId, payload, options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    function crossChainRaid(
        uint32 destChainId,
        uint256 tokenId
    ) external payable returns (MessagingReceipt memory receipt) {
        if (LibGlobalVarState.interfaceStore()._narcToken.balanceOf(msg.sender) == 0)
            revert LibGlobalVarState.NotANarc();
        if (tokenId != 0) {
            if (LibGlobalVarState.interfaceStore()._informantToken.ownerOf(tokenId) != msg.sender)
                revert LibGlobalVarState.NotOwnerOfAsset();
            LibGlobalVarState.interfaceStore()._informantToken.burnFrom(tokenId);
        }

        bytes memory payload = abi.encode(
            LzState.getStorage().CROSS_CHAIN_RAID_MESSAGE,
            abi.encode(tokenId, 0, msg.sender)
        );
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_500_000, 0);
        MessagingFee memory ccmFees = _quote(destChainId, payload, options, false);

        if (msg.value - LibGlobalVarState.intStore().raidFees < ccmFees.nativeFee)
            revert LibGlobalVarState.InsufficientRaidFees();
        receipt = _lzSend(destChainId, payload, options, ccmFees, payable(msg.sender));

        LibGlobalVarState.addressStore().treasuryWallet.transfer(LibGlobalVarState.intStore().raidFees);
    }

    function crossChainBudsTransfer(
        uint32 _dstEid,
        address _to,
        uint256 _amount
    ) external payable returns (MessagingReceipt memory receipt) {
        if (_amount == 0) revert LibGlobalVarState.InvalidParams();
        if (LibGlobalVarState.interfaceStore()._budsToken.balanceOf(msg.sender) < _amount)
            revert LibGlobalVarState.InsufficientBalance();

        bytes memory _payload = abi.encode(
            LzState.getStorage().CROSS_CHAIN_BUDS_TRANSFER,
            abi.encode(0, _amount, msg.sender, _to)
        );
        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_500_000, 0);
        MessagingFee memory transferFee = _quote(_dstEid, _payload, bytes("0"), false);

        if (msg.value < transferFee.nativeFee) revert LibGlobalVarState.InsufficientFees();

        LibGlobalVarState.interfaceStore()._budsToken.burnFrom(msg.sender, _amount);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit LibGlobalVarState.CrossChainBudsTransfer(receipt.guid, _dstEid, _amount, msg.sender, _to);
    }

    function crossChainNFTTransfer(
        uint32 _dstEid,
        address _to,
        uint256 tokenId,
        uint8 tokenNumber
    ) external payable returns (MessagingReceipt memory receipt) {
        if (tokenNumber > 4) revert LibGlobalVarState.InvalidTokenNumber();
        IAsset assetToSend = LibGlobalVarState.mappingStore().tokenByTokenNumber[tokenNumber];
        if (tokenId == 0) revert LibGlobalVarState.InvalidParams();

        bytes memory _payload = abi.encode(
            LzState.getStorage().CROSS_CHAIN_NFT_TRANSFER,
            abi.encode(tokenNumber, tokenId, msg.sender, _to)
        );
        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_500_000, 0);
        MessagingFee memory transferFee = _quote(_dstEid, _payload, bytes("0"), false);

        if (msg.value < transferFee.nativeFee) revert LibGlobalVarState.InsufficientFees();

        assetToSend.burnFrom(tokenId);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit LibGlobalVarState.CrossChainNFTTransfer(receipt.guid, _dstEid, tokenId, msg.sender, _to);
    }

    function _payNative(uint256 _nativeFee) internal override returns (uint256) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (bytes32 messageType, bytes memory _data) = abi.decode(payload, (bytes32, bytes));

        if (messageType == LzState.getStorage().CROSS_CHAIN_STAKE_MESSAGE) {
            (uint256 budsAmount, uint256 tokenId, address sender) = abi.decode(_data, (uint256, uint256, address));
            _onStake(tokenId, sender, budsAmount);
            return;
        }
        if (messageType == LzState.getStorage().CROSS_CHAIN_RAID_MESSAGE) {
            (uint256 tokenId, uint256 riskLevel, address sender) = abi.decode(_data, (uint256, uint256, address));
            if (riskLevel == 0) {
                IStaking(address(this)).raidPool(tokenId, sender);
            } else {
                IStaking(address(this)).raidPoolCustom(tokenId, sender, riskLevel);
            }
            return;
        }

        if (messageType == LzState.getStorage().CROSS_CHAIN_BUDS_TRANSFER) {
            (, uint amount, , address to) = abi.decode(_data, (uint8, uint, address, address));
            LibGlobalVarState.interfaceStore()._budsToken.mintTo(to, amount);
            return;
        }

        if (messageType == LzState.getStorage().CROSS_CHAIN_NFT_TRANSFER) {
            (uint8 tokenNumber, uint tokenID, , address to) = abi.decode(_data, (uint8, uint, address, address));
            if (tokenNumber < 1 || tokenNumber > 4) revert LibGlobalVarState.InvalidTokenNumber();
            IAsset assetToReceive = LibGlobalVarState.mappingStore().tokenByTokenNumber[tokenNumber];
            assetToReceive.mintTokenId(to, tokenID);
            return;
        }
    }

    function getCctxFees(
        uint32 eId,
        uint256 budsAmount,
        uint256 tokenId,
        address sender
    ) external view returns (uint256) {
        bytes memory payload = abi.encode(
            LzState.getStorage().CROSS_CHAIN_STAKE_MESSAGE,
            abi.encode(budsAmount, tokenId, sender)
        );
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_500_000, 0);
        MessagingFee memory ccmFees = _quote(eId, payload, options, false);
        return ccmFees.nativeFee;
    }

    function _onStake(uint256 tokenId, address sender, uint256 _budsAmount) internal {
        if (_budsAmount < 1 ether && tokenId == 0) revert LibGlobalVarState.InvalidData();
        if (tokenId != 0 && LibGlobalVarState.mappingStore().stakedFarmer[sender] != 0)
            revert LibGlobalVarState.FarmerStakedAlready();
        LibGlobalVarState.Stake memory stk = LibGlobalVarState.Stake({
            owner: sender,
            timeStamp: block.timestamp,
            budsAmount: _budsAmount
        });
        LibGlobalVarState.intStore().localStakedBudsCount += _budsAmount;
        LibGlobalVarState.intStore().globalStakedBudsCount += _budsAmount;

        if (LibGlobalVarState.mappingStore().stakeRecord[sender].length == 0) {
            LibGlobalVarState.intStore().numberOfStakers += 1;
        }
        LibGlobalVarState.mappingStore().stakeRecord[sender].push(stk);

        if (tokenId != 0) {
            LibGlobalVarState.intStore().totalStakedFarmers += 1;
            LibGlobalVarState.mappingStore().stakedFarmer[sender] = tokenId;
            LibGlobalVarState.interfaceStore()._farmerToken.mintTokenId(address(this), tokenId);
        }

        if (_budsAmount != 0) {
            LibGlobalVarState.interfaceStore()._budsToken.mintTo(address(this), _budsAmount);
        }
        emit LibGlobalVarState.Staked(
            sender,
            tokenId,
            stk.budsAmount,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

 
    function endpoint() external view override returns (ILayerZeroEndpointV2 iEndpoint) {}

    function peers(uint32 _eid) external view override returns (bytes32 peer) {}
}