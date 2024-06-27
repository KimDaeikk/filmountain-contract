// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SPVault} from "./SPVault.sol";

contract SPVaultFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

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
        SPVault vault = new SPVault(wFIL, msg.sender, filmountainPool);
        vault.transferOwnership(msg.sender);
        // 생성된 Vault 주소 등록
        registeredVaultSet.add(address(vault));
    }

    function setAuthorized() public {}

    function values() public view returns (address[] memory) {
        return registeredVaultSet.values();
    }
}