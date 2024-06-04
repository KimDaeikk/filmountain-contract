// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FilMountainPool is 
    ReentrancyGuard
{
    // function borrow(VerifiableCredential memory vc) external isOpen subjectIsAgentCaller(vc) {
    //     // 1e18 => 1 FIL, can't borrow less than 1 FIL
    //     if (vc.value < WAD) revert InvalidParams();
    //     // can't borrow more than the pool has
    //     if (totalBorrowableAssets() < vc.value) revert InsufficientLiquidity();
    //     Account memory account = _getAccount(vc.subject);
    //     // fresh account, set start epoch and epochsPaid to beginning of current window
    //     if (account.principal == 0) {
    //         uint256 currentEpoch = block.number;
    //         account.startEpoch = currentEpoch;
    //         account.epochsPaid = currentEpoch;
    //         GetRoute.agentPolice(router).addPoolToList(vc.subject, id);
    //     }

    //     account.principal += vc.value;
    //     account.save(router, vc.subject, id);

    //     totalBorrowed += vc.value;

    //     emit Borrow(vc.subject, vc.value);

    //     // interact - here `msg.sender` must be the Agent bc of the `subjectIsAgentCaller` modifier
    //     asset.transfer(msg.sender, vc.value);
    // }
}