// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "wormhole-solidity-sdk/interfaces/IWormhole.sol";

interface IStaking {
    function raidPool( uint256 tokenId, address sender) external;
    function raidPoolCustom( uint256 tokenId, address sender, uint256 riskLevel) external;
    function updateState(bytes memory response, IWormhole.Signature[] memory signatures) external;
    function getstakingRecord(address userAddress) external returns (address user, uint256 budsAmount, uint256 tokenId);
}
