// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IChars.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTFaucet is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    IChars public _farmerToken;
    IChars public _narcToken;

    address[] farmers;
    address[] narcs;

    mapping (address => bool) public farmerClaimedBy;
    mapping (address => bool) public narcClaimedBy;

    function initialize(
        address _farmer, address _narcs
    ) public initializer{
        __Ownable_init(msg.sender);
        _farmerToken = IChars(_farmer);
        _narcToken = IChars(_narcs);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


    function setFarmer(address _farmer) public onlyOwner{
        _farmerToken = IChars(_farmer);
        delete farmers;
    }

    function setNarc(address _narc) public onlyOwner{
        _narcToken = IChars(_narc);
        delete narcs;
    }

    function canClaimFarmer() public view returns(bool){
        return !farmerClaimedBy[msg.sender];
    }

    function canClaimNarc() public view returns(bool){
        return !narcClaimedBy[msg.sender];
    }

    function claimFarmer() external {
        require(!farmerClaimedBy[msg.sender], "already claimed");
        farmerClaimedBy[msg.sender] = true;
        farmers.push(msg.sender);
        _farmerToken.safeMint(msg.sender);
    }

    function claimNarc() external {
        require(!narcClaimedBy[msg.sender], "already claimed");
        narcClaimedBy[msg.sender] = true;
        narcs.push(msg.sender);
        _narcToken.safeMint(msg.sender);
    }

    
}