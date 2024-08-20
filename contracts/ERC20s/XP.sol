// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IBudsVault {
    function sendBudsTo(address to, uint256 amount) external;
}

interface IStaking {
    function getUserStakes(address userAddress) external returns (uint256 budsAmount, uint256 tokenId);
}

/// @title XP token
/// @author @Rushikesh0125
/// @notice Contract responsible for XP token contract
contract XP is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    error ZeroAddress();
    error InvalidParam();
    error ClaimOnlyAfterADay();

    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;
    
    /// Keeps track of last XP claim by user
    mapping(address => uint) public lastClaimBy;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// Instances of buds vault and staking contract
    IBudsVault public _budsvault;
    IStaking public _stakingContract;

    /// @notice Initializer function
    /// @param budsVault Address of buds vault
    /// @param _staking Address of staking contract
    function initialize(address budsVault, address _staking) public initializer {
        if (budsVault == address(0) || _staking == address(0)) {
            revert ZeroAddress();
        }
        __Ownable_init(msg.sender);
        _name = "Bakelandd XP Token";
        _symbol = "BXP";
        _budsvault = IBudsVault(budsVault);
        _stakingContract = IStaking(_staking);
    }

    /// @param _address Function to set staking contract address
    /// @dev Only callable by owner
    function setStaking(address _address) external onlyOwner {
        if(_address == address(0)) revert ZeroAddress();
        _stakingContract  = IStaking(_address);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /// @param amount Amount of XP to be burnt 
    /// @notice Function to burn XP for Buds
    function burnForBuds(uint256 amount) external returns (uint256 budsRewarded) {
        if (amount < 1000 || amount < balanceOf(msg.sender))
            revert IERC20Errors.ERC20InsufficientBalance(msg.sender, amount, 1000 ether);
        budsRewarded = calculateBudsForXP(amount);
        _burn(msg.sender, amount);
        _budsvault.sendBudsTo(msg.sender, budsRewarded);
    }

    function burn(uint256 amount, address owner) public {
        if (allowance(owner, msg.sender) < amount) {
            revert IERC20Errors.ERC20InsufficientAllowance(msg.sender, allowance(owner, msg.sender), amount);
        }
        _burn(owner, amount);
    }

    /// @param amount Amount of XP 
    /// @notice Calculates amount of buds to be rewarded to user for burning specific amount of XP
    function calculateBudsForXP(uint256 amount) public pure returns (uint256 budsReward) {
        if (amount <= 0) {
            revert InvalidParam();
        }
        budsReward = amount / 1000;
    }

    /// @notice Function to claim XP every day
    function claimXP() public returns (uint256 xpToMint) {
        if (lastClaimBy[msg.sender] < 1 days) revert ClaimOnlyAfterADay();
        lastClaimBy[msg.sender] = block.timestamp;
        xpToMint = calculateXp(msg.sender);
        _mint(msg.sender, xpToMint);
    }

    /// @notice Function to calculate amount of XP to be claimed by user
    /// Depends on users Stake
    function calculateXp(address userAddress) internal returns (uint256 xpToMint) {
        (uint256 budsAmount, uint256 tokenId) = _stakingContract.getUserStakes(userAddress);
        xpToMint += 10;
        xpToMint += (budsAmount / 1000);
        xpToMint += tokenId == 0 ? 0 : 10;
    }

    // function validateLevelUpXP(uint256 tokenId)

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit IERC20.Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert IERC20Errors.ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit IERC20.Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}
