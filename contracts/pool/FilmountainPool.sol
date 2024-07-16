// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IUserRegistry.sol";
import {IWFIL} from "../interfaces/IWFIL.sol";
import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
import {FilAddress} from "fevmate/contracts/utils/FilAddress.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract FilmountainPool is 
    Initializable,
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using FilAddress for address;

    error ERC4626Overflow();
    error ERC4626ZeroShares();
    error AmountMismatch();
    error NotEnoughBalance();
    error InsufficientBalancePool();
    error OnlyRegisteredUser();
    error UnauthorizedVault();

    event Deposit(address depositer, uint256 amount);
    event Withdraw(address owner, address to, uint256 amount);
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
        __ERC20_init("zFIL", "zFIL");
        __ERC4626_init(IERC20Upgradeable(address(this)));
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        UserRegistry = IUserRegistry(_userRegistry);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit(uint256 _amount) public payable onlyRegisteredUser nonReentrant returns (uint256 shares) {
        if (msg.value != _amount) revert AmountMismatch();
        uint256 assets = msg.value;
        address receiver = msg.sender;

        if (assets > maxDeposit(receiver)) revert ERC4626Overflow();
		shares = previewDeposit(assets);

		if (shares == 0) revert ERC4626ZeroShares();

        wFIL.deposit{value: assets}();

		_mint(receiver, shares);
        emit Deposit(receiver, _amount);
    }

    function withdraw(address _to, uint256 _amount) public onlyRegisteredUser nonReentrant returns (uint256 shares) {
        // -- 요청 유효성 검사 --
        address owner = msg.sender;
		
        shares = previewWithdraw(_amount);

		_burn(owner, shares);

		wFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(_to, _amount);
		emit Withdraw(owner, _to, _amount);
    }

    function borrow(uint256 _amount) external {
        // 등록된 vault에서 실행시켰는지 확인
        if (!SPVaultFactory.isRegistered(msg.sender)) revert UnauthorizedVault();
        // -- 요청 유효성 검사 --
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
        return totalSupply() + totalAssetsBorrowed;
    }

    function availableAssets() public view returns (uint256) {
        return totalSupply();
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

    receive() external payable {}

    fallback() external payable {
        revert("Direct transfers not allowed");
    }
}
