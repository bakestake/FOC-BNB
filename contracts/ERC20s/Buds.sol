// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Buds token contract
/// @author Bakeland @Rushikesh0125
/// @notice This contract is responsible for Buds token 
contract Buds is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    error ZeroAddress();
    error UnAuthorizedAccess();

    /// @notice Staking contract address
    address public _stakingContractAddress;


    /// @param _stakingContractAddress_ Address of staking contract
    /// @notice This function is intializer and only called once at the time of deployment
    function initialize(address _stakingContractAddress_) public initializer {
        if (_stakingContractAddress_ == address(0)) {
            revert ZeroAddress();
        }   

        /// Initializing ERC20, Ownable, and upgradable interface
        __ERC20_init("Bakeland Buds token", "BUDS");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _stakingContractAddress = _stakingContractAddress_;

        /// Minting supply to owner
        _mint(msg.sender, 42000000 * 10 ** decimals());
    }
    
    /// @notice Modifier for gated functions which are meant to called from staking contract only 
    modifier OnlyStakingContract() {
        if (msg.sender != _stakingContractAddress) revert UnAuthorizedAccess();
        _;
    }

    /// @param _stk Address of staking contract
    /// @dev This function is only callable by owner
    /// @notice Function responsible for setting staking contract address
    function setStakingContract(address _stk) external onlyOwner{
        _stakingContractAddress = _stk;
    }

    /// @param _from Address from which buds are meant to be burned
    /// @param _amount Amount of buds to burn
    /// @notice Function is used for cross chain burn and mint mechanism
    /// @dev Only callable by staking contract
    function burnFrom(address _from, uint256 _amount) external OnlyStakingContract {
        _burn(_from, _amount);
    }

    /// @param _to  Address to which buds are meant to be minted
    /// @param _amount Amount of buds to minted
    /// @notice Function is used for cross chain burn and mint mechanism
    /// @dev Only callable by staking contract
    function mintTo(address _to, uint256 _amount) external OnlyStakingContract {
        _mint(_to, _amount);
    }

    /// @param newImplementation New implementation contract address
    /// @notice @dev Override only meant for inheritance purpose
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
