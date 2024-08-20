// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title rstBuds token contract
/// @author Bakeland @Rushikesh0125
/// @notice This contract is responsible for Buds token 
contract rstBuds is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    error ZeroAddress();
    error UnAuthorizedAccess();

    /// @notice Staking contract address
    address public _stBudsToken;


    /// @param _stBudsContract Address of stBuds contract
    /// @notice This function is intializer and only called once at the time of deployment
    function initialize(address _stBudsContract) public initializer {
        if (_stBudsContract == address(0)) {
            revert ZeroAddress();
        }   

        /// Initializing ERC20, Ownable, and upgradable interface
        __ERC20_init("Bakeland rst Buds token", "BUDS");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _stBudsToken = _stBudsContract;

    }
    
    /// @notice Modifier for gated functions which are meant to called from staking contract only 
    modifier OnlystBudsContract() {
        if (msg.sender != _stBudsToken) revert UnAuthorizedAccess();
        _;
    }

    /// @param _stBuds Address of stBuds contract
    /// @dev This function is only callable by owner
    /// @notice Function responsible for setting staking contract address
    function setStBudsContract(address _stBuds) external onlyOwner{
        _stBudsToken = _stBuds;
    }
    
    function mintTo(address _to, uint256 _amount) external OnlystBudsContract{
        _mint(_to, _amount);
    }

    /// @param newImplementation New implementation contract address
    /// @notice @dev Override only meant for inheritance purpose
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
