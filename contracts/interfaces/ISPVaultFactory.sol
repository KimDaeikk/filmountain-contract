// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISPVaultFactory {
    function isRegistered(address) external view returns (bool);
}