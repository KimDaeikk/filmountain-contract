// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUserRegistry {
    function isUser(address _target) external view returns (bool);
}