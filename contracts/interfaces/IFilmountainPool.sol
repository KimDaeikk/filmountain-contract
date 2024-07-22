// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainPool {
    function borrow(uint256 _amount) external;
    function payInterest() external payable;
    function payPrincipal(address owner, uint256 amount) external payable;
}