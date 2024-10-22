// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainAddressRegistry.sol";
// import "../interfaces/IFilmountainUserRegistry.sol";
// import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract FilmountainPoolV0 is 
    Initializable,
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error OnlyRegisteredUser(address user);
    error ERC4626Overflow();
    error ERC4626ZeroShares();
    error UnauthorizedVault();
    error NotEnoughBalance();
    error InsufficientFunds();
    error NotPayer();
    error NotColdMSig();

    event Deposit(address depositer, uint256 fil, uint256 zfil, uint256 hot, uint256 cold);
    event Withdraw(address from, address to, uint256 amount, uint256 gasFee);
    event Borrow(address borrower, uint256 amount);
    event PayInterest(address sender, uint256 amount);
    event PayBorrowed(uint256 amount);
    event ColdToHot(uint256 amount);
    // event SetFactory(address factory);
    
    using MathUpgradeable for uint256;

    struct lpPrincipal {
        uint256 depositPrincipal;
        uint256 expiredTimestamp;
    }

    IWFIL public wFIL;
    // IFilmountainAddressRegistry public FilmountainAddressRegistry;
    // IFilmountainUserRegistry public FilmountainUserRegistry;
    // ISPVaultFactory public SPVaultFactory;
    uint256 public totalAssetsBorrowed;
    uint256 public totalAssetsCold;
    uint256 public expireDates;
    address public payer;
    address public coldMSig;
    // 각 유저의 balance 데이터
    mapping(address => mapping(uint256 => lpPrincipal)) lpPrincipalData;
    // 각 유저의 현재 인덱스를 추적하는 mapping
    mapping(address => uint256) public lpPrincipalTotalIndex;

    function initialize(
        address _wFIL,
        // address _addrRegistry,
        // address _userRegistry
        address _payer,
        address _coldMSig
    ) public initializer {
        __ERC20_init("zFIL", "zFIL");
        __ERC4626_init(IERC20Upgradeable(address(this)));
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        expireDates = 180;
        // FilmountainAddressRegistry = IFilmountainAddressRegistry(_addrRegistry);
        // FilmountainUserRegistry = IFilmountainUserRegistry(_userRegistry);
        payer = _payer;
        coldMSig = _coldMSig;
        uint256 shares = previewDeposit(6000 ether);
        _mint(msg.sender, shares);
        totalAssetsBorrowed += 6000 ether;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit() public payable nonReentrant returns (uint256 assets, uint256 shares, uint256 hotAssets, uint256 coldAssets) {
        // if (!FilmountainUserRegistry.isUser(msg.sender)) revert OnlyRegisteredUser(msg.sender);
        uint256 assets = msg.value;

        if (assets > maxDeposit(msg.sender)) revert ERC4626Overflow();
		shares = previewDeposit(assets);

		if (shares == 0) revert ERC4626ZeroShares();
        coldAssets = assets * 7 / 10;
        hotAssets = assets - coldAssets;
        
        wFIL.deposit{value: hotAssets}();
		_mint(msg.sender, shares);
        SafeTransferLib.safeTransferETH(coldMSig, coldAssets); 
        
        totalAssetsCold += coldAssets;
        uint256 currentIndex = lpPrincipalTotalIndex[msg.sender];
        lpPrincipalData[msg.sender][currentIndex].depositPrincipal = assets;
        lpPrincipalData[msg.sender][currentIndex].expiredTimestamp = block.timestamp + expireDates * 1 days;
        emit Deposit(msg.sender, assets, shares, hotAssets, coldAssets);
    }

    function withdraw(address _from, address _to, uint256 _amount, uint256 _gasFee) public payable onlyOwner nonReentrant returns (uint256, uint256 shares) {
        // if (!FilmountainUserRegistry.isUser(_from)) revert OnlyRegisteredUser(_from);
        // -- 요청 유효성 검사 --
        // 만약 pool 내부에 withdraw시키려는 양보다 FIL이 부족하다면
        // withdraw를 실행시키면서 부족한만큼 msig에서 pool로 갚는다
        uint256 assets = msg.value;
        if (assets > 0) {
            wFIL.deposit{value: assets}();
            totalAssetsBorrowed -= assets;
        }
        shares = previewWithdraw(_amount);

		_burn(_from, shares);

        uint256 balanceWETH9 = wFIL.balanceOf(address(this));
		if (balanceWETH9 < _amount) revert InsufficientFunds();
        if (balanceWETH9 > 0) {
            wFIL.withdraw(_amount);
            SafeTransferLib.safeTransferETH(_to, _amount - _gasFee);
            SafeTransferLib.safeTransferETH(owner(), _gasFee);
        }

        return (_amount - _gasFee, shares);
        emit Withdraw(_from, _to, _amount - _gasFee, _gasFee);
    }

    function borrow(address _to, uint256 _amount) public onlyOwner returns (uint256) {
        // -- 대출 --
        wFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(_to, _amount);
        
        // -- 정보 갱신 --
        // 추가로 빌린양 갱신
        totalAssetsBorrowed += _amount;

        return _amount;
        emit Borrow(_to, _amount);
    }

    function payInterest() public payable returns (uint256) {
        if (msg.sender != payer) revert NotPayer();
        // -- 상환 --
        wFIL.deposit{value: msg.value}();
        return msg.value;
        emit PayInterest(msg.sender, msg.value);
    }

    function payBorrowed() public payable returns (uint256) {
        if (msg.sender != payer) revert NotPayer();
        uint256 amount = msg.value;

        // shares = previewWithdraw(amount);
		// _burn(_to, shares);

        wFIL.deposit{value: amount}();
        totalAssetsBorrowed -= amount;
        // SafeTransferLib.safeTransferETH(_to, amount - _gasFee);
        // SafeTransferLib.safeTransferETH(owner(), _gasFee);
        return amount;
        emit PayBorrowed(amount);
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view override returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view override returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    function setExpireDates(uint256 _days) public onlyOwner returns (uint256) {
        expireDates = _days;
        return _days;
    }

    function checkUserIndex(address _lpAddress) public view returns (uint256) {
        return lpPrincipalTotalIndex[_lpAddress];
    }

    // 원금 남은 기간
    function checkPrincipalExpired(address _userAddress, uint256 _index) public view returns (uint256) {
        // 만료된 경우
        if (block.timestamp >= lpPrincipalData[_userAddress][_index].expiredTimestamp) {
            return 0;
        // 남은 시간 반환
        } else {
            return lpPrincipalData[_userAddress][_index].expiredTimestamp - block.timestamp;  
        }
    }

    function totalAssets() public view override returns (uint256) {
        return wFIL.balanceOf(address(this)) + totalAssetsBorrowed + totalAssetsCold;
    }

    function availableAssets() public view returns (uint256) {
        return wFIL.balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {
        // cold -> hot
        if (msg.sender != coldMSig) revert NotColdMSig();
        uint256 amount = msg.value;
        wFIL.deposit{value: amount}();
        totalAssetsCold -= amount;
        emit ColdToHot(amount);
    }
}