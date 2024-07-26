// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainAddressRegistry {
    function zc() external view returns (address);
    function pool() external view returns (address);
    function vault() external view returns (address);
}