// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Test is 
    OwnableUpgradeable,
    UUPSUpgradeable
{
    mapping(uint256 => address) addrmap;
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function deposit() external payable {
        addrmap[0] = msg.sender;
    }

    function lookAddress() external view returns (address) {
        return addrmap[0];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}