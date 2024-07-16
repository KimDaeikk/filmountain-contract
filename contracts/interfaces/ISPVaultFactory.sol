// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISPVaultFactory {
    event CreateVault(address vault);
    event SetAuthorized(address target);

    function isRegistered(address) external view returns (bool);
    function isAuthorized(address) external view returns (bool);
}