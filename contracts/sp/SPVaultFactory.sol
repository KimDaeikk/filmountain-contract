// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import "../interfaces/ISPVaultFactory.sol";
// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {SPVault_change_owner} from "./SPVault_change_owner.sol";
// import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

// contract SPVaultFactory is ISPVaultFactory, Ownable {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private registeredVaultSet;
//     EnumerableSet.AddressSet private AuthorizedVaultSet;
//     address public wFIL;
//     address public filmountainPool;
//     address public spVaultImplementation;

//     constructor(
//         address _wFIL,
//         address _filmountainPool,
//         address _spVaultImplementation
//     ) {
//         wFIL = _wFIL;
//         filmountainPool = _filmountainPool;
//         spVaultImplementation = _spVaultImplementation;
//     }

//     function isRegistered(address _target) public view returns (bool) {
//         return registeredVaultSet.contains(_target);
//     }

//     function createVault(uint64 _ownerId) public returns (address vault) {
//         // Create clone of the SPVault implementation
//         vault = Clones.clone(spVaultImplementation);
//         SPVault_change_owner(vault).initialize(wFIL, owner(), msg.sender, filmountainPool, _ownerId);

//         // Register the created Vault address
//         registeredVaultSet.add(vault);
//         emit CreateVault(vault);
//     }

//     function setAuthorized(address _target) public onlyOwner {
//         // Anyone can create a Vault via createVault, but only authorized Vaults can borrow from the pool
//         AuthorizedVaultSet.add(_target);
//         emit SetAuthorized(_target);
//     }

//     function isAuthorized(address _target) public view returns (bool) {
//         return AuthorizedVaultSet.contains(_target);
//     }

//     function vaultList() public view returns (address[] memory) {
//         return registeredVaultSet.values();
//     }

//     function updateSPVaultImplementation(address _newImplementation) external onlyOwner {
//         spVaultImplementation = _newImplementation;
//     }
// }