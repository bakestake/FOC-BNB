// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IBooster.sol";
import "../../interfaces/ISupraRouter.sol";

import "../lib/LidGlobalDataState.sol";

contract BurnFacet {

    function burnForInformant() external returns (uint256 requestId) {
        if (LibGlobalVarState.interfaceStore()._budsToken.balanceOf(msg.sender) < 1000 ether) {
            revert ("Insufficient balance");
        }
        LibGlobalVarState.arrayStore().burnQue.push(LibGlobalVarState.Burners({ sender: msg.sender, amount: 0 }));
        requestId = LibGlobalVarState.interfaceStore()._supraRouter.generateRequest(
            "mintBooster(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
        requestId;
    }

    function burnForStoner() external returns (uint256 requestId) {
        if (LibGlobalVarState.interfaceStore()._budsToken.balanceOf(msg.sender) < 1000 ether) {
            revert ("Insufficient balance");
        }
        LibGlobalVarState.arrayStore().burnQue.push(LibGlobalVarState.Burners({ sender: msg.sender, amount: 1 }));
        requestId = LibGlobalVarState.interfaceStore()._supraRouter.generateRequest(
            "mintBooster(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
        requestId;
    }

    function mintBooster(
        uint256 _nonce,
        uint256[] memory _rngList
    ) external returns (uint256 tokenId, string memory boosterType) {
        require(msg.sender == address(LibGlobalVarState.interfaceStore()._supraRouter));

        uint256 randomNo = _rngList[0];

        LibGlobalVarState.Burners memory currentBurner = LibGlobalVarState.arrayStore().burnQue[0];
        for (uint256 i = 0; i < LibGlobalVarState.arrayStore().burnQue.length - 1; i++) {
            LibGlobalVarState.arrayStore().burnQue[i] = LibGlobalVarState.arrayStore().burnQue[i + 1];
        }
        LibGlobalVarState.arrayStore().burnQue.pop();

        /// User should not get the boosters if balance is not 1000 so no revert will be there on burn
        if (LibGlobalVarState.interfaceStore()._budsToken.balanceOf(currentBurner.sender) < 1000 ether) {
            revert ("insufficient");
        }

        LibGlobalVarState.interfaceStore()._budsToken.burnFrom(currentBurner.sender, 1000 * 1 ether);

        randomNo = randomNo % 2;
        if (currentBurner.amount == 0 && randomNo == 1) {
            boosterType = "informant";
            tokenId = LibGlobalVarState.interfaceStore()._informantToken.safeMint(currentBurner.sender);
            emit LibGlobalVarState.Burned("Informant", currentBurner.sender, currentBurner.amount);
        } else if (currentBurner.amount == 1 && randomNo == 1) {
            boosterType = "stoner";
            tokenId = LibGlobalVarState.interfaceStore()._stonerToken.safeMint(currentBurner.sender);
            emit LibGlobalVarState.Burned("Stoner", currentBurner.sender, currentBurner.amount);
        } else {
            emit LibGlobalVarState.Burned("NoLuck", currentBurner.sender, currentBurner.amount);
        }
    }

}