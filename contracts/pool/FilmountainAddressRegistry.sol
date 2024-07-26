// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FilmountainAddressRegistry is Ownable {
    address public zc;
    address public pool;
    address public vault;

    constructor(address _zc) {
        zc = _zc;
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