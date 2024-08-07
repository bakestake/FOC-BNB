// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";


contract stBuds is Initializable, ERC20CappedUpgradeable, UUPSUpgradeable, OwnableUpgradeable {

    address _stakingContract;

    modifier onlyStakingContract {
        require(msg.sender ==  _stakingContract, "Only staking contract");
        _;
    }

    function init() external initializer {
        __ERC20_init("stBuds", "Staked Buds");
        __ERC20Capped_init(420000000*1e18);
    }

    function setStakingAddress(address _addr) external onlyOwner {
        _stakingContract = _addr;
    }

    function mintTo(address to, uint256 amount) external onlyStakingContract{
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyStakingContract{
        _burn(from, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}