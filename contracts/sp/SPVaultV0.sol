// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainRegistry.sol";
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

    // using EnumerableSet for EnumerableSet.AddressSet;

    IFilmountainRegistry public FilmountainRegistry;
    IWFIL public wFIL;
    // EnumerableSet.AddressSet private RegisteredMinerSet;
    mapping(address => address) RegisteredMiner;

    function initialize(
        address _wFIL,
        address _registry
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        wFIL = IWFIL(_wFIL);
        FilmountainRegistry = IFilmountainRegistry(_registry);
    }

    function addMiner(address _glif, address _owner) public onlyOwner {
        // RegisteredMinerSet.add(_glif);
        RegisteredMiner[_glif] = _owner;
    }

    function setMiner(address _glif, address _owner) public onlyOwner {
        RegisteredMiner[_glif] = _owner;
    }

    function removeMiner(address _glif) public onlyOwner {
        // RegisteredMinerSet.remove(_glif);
        delete RegisteredMiner[_glif];
    }

    function borrow(uint256 _amount) public onlyOwner {
        IFilmountainPool(FilmountainRegistry.pool()).borrow(_amount);
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
        IFilmountainPool(FilmountainRegistry.pool()).payInterest{value: _amount}();
    }

    // function payPrincipal(address _owner) public payable onlyOwner {
    //     IFilmountainPool(FilmountainRegistry.pool()).payPrincipal{value: msg.value}(_owner, msg.value);
    // }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {
        if (RegisteredMiner[msg.sender] != address(0)) {
            uint256 part1 = msg.value * 60 / 100;
            uint256 part2 = msg.value * 40 / 100;

            uint256 spAmount = part1 * 80 / 100;
            uint256 zcFromPart1 = part1 * 20 / 100;

            uint256 zcFromPart2 = part2 * 2 / 100;
            uint256 lpAmount = part2 * 98 / 100;

            uint256 zcAmount = zcFromPart1 + zcFromPart2;

            payInterest(lpAmount);
            SafeTransferLib.safeTransferETH(RegisteredMiner[msg.sender], spAmount);
            SafeTransferLib.safeTransferETH(FilmountainRegistry.zc(), zcAmount);
        }
    }
}