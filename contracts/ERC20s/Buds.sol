// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IBooster.sol";
import "../interfaces/ISupraRouter.sol";

contract Buds is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    error ZeroAddress();
    error UnAuthorizedAccess();

    IBoosters public _informantToken;
    IBoosters public _stonerToken;

    address public _stakingContractAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize( address _informantToken_, address _stonerToken_, address _stakingContractAddress_) public initializer {
        if (_informantToken_ == address(0) || _stonerToken_ == address(0)) {
            revert ZeroAddress();
        }
        __ERC20_init("Bakeland Buds token", "BUDS");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _informantToken = IBoosters(_informantToken_);
        _stonerToken = IBoosters(_stonerToken_);

        _stakingContractAddress = _stakingContractAddress_;

        _mint(msg.sender, 42000000 * 10 ** decimals());
    }

    modifier OnlyStakingContract() {
        if (msg.sender != _stakingContractAddress) revert UnAuthorizedAccess();
        _;
    }

    function burnFrom(address from, uint256 amount) external OnlyStakingContract {
        _burn(from, amount);
    }

    function mintTo(address _to, uint256 _amount) external OnlyStakingContract {
        _mint(_to, _amount);
    }

    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
