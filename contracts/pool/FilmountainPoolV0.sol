// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainAddressRegistry.sol";
import "../interfaces/IFilmountainUserRegistry.sol";
import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
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

    event Deposit(address depositer, uint256 amount);
    event Withdraw(address from, address to, uint256 amount);
    event Borrow(address borrower, uint256 amount);
    event PayInterest(address sender, uint256 amount);
    event PayPrincipal(address owner, uint256 amount);
    event SetFactory(address factory);
    
    using MathUpgradeable for uint256;

    IWFIL public wFIL;
    IFilmountainAddressRegistry public FilmountainAddressRegistry;
    IFilmountainUserRegistry public FilmountainUserRegistry;
    ISPVaultFactory public SPVaultFactory;
    uint256 public totalAssetsBorrowed;
    mapping(address => uint256) depositBalance;

    function initialize(
        address _wFIL,
        address _addrRegistry,
        address _userRegistry
    ) public initializer {
        __ERC20_init("zFIL", "zFIL");
        __ERC4626_init(IERC20Upgradeable(address(this)));
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        FilmountainAddressRegistry = IFilmountainAddressRegistry(_addrRegistry);
        FilmountainUserRegistry = IFilmountainUserRegistry(_userRegistry);
        uint256 shares = previewDeposit(6000 ether);
        _mint(msg.sender, shares);
        totalAssetsBorrowed += 6000 ether;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit() public payable nonReentrant returns (uint256 shares) {
        if (!FilmountainUserRegistry.isUser(msg.sender)) revert OnlyRegisteredUser(msg.sender);
        uint256 assets = msg.value;

        if (assets > maxDeposit(msg.sender)) revert ERC4626Overflow();
		shares = previewDeposit(assets);

		if (shares == 0) revert ERC4626ZeroShares();

        depositBalance[msg.sender] = assets;
        wFIL.deposit{value: assets}();
		_mint(msg.sender, shares);
        emit Deposit(msg.sender, assets);
    }

    function withdraw(address _from, address _to, uint256 _amount) public onlyOwner nonReentrant returns (uint256 shares) {
        if (!FilmountainUserRegistry.isUser(_from)) revert OnlyRegisteredUser(_from);
        // -- 요청 유효성 검사 --		
        shares = previewWithdraw(_amount);

		_burn(_from, shares);

        uint256 balanceWETH9 = wFIL.balanceOf(address(this));
		if (balanceWETH9 < _amount) revert InsufficientFunds();
        if (balanceWETH9 > 0) {
            wFIL.withdraw(_amount);
            SafeTransferLib.safeTransferETH(_to, _amount);
        }
        emit Withdraw(_from, _to, _amount);
    }

    function borrow(uint256 _amount) external {
        // 등록된 vault에서 실행시켰는지 확인
        if (FilmountainAddressRegistry.vault() != msg.sender) revert UnauthorizedVault();

        // -- 정보 갱신 --
        // 추가로 빌린양 갱신
        totalAssetsBorrowed += _amount;
        
        // -- 대출 --
        wFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(msg.sender, _amount);
        emit Borrow(msg.sender, _amount);
    }

    function payInterest() external payable {
        // 등록된 vault에서 실행시켰는지 확인
        if (FilmountainAddressRegistry.vault() != msg.sender) revert UnauthorizedVault();

        // -- 상환 --
        wFIL.deposit{value: msg.value}();
        emit PayInterest(msg.sender, msg.value);
    }

    function payPrincipal(address _owner) public payable onlyOwner returns (uint256 shares) {
        uint256 amount = msg.value;

        shares = previewWithdraw(amount);
		_burn(_owner, shares);

        totalAssetsBorrowed -= amount;
        SafeTransferLib.safeTransferETH(_owner, amount);
        emit PayPrincipal(_owner, amount);
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

    function totalAssets() public view override returns (uint256) {
        return wFIL.balanceOf(address(this)) + totalAssetsBorrowed;
    }

    function availableAssets() public view returns (uint256) {
        return wFIL.balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}
}