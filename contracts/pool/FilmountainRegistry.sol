// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FilmountainRegistry is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddUser(address target);
    event RemoveUser(address traget);

    EnumerableSet.AddressSet private userSet;
    address public zc;
    address public pool;
    address public vault;

    constructor(address _zc) {
        zc = _zc;
    }

    function addUser(address _target) public onlyOwner {
        userSet.add(_target);
        emit AddUser(_target);
    }

    function removeUser(address _target) public onlyOwner {
        userSet.remove(_target);
        emit RemoveUser(_target);
    }

    function isUser(address _target) public view returns (bool) {
        return userSet.contains(_target);
    }

    function userList() public view returns (address[] memory) {
        return userSet.values();
    }

    function setPool(address _pool) public onlyOwner {
        pool = _pool;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    function setZC(address _zc) public onlyOwner {
        zc = _zc;
    }
}