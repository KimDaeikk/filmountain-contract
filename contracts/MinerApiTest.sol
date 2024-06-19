// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FilAddress} from "fevmate/contracts/utils/FilAddress.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";
import {PrecompilesAPI} from "filecoin-solidity-api/contracts/v0.8/PrecompilesAPI.sol";

contract MinerApiTest {
    using FilAddress for address;

    error API_ERROR(int256);

    function getOwner(uint64 _minerId) public view returns (bytes memory) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (int256 exitcode, MinerTypes.GetOwnerReturn memory ownerReturn) = MinerAPI.getOwner(minerId);
        if (exitcode != 0) revert API_ERROR(exitcode);
        return ownerReturn.owner.data;
    }

    function getOwnerId(uint64 _minerId) public view returns (uint64) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (int256 exitcode, MinerTypes.GetOwnerReturn memory ownerReturn) = MinerAPI.getOwner(minerId);
        if (exitcode != 0) revert API_ERROR(exitcode);
        return PrecompilesAPI.resolveAddress(ownerReturn.owner);
    }

    // miner actor에 주소가 owner, beneficiary 등으로 포함되어있는지
    function isControllingAddress(uint64 _minerId, bytes memory _addr) public view returns (bool control) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        CommonTypes.FilAddress memory filAddr = CommonTypes.FilAddress(_addr);
        (, control) = MinerAPI.isControllingAddress(minerId, filAddr);
    }

    function getSectorSize(uint64 _minerId) public view returns (uint64 size) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, size) = MinerAPI.getSectorSize(minerId);
    }

    function getAvailableBalance(uint64 _minerId) public view returns (CommonTypes.BigInt memory) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, CommonTypes.BigInt memory balance) = MinerAPI.getAvailableBalance(minerId);
        return balance;
    }

    function getVestingFunds(uint64 _minerId) public view returns (MinerTypes.VestingFunds[] memory funds) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, funds) = MinerAPI.getVestingFunds(minerId);
    }

    function getBeneficiary(uint64 _minerId) public view returns (MinerTypes.GetBeneficiaryReturn memory) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, MinerTypes.GetBeneficiaryReturn memory beneficiary) = MinerAPI.getBeneficiary(minerId);
        return beneficiary;
    }

    function getPeerId(uint64 _minerId) public view returns (CommonTypes.FilAddress memory) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, CommonTypes.FilAddress memory peerId) = MinerAPI.getPeerId(minerId);
        return peerId;
    }

    function getMultiaddresses(uint64 _minerId) public view returns (CommonTypes.FilAddress[] memory addresses) {
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, addresses) = MinerAPI.getMultiaddresses(minerId);
    }
}