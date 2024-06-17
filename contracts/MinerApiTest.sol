// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FilAddress} from "fevmate/contracts/utils/FilAddress.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";

contract MinerApiTest {
    using FilAddress for address;

    error API_ERROR(int256);

    function getOwner(uint64 _minerId) public view returns (bytes memory) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (int256 exitcode, MinerTypes.GetOwnerReturn memory ownerReturn) = MinerAPI.getOwner(minerId);
        if (exitcode != 0) revert API_ERROR(exitcode);
        return ownerReturn.owner.data;
    }

    // function changeOwnerAddress() public returns (string) {
        
    // }
}