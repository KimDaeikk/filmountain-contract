// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainRegistry.sol";
import "../interfaces/IFilmountainPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FilmountainPoolV0Router is 
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error OnlyRegisteredUser();

    IWFIL public wFIL;
    IFilmountainRegistry public FilmountainRegistry;
    
    constructor() initializer {}

    function initialize(
        address _wFIL,
        address _registry
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        FilmountainRegistry = IFilmountainRegistry(_registry);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}