// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SPVaultV0 is 
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function borrow() public onlyOwner {

    }

    function payInterest() public onlyOwner {
        
    }

    // GLIF가 붙은 상태에서는 원금은 pool로 직접 쏘기
    // function payPricinpal() public onlyOwner {}

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    receive() external payable {}

    fallback() external payable {
        revert("Direct transfers not allowed");
    }
}