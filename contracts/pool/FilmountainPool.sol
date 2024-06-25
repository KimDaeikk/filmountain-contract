// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract FilmountainPool is ERC4626, ReentrancyGuard, Ownable {
    error OnlyRegisteredUser();

    mapping(address => uint256) public borrowedBalances;
    uint256 public totalBorrowed;
    uint256 public totalAssetsBorrowed;

    modifier onlyRegisteredUser() {
        if (!UserRegistry.isUser()) revert OnlyRegisteredUser();
        _;
    }

    constructor(IERC20 _wFIL) ERC4626(_wFIL) {}
    
    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit() public payable onlyRegisteredUser {
        require(msg.value == assets, "Mismatch between msg.value and assets");

        wFIL.deposit{value: msg.value}();

        IERC20(address(wFIL)).transfer(address(this), msg.value);
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 _amount) public onlyRegisteredUser {
        return super.withdraw(_amount, msg.sender, msg.sender);
    }

    function borrow(address _borrower, uint256 _amount) internal {
        require(_amount > 0, "Cannot borrow 0 tokens");
        require(totalAssets() >= _amount, "Insufficient collateral in the pool");
        // TODO 빌린 시간을 포함해서 struct 구성하여 기간이 지날때마다 자동으로 이자가 계산되도록

        borrowedBalances[_borrower] += _amount;
        totalAssetsBorrowed += _amount;
        _mint(msg.sender, _amount);
        asset.transfer(msg.sender, _amount);
        emit Borrow(msg.sender, _amount);
    }

    function pay(address _borrower, uint256 _amount) internal {
        require(_amount > 0, "Cannot repay 0 tokens");
        require(balanceOf(msg.sender) >= _amount, "Insufficient borrowed balance");
        // TODO 이자 포함 borrowedBalances 계산

        borrowedBalances[_borrower] -= _amount;
        totalAssetsBorrowed -= _amount;
        _burn(msg.sender, _amount);
        asset.transferFrom(msg.sender, address(this), _amount);
        emit Repay(msg.sender, _amount);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- UTILITY -=-=-=-=-=-=-=-=-=-=-=- */
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() + totalAssetsBorrowed;
    }
    
    function isBorrow(address _borrower) public view returns (bool) {
        return borrowedBalances[_borrower] > 0;
    }

    function interestOf(address _borrower) public view returns (bool) {
        // TODO interestRate 소수점 처리가 solidity에서 안되서 다른방법으로
        return borrowedBalances[_borrower] * (지난 week 개수) * interestRate;
    }

    function borrowOf(address _borrower) public view returns (uint256) {
        return borrowed + interestOf(_borrower); 
    }

    function setInterestRate(_uint256) public onlyOwner returns (bool) {
        
    }
}