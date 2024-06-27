// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainPool {
    function borrow(uint256 _amount) external;
    function pay(uint256 _amount) external;
    function isBorrow() external view returns (bool);
}