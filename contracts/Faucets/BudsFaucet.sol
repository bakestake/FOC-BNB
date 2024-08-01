// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BudsFaucet is  Initializable, UUPSUpgradeable, OwnableUpgradeable{

    IERC20 public _budsToken;
    mapping (address => uint256) public lastClaimeBy;

    
    function initialize(
        address _budsAddress
    ) public initializer{
        __Ownable_init(msg.sender);
        _budsToken = IERC20(_budsAddress);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function setBudsAddress(address _budsToken_) public onlyOwner{
        _budsToken = IERC20(_budsToken_);
    }

    function nextClaimTimeInSeconds(address _sender) public view returns(uint256){
        uint256 timeElapsedFromLastClaim = block.timestamp - lastClaimeBy[_sender];
        return 12 hours - timeElapsedFromLastClaim;
    }

    function claim(address _receiver) external {
        require(block.timestamp - lastClaimeBy[_receiver] >= 12 hours);
        lastClaimeBy[_receiver] = block.timestamp;
        _budsToken.transfer(_receiver, 42069*1 ether);
    }

    
}