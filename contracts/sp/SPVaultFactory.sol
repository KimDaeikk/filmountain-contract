// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SPVault} from "./SPVault.sol";

contract SPVaultFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event CreateVault(address vault);
    event SetAuthorized(address target, bool flag);

    EnumerableSet.AddressSet private registeredVaultSet;
    address wFIL;
    address filmountainPool;

    constructor(
        address _wFIL,
        address _filmountainPool
    ) {
        wFIL = _wFIL;
        filmountainPool = _filmountainPool;
    }

    function isRegistered(address _target) public view returns (bool) {
        return registeredVaultSet.contains(_target);
    }

    function createVault() public {
        // Vault 컨트랙트 생성
        SPVault vault = new SPVault(wFIL, owner(), msg.sender, filmountainPool);
        vault.transferOwnership(msg.sender);
        // 생성된 Vault 주소 등록
        registeredVaultSet.add(address(vault));
        emit CreateVault(address(vault));
    }

    function setAuthorized(address _target, bool _flag) public onlyOwner {
        // 누구나 createVault로 vault를 생성할 수 있지만
        // factory owner가 authorize한 vault만 pool에서 빌려올 수 있음
        SPVault(_target).setAuthorized(_flag);
        emit SetAuthorized(_target, _flag);
    }

    function vaultList() public view returns (address[] memory) {
        return registeredVaultSet.values();
    }
}