// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "../interfaces/IUserRegistry.sol";

contract FilmountainPool is 
    ERC4626, 
    ReentrancyGuard, 
    Ownable 
{
    error ZeroAmount();
    error AmountMismatch();
    error NotEnoughBalance();
    error InsufficientBalancePool();
    error OnlyRegisteredUser();
    error UnauthorizedVault();

    event Borrow(address, uint256);
    event Pay(address, uint256);

    IWFIL public wFIL;
    ISPVaultFactory public SPVaultFactory;
    IUserRegistry public UserRegistry;

    struct borrowedBalance {
        uint256 amount;
        uint256 startDate;
    }

    mapping(address => borrowedBalance) public borrowedBalances;
    uint256 public totalBorrowed;
    uint256 public totalAssetsBorrowed;
    uint256 public interestRate;

    modifier onlyRegisteredUser() {
        if (!UserRegistry.isUser(msg.sender)) revert OnlyRegisteredUser();
        _;
    }

    constructor(
        address _wFIL,
        address _userRegistry
    )
    ERC4626(IWFIL(_wFIL))
    ERC20("ZFIL", "ZFIL")
    {
        wFIL = IWFIL(_wFIL);
        UserRegistry = IUserRegistry(_userRegistry);
    }
    
    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit(uint256 _amount) public payable onlyRegisteredUser returns (uint256){
        if (msg.value != _amount) revert AmountMismatch();

        wFIL.deposit{value: msg.value}();

        IERC20(address(wFIL)).transfer(address(this), msg.value);
        return super.deposit(_amount, msg.sender);
    }

    function withdraw(uint256 _amount, address _to) public onlyRegisteredUser returns (uint256) {
        // -- 요청 유효성 검사 --
        if (_amount == 0) revert ZeroAmount();
        if (_amount > super.totalAssets()) revert InsufficientBalancePool();

        // 풀에 돈 없어서 못 뽑는건 회원한테 양해구하기
        return super.withdraw(_amount, _to, msg.sender);
    }

    function borrow(uint256 _amount) external {
        // 등록된 vault에서 실행시켰는지 확인
        if (!SPVaultFactory.isRegistered(msg.sender)) revert UnauthorizedVault();
        // -- 요청 유효성 검사 --
        if (_amount == 0) revert ZeroAmount();
        // pool에 빌리기에 충분한 FIL이 있는지
        // 전체의 20%는 지급준비금
        // totalAssets : 빌려진 자금 포함 pool 전체 FIL의 양
        // super.totalAssets : 현재 pool 내의 전체 FIL의 양
        // 현재 pool에서 amount만큼 토큰을 빌려갔을 때 전체 자금의 20% 이상 남는지
        if (totalAssets() * 20 / 100 < super.totalAssets() - _amount) revert InsufficientBalancePool();

        // -- 정보 갱신 --
        borrowedBalance memory balance = borrowedBalances[msg.sender];
        // 기존에 계산되던 이자 처리
        balance.amount += interestOf(msg.sender);
        
        // 빌린 시작일, 추가로 빌린양 갱신
        balance.amount += _amount;
        balance.startDate = block.timestamp;
        totalAssetsBorrowed += _amount;
        
        // -- 대출 --
        wFIL.transfer(msg.sender, _amount);
        emit Borrow(msg.sender, _amount);
    }

    function pay(uint256 _amount) external {
        // 등록된 vault에서 실행시켰는지 확인
        if (!SPVaultFactory.isRegistered(msg.sender)) revert UnauthorizedVault();
        if (_amount == 0) revert ZeroAmount();
        if (balanceOf(msg.sender) < _amount) revert NotEnoughBalance();
        borrowedBalance memory balance = borrowedBalances[msg.sender];
        // 기존에 계산되던 이자 처리
        balance.amount += interestOf(msg.sender);

        borrowedBalances[msg.sender].amount -= _amount;
        totalAssetsBorrowed -= _amount;
        _burn(msg.sender, _amount);
        wFIL.transferFrom(msg.sender, address(this), _amount);
        emit Pay(msg.sender, _amount);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- UTILITY -=-=-=-=-=-=-=-=-=-=-=- */
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() + totalAssetsBorrowed;
    }
    
    function isBorrow(address _borrower) public view returns (bool) {
        return borrowedBalances[_borrower].amount > 0;
    }

    function interestOf(address _borrower) public view returns (uint256) {
        borrowedBalance memory balance = borrowedBalances[_borrower];
        // (빌린양 * 주간 이자율) * 지나간 총 weeks
        return (balance.amount * getInterestRate()) * (block.timestamp - balance.startDate) / 1 weeks;
    }

    function borrowOf(address _borrower) public view returns (uint256) {
        return borrowedBalances[_borrower].amount + interestOf(_borrower);
    }

    function getInterestRate() public view returns (uint256) {
        return interestRate / 1000000;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- ADMIN -=-=-=-=-=-=-=-=-=-=-=- */
    function setInterestRate(uint256 _rate) public onlyOwner {
        // ex. 1년에 40%라면 40% / 52주 = 0.767...%이므로 _rate는 767로 적용
        interestRate = _rate;
    }

    function setFactory(address _sPVaultFactory) public onlyOwner {
        SPVaultFactory = ISPVaultFactory(_sPVaultFactory);
    }

    receive() external payable {
        revert("Direct transfers not allowed");
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }
}