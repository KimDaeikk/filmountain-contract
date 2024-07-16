// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISPVault_change_owner {
    error Unauthorized();
    error OwedMiner();
    error NotOwnedMiner();
    error IncorrectWithdrawal();
    error OnlyFactory();
    error FailToGetOwner(int256 errorCode);
    error InactiveActor();
    error InvalidProposed();
    error FailToChangeOwner();
    error BigNumConversion();
    error NotEnoughBalance(uint256);

    event AddMiner(address vault, uint64 minerId);
    event RemoveMiner(address vault, uint64 minerId);
    event Borrow(address borrower, uint256 amount);
    event Pay(address payer, uint256 amount);
    event Withdraw(address to, uint256 amount);
    event PullFund(uint64 minerId, uint256 amount);
    event PushFund(uint64 minerId, uint256 amount);
    event SendPrincipal(uint256 amountToPool);
    event SetAuthorized(bool flag);
}