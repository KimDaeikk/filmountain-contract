// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IUserRegistry.sol";

contract FilmountainPool is 
    Initializable,
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error ZeroAmount();
    error AmountMismatch();
    error NotEnoughBalance();
    error InsufficientBalancePool();
    error OnlyRegisteredUser();
    error UnauthorizedVault();

    event Deposit(uint256 amount);
    event Borrow(address, uint256);
    event Pay(address, uint256);
    event SetStableMode(bool flag);
    event SetFactory(address factory);

    IWFIL public wFIL;
    ISPVaultFactory public SPVaultFactory;
    IUserRegistry public UserRegistry;

    struct borrowedBalance {
        uint256 borrowed;
        uint256 payed;
    }

    mapping(address => borrowedBalance) public borrowedBalances;
    uint256 public totalBorrowed;
    uint256 public totalAssetsBorrowed;
    uint256 public interestRate;
    bool stable;

    modifier onlyRegisteredUser() {
        if (!UserRegistry.isUser(msg.sender)) revert OnlyRegisteredUser();
        _;
    }

    function initialize(
        address _wFIL,
        address _userRegistry
    ) public initializer {
        __ERC4626_init(IWFIL(_wFIL));
        __ERC20_init("zFIL", "zFIL");
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        UserRegistry = IUserRegistry(_userRegistry);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit(uint256 _amount) public payable onlyRegisteredUser returns (uint256) {
        if (msg.value != _amount) revert AmountMismatch();

        wFIL.deposit{value: msg.value}();

        wFIL.transfer(address(this), msg.value);
        return super.deposit(_amount, msg.sender);
    }

    function withdraw(uint256 _amount, address _to) public onlyRegisteredUser returns (uint256) {
        // -- 요청 유효성 검사 --
        if (_amount == 0) revert ZeroAmount();
        if (_amount > super.totalAssets()) revert InsufficientBalancePool();

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
        // 안정적인 상황이 되었을 때, pool에 여유자금 전체 자금의 20% 이상 남기도록
        if (stable) {
            if (totalAssets() * 20 / 100 < super.totalAssets() - _amount) revert InsufficientBalancePool();
        }

        // -- 정보 갱신 --
        // 추가로 빌린양 갱신
        borrowedBalances[msg.sender].borrowed += _amount;
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

        // -- 정보 갱신 --
        borrowedBalances[msg.sender].payed += _amount;
        totalAssetsBorrowed -= _amount;

        // -- 상환 --
        wFIL.transferFrom(msg.sender, address(this), _amount);
        emit Pay(msg.sender, _amount);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- UTILITY -=-=-=-=-=-=-=-=-=-=-=- */
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() + totalAssetsBorrowed;
    }

    function availableAssets() public view returns (uint256) {
        return super.totalAssets();
    }

    function borrowOf(address _borrower) public view returns (uint256) {
        return borrowedBalances[_borrower].borrowed;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- ADMIN -=-=-=-=-=-=-=-=-=-=-=- */
    function setStableMode(bool _flag) public onlyOwner {
        stable = _flag;
        emit SetStableMode(_flag);
    }
    
    function setFactory(address _sPVaultFactory) public onlyOwner {
        SPVaultFactory = ISPVaultFactory(_sPVaultFactory);
        emit SetFactory(_sPVaultFactory);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {
        revert("Direct transfers not allowed");
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }
}
