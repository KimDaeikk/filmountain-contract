// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainPool {
    function deposit(address _userAddress) external;
    function withdraw(address _owner, address _to, uint256 _amount) external;
    function borrow(uint256 _amount) external;
    function payInterest(uint256 _amount) external;
}