// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import "../interfaces/IXP.sol";
import "../interfaces/IChars.sol";

contract Farmer is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    error ZeroAddress();
    error UnauthorizedAccess();
    error CapReached();

    bytes32 public MINTER_ROLE;
    bytes32 public UPGRADER_ROLE;
    bytes32 public STAKING_CONTRACT;

    uint256 private _nextTokenId;
    uint256 private _tokensLeft;

    address public _xpToken;

    mapping(uint256 tokenId => uint8 level) public levelByTokenId;
    mapping(uint8 level => string uri) public uriByLevel;

    function initialize(uint256 _seed, address _xp, address _stakingAddress, string[] memory uris) public initializer {
        if (_xp == address(0)) revert ZeroAddress();

        __ERC721_init("Bakeland Farmer", "FARMER");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        MINTER_ROLE = keccak256("MINTER_ROLE");
        UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
        STAKING_CONTRACT = keccak256("STAKING_CONTRACT");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(STAKING_CONTRACT, _stakingAddress);

        _tokensLeft = 690;
        _nextTokenId = _seed;
        _xpToken = _xp;

        for (uint8 i = 1; i < 11; i++) {
            uriByLevel[i] = uris[i - 1];
        }
    }


    function setMinter(address newMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newMinter == address(0)) revert ZeroAddress();
        _grantRole(MINTER_ROLE, newMinter);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        if (_tokensLeft == 0) revert CapReached();
        tokenId = _nextTokenId++;
        _tokensLeft -= 1;
        levelByTokenId[tokenId] = 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uriByLevel[1]);
    }

    function levelUpToken(uint256 tokenId) external {
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId))
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        if (ownerOf(tokenId) != msg.sender) revert UnauthorizedAccess();

        uint256 xpToBurn = calculateRequiredXp(levelByTokenId[tokenId]);

        IXP(_xpToken).burn(msg.sender, xpToBurn);

        levelByTokenId[tokenId]++;
        _setTokenURI(tokenId, uriByLevel[levelByTokenId[tokenId]]);
    }

    function calculateRequiredXp(uint8 level) internal pure returns (uint256 xpToBurn) {
        return level + 1 * 500 ether;
    }

    function burnFrom(uint256 tokenId) public onlyRole(STAKING_CONTRACT){
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId))
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        _burn(tokenId);
    }

    function mintTokenId(address _to, uint256 _tokenId) external onlyRole(STAKING_CONTRACT) {
        _mint(_to, _tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function balanceOf(address owner) public view override(ERC721Upgradeable, IERC721) returns (uint256 balance) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override(ERC721Upgradeable, IERC721) returns (address owner) {
        return super.ownerOf(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) {
        super.transferFrom(from, to, tokenId);
    }

    function setUriForToken(uint256 tokenId, string calldata uriString) external onlyRole(STAKING_CONTRACT) {
        _setTokenURI(tokenId, uriString);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {}
}
