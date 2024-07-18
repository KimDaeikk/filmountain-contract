// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainRegistry {
    function isUser(address _target) external view returns (bool);
    function pool() external view returns (address);
    function router() external view returns (address);
    function vault() external view returns (address);
}