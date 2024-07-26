// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFilmountainUserRegistry {
    function isUser(address _target) external view returns (bool);
}