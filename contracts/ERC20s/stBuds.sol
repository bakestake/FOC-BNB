// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { OApp, MessagingFee, Origin } from "../lzSupport/OAppUp.sol";
import { MessagingReceipt } from "../lzSupport/OAppSenderUp.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {OApp} from "../lzSupport/OAppUp.sol";
import {IGauge} from "../interfaces/IGauge.sol";

interface IrstBuds{
    function mintTo(address to, uint256 amount) external;
}

/// @title stBuds - Staked buds
/// @author Bakeland @Rushikesh0125
/// @notice Contract for staked buds tokens, Meant to minted to users on staking buds in staking pool
contract StBuds is OApp, ERC20CappedUpgradeable, ReentrancyGuard, OwnableUpgradeable{
    /// Staking contract address
    address public _stakingContract;
    
    /// layerzero endpoint for berachain
    uint32 public beraEndpoint;

    /// Cross chain message types
    bytes32 public CROSS_CHAIN_TRANSFER;
    bytes32 public CROSS_CHAIN_GAUGE_STAKE;

    /// beragauge interface instance
    IGauge public _beraGauge;

    /// rstBuds interface instance
    IrstBuds public _rstBuds;


    /// @notice Modifier for gated functions which are meant to called from staking contract only 
    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, "Only staking contract");
        _;
    }

    /// @param lzEndpoint Address of layerzero endpoint contract on deployed chain
    /// @param stakingContract Address of staking contract
    /// @param _endpointBera Layerero endpoint id for berachain
    /// @notice This function is intializer and only called once at the time of deployment
    function initialize(address lzEndpoint, address stakingContract, uint32 _endpointBera) external initializer {
        CROSS_CHAIN_TRANSFER = bytes32("CROSS_CHAIN_TRANSFER");
        CROSS_CHAIN_GAUGE_STAKE = bytes32("CROSS_CHAIN_GAUGE_STAKE");
        _stakingContract = stakingContract;
        beraEndpoint = _endpointBera;

        __OApp_Init(lzEndpoint, msg.sender);
        __ERC20_init("stBuds", "Staked Buds");
        __ERC20Capped_init(420000000 * 1e18);
        __Reentrancy_init();

    }

    /// @param _addr Address of staking contract
    /// @dev This function is only callable by owner
    /// @notice Function responsible for setting staking contract address
    function setStakingAddress(address _addr) external onlyOwner {
        _stakingContract = _addr;
    }

    /// @param _rstBudsAddress Address of rstBuds contract
    /// @dev This function is only callable by owner
    /// @notice Function responsible for setting rstBuds contract address
    function setRstBuds(address _rstBudsAddress) external onlyOwner {
        _rstBuds = IrstBuds(_rstBudsAddress);
    }

    /// @param _gaugeAddress Address of bera gauge contract
    /// @dev This function is only callable by owner
    /// @notice Function responsible for setting staking contract address
    function setBeraGauge(address _gaugeAddress) external onlyOwner {
        _beraGauge = IGauge(_gaugeAddress);
    }

    function mintTo(address to, uint256 amount) external onlyStakingContract {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyStakingContract {
        _burn(from, amount);
    }

    function stakeInBeraGauge(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount,"Insufficient balance");
        _beraGauge.delegateStake(msg.sender, _amount);
        _rstBuds.mintTo(msg.sender, _amount);
    }

    //function to stake into bera gauge 
    function crossChainBeraStake(uint256 amount) external payable returns (MessagingReceipt memory receipt){
        bytes memory _payload = abi.encode(
            CROSS_CHAIN_GAUGE_STAKE,
            abi.encode(amount, msg.sender)
        );

        _burn(msg.sender, amount);

        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory transferFee = _quote(beraEndpoint, _payload, bytes("0"), false);

        if (msg.value < transferFee.nativeFee) revert ("Insufficient fees");
        receipt = _lzSend(beraEndpoint, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    function crossChainTransfer(uint32 _dstEid, uint256 amount, address to) external payable returns (MessagingReceipt memory receipt){
        bytes memory _payload = abi.encode(
            CROSS_CHAIN_TRANSFER,
            abi.encode( amount, to)
        );

        _burn(msg.sender, amount);
        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory transferFee = _quote(_dstEid, _payload, bytes("0"), false);

        if (msg.value < transferFee.nativeFee) revert ("Insufficient fees");
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));

    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal virtual override nonReentrant{
        (bytes32 messageType, bytes memory _data) = abi.decode(payload, (bytes32, bytes));

        if(messageType == CROSS_CHAIN_TRANSFER){
            (uint256 amount, address to) = abi.decode(_data, (uint256, address));
            _mint(to, amount);
        }

        if(messageType == CROSS_CHAIN_GAUGE_STAKE){
            (uint256 amount, address sender) = abi.decode(_data, (uint256, address));
            _mint(address(this), amount);
            _beraGauge.delegateStake(sender, amount);
            _rstBuds.mintTo(msg.sender, amount);
        }

    }

    function endpoint() external view override returns (ILayerZeroEndpointV2 iEndpoint) {
    }

    function peers(uint32 _eid) external view override returns (bytes32 peer) {
    }
}