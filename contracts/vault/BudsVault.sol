// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BudsVault is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    error NotWhitelisted(address addr);

    IERC20 public _budsToken;

    uint256 public vaultBalance;

    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        if (!whitelist[msg.sender] && msg.sender != owner()) revert NotWhitelisted(msg.sender);
        _;
    }

    function initialize(address budsToken) public initializer {
        __Ownable_init(msg.sender);
        _budsToken = IERC20(budsToken);
    }

    function deposite(address from, uint256 amount) public onlyWhitelisted{
        vaultBalance += amount;
        _budsToken.transferFrom(from, address(this), amount);
    }

    function whitelistContracts(address[] memory contractAddresses) public onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            whitelist[contractAddresses[i]] = true;
        }
    }

    function removeContracts(address[] memory contractAddresses) public onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            whitelist[contractAddresses[i]] = false;
        }
    }

    function sendBudsTo(address to, uint256 amount) public onlyWhitelisted {
        vaultBalance = vaultBalance - amount;
        _budsToken.transfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}
