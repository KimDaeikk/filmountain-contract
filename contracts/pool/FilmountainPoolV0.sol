// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import "../interfaces/IFilmountainRegistry.sol";
import {ISPVaultFactory} from "../interfaces/ISPVaultFactory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract FilmountainPoolV0 is 
    Initializable,
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error OnlyRouter(address sender);
    error ERC4626Overflow();
    error ERC4626ZeroShares();
    error UnauthorizedVault();
    error NotEnoughBalance();

    event Deposit(address depositer, uint256 amount);
    event Withdraw(address owner, address to, uint256 amount);
    event Borrow(address borrower, uint256 amount);
    event PayInterest(address sender, uint256 amount);
    event SetFactory(address factory);
    
    IWFIL public wFIL;
    IFilmountainRegistry public FilmountainRegistry;
    ISPVaultFactory public SPVaultFactory;
    uint256 public totalAssetsBorrowed;

    constructor() initializer {}

    modifier onlyRouter() {
        if (FilmountainRegistry.router() != msg.sender) revert OnlyRouter(msg.sender);
        _;
    }

    function initialize(
        address _wFIL,
        address _registry
    ) public initializer {
        __ERC20_init("zFIL", "zFIL");
        __ERC4626_init(IERC20Upgradeable(address(this)));
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        wFIL = IWFIL(_wFIL);
        FilmountainRegistry = IFilmountainRegistry(_registry);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function deposit(address _userAddress) external payable onlyRouter nonReentrant returns (uint256 shares) {
        uint256 assets = msg.value;
        address receiver = _userAddress;

        if (assets > maxDeposit(receiver)) revert ERC4626Overflow();
		shares = previewDeposit(assets);

		if (shares == 0) revert ERC4626ZeroShares();

        wFIL.deposit{value: assets}();
		_mint(receiver, shares);
        emit Deposit(receiver, assets);
    }

    function withdraw(address _owner, address _to, uint256 _amount) external onlyRouter nonReentrant returns (uint256 shares) {
        // -- 요청 유효성 검사 --
        address owner = _owner;
		
        shares = previewWithdraw(_amount);

		_burn(owner, shares);

		wFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(_to, _amount);
		emit Withdraw(owner, _to, _amount);
    }

    function borrow(uint256 _amount) external onlyOwner {
        // 등록된 vault에서 실행시켰는지 확인
        if (FilmountainRegistry.vault() != msg.sender) revert UnauthorizedVault();

        // -- 정보 갱신 --
        // 추가로 빌린양 갱신
        totalAssetsBorrowed += _amount;
        
        // -- 대출 --
        wFIL.transfer(msg.sender, _amount);
        emit Borrow(msg.sender, _amount);
    }

    function payInterest(uint256 _amount) external onlyOwner {
        // 등록된 vault에서 실행시켰는지 확인
        if (FilmountainRegistry.vault() != msg.sender) revert UnauthorizedVault();
        if (balanceOf(msg.sender) < _amount) revert NotEnoughBalance();

        // -- 상환 --
        wFIL.transferFrom(msg.sender, address(this), _amount);
        emit PayInterest(msg.sender, _amount);
    }


    function requestPrincipal() external onlyRouter {

    }

    function approvePrincipal() public payable onlyOwner {
        // 멀티시그로 배포해서 owner가 멀티시그인 상태로 가정 
        // 원금을 돌려줄 때는 콜드월렛(멀티시그)을 이용하여 돌려줌
        uint256 amount = msg.value;
        totalAssetsBorrowed -= amount;
        
    }

    function revertPrincipal() public payable onlyOwner {
        
    }

    function totalAssets() public view override returns (uint256) {
        return totalSupply() + totalAssetsBorrowed;
    }

    function availableAssets() public view returns (uint256) {
        return totalSupply();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    receive() external payable {}

    fallback() external payable {
        revert("Direct transfers not allowed");
    }
}