// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainAddressRegistry.sol";
import {IFilmountainPool} from "../interfaces/IFilmountainPool.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SendAPI} from "filecoin-solidity-api/contracts/v0.8/SendAPI.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract SPVaultV0 is 
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error IncorrectWithdrawal();
    event PushFund(uint64 minerId, uint256 amount);

    IFilmountainAddressRegistry public FilmountainAddressRegistry;
    IWFIL public wFIL;

    function initialize(
        address _wFIL,
        address _addressRegistry
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        wFIL = IWFIL(_wFIL);
        FilmountainAddressRegistry = IFilmountainAddressRegistry(_addressRegistry);
    }

    function borrow(uint256 _amount) public onlyOwner {
        IFilmountainPool(FilmountainAddressRegistry.pool()).borrow(_amount);
    }

    function pushFund(uint64 _minerId, uint256 _amount) public onlyOwner {
        uint256 balanceWETH9 = wFIL.balanceOf(address(this));
        // -- 꺼내려는 양이 wFIL balance 보다 많은지 체크 --
        if (_amount > balanceWETH9) revert IncorrectWithdrawal();

        // -- wFIL를 FIL로 unwrapping하고 miner로 전송 --
        wFIL.withdraw(_amount);
        SendAPI.send(CommonTypes.FilActorId.wrap(_minerId), _amount);
        emit PushFund(_minerId, _amount);
    }

    function payInterest(uint256 _amount) public {
        IFilmountainPool(FilmountainAddressRegistry.pool()).payInterest{value: _amount}();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}
}