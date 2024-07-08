// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import {IFilmountainPool} from "../interfaces/IFilmountainPool.sol";
import {FilAddress} from "fevmate/contracts/utils/FilAddress.sol";
import {BigInts} from "filecoin-solidity-api/contracts/v0.8/utils/BigInts.sol";
import {FilAddresses} from "filecoin-solidity-api/contracts/v0.8/utils/FilAddresses.sol";
import {PrecompilesAPI} from "filecoin-solidity-api/contracts/v0.8/PrecompilesAPI.sol";
import {SendAPI} from "filecoin-solidity-api/contracts/v0.8/SendAPI.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract SPVault is 
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using FilAddress for address;
    using MinerAPI for CommonTypes.FilActorId;
    using EnumerableSet for EnumerableSet.UintSet;

    error Unauthorized();
    error OwedMiner();
    error InactiveActor();
    error InvalidProposed();
    error FailToChangeOwner();
    error NotOwnedMiner();
    error NotEnoughBalance(uint256);
    error BigNumConversion();
    error IncorrectWithdrawal();
    error OnlyFactory();

    event AddMiner(address vault, uint64 minerId);
    event RemoveMiner(address vault, uint64 minerId);
    event Borrow(address borrower, uint256 amount);
    event Pay(address payer, uint256 amount);
    event Withdraw(address to, uint256 amount);
    event PullFund(uint64 minerId, uint256 amount);
    event PushFund(uint64 minerId, uint256 amount);
    event SetAuthorized(bool flag);

    IWFIL public wFIL;
    IFilmountainPool public FilmountainPool;

    // 보유한 miner actor들의 리스트
    EnumerableSet.UintSet private ownedMinerSet;
    address factory;
    address inc;
    bool approve;

    constructor() initializer {}

    function initialize(address _wFIL, address _ZC, address _owner, address _filmountainPool) initializer public {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        transferOwnership(_owner);
        wFIL = IWFIL(_wFIL);
        ZC = _ZC;
        factory = msg.sender;
        FilmountainPool = IFilmountainPool(_filmountainPool);
        approve = false;
    }

    modifier authorized() {
        if (!approve) revert Unauthorized();
        _;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- REGISTRATION -=-=-=-=-=-=-=-=-=-=-=- */
    function addMiner(uint64 _minerId) public onlyOwner authorized {
        // 로컬 변수를 struct로 관리하여 stack too deep 방지
        DataTypes.AddMinerCache memory addMinerCache;
        
        // -- proposed 된 주소가 Vault 컨트랙트 주소가 맞는지 체크 --
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        // 현재 owner 주소와 proposed 주소 가져오기
        (, MinerTypes.GetOwnerReturn memory ownerReturn) = MinerAPI.getOwner(minerId);
        (addMinerCache.isID, addMinerCache.thisId) = address(this).normalize().getActorID();
        addMinerCache.proposedId = PrecompilesAPI.resolveAddress(ownerReturn.proposed);
        if (addMinerCache.proposedId != addMinerCache.thisId) revert InvalidProposed();

        // -- miner actor 소유권 변경 --
        // 기존 owner가 이 컨트랙트에 changeOwnerAddress()를 먼저 실행하여 제안
        // 이 컨트랙트가 changeOwnerAddress()를 실행시키면 accept
        CommonTypes.FilAddress memory thisFilAddress = FilAddresses.fromEthAddress(address(this).normalize());
        minerId.changeOwnerAddress(thisFilAddress);

        // -- miner actor 소유권 변경 성공 여부 검사 --
        // changeOwnerAddress() 이후 miner 소유자 주소 가져오기
        (,ownerReturn) = MinerAPI.getOwner(minerId);
        // miner 소유자의 actor ID 가져오기
        addMinerCache.ownerId = PrecompilesAPI.resolveAddress(ownerReturn.owner);
        // miner actor의 소유자가 정상적으로 바뀌었는지 체크
        if (!addMinerCache.isID) revert InactiveActor();
        if (addMinerCache.ownerId != addMinerCache.thisId) revert FailToChangeOwner();

        // -- 추가된 miner 정보 저장 --
        ownedMinerSet.add(_minerId);
        emit AddMiner(address(this), _minerId);
    }

    function removeMiner(uint64 _minerId) public onlyOwner authorized {
        // -- Vault에 맡긴 miner가 아니라면 revert --
        if(!ownedMinerSet.contains(_minerId)) revert NotOwnedMiner();
        
        // -- miner를 기존 owner에게 반환 --
        // % 반환 이후 vesting, available도 owner로 넘어가는지 체크 %
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        CommonTypes.FilAddress memory minerFilAddress = FilAddresses.fromActorID(_minerId);
        minerId.changeOwnerAddress(minerFilAddress);

        // -- 배열에서 정보 삭제 --
        ownedMinerSet.remove(_minerId);
        emit RemoveMiner(address(this), _minerId);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function borrow(uint256 _amount) public onlyOwner authorized {
        // -- 대출 조건을 충족하는지 확인 --
        // Vault 생성자만 실행 가능
        // factory에서 authorized되어야 실행 가능(Vault를 생성해서 아무나 빌려가면 안되므로)

        // -- pool의 borrow 메서드 호출 --
        FilmountainPool.borrow(_amount);
        emit Borrow(msg.sender, _amount);
    }

    function pay(uint256 _amount) public onlyOwner {
        // -- pool로 40% 전송 --
        uint256 amountToPool = _amount * 40 / 100;
        wFIL.deposit{value: amountToPool}();
        wFIL.approve(address(FilmountainPool), amountToPool);
        FilmountainPool.pay(amountToPool);
        
        // -- 나머지 20% 전송 --
        uint256 amountToZC = (_amount - amountToPool) * 20 / 100;
        SafeTransferLib.safeTransferETH(ZC, amountToZC);
        // -- SP의 몫 --
        emit Pay(msg.sender, _amount);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner authorized {
        uint256 balanceWETH9 = wFIL.balanceOf(address(this));
        // -- 꺼내려는 양이 wFIL balance 보다 많은지 체크 --
        if (_amount > balanceWETH9) revert IncorrectWithdrawal();

        // -- wFIL를 FIL로 unwrapping하고 miner로 전송 --
        wFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(_to, _amount);
        emit Withdraw(_to, _amount);
    }

    function pullFund(uint64 _minerId, uint256 _amount) public onlyOwner authorized {
        DataTypes.pullFundCache memory pullFundCache;
        // -- Available 잔액이 충분한지 확인 --
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        (, CommonTypes.BigInt memory bigBalance) = MinerAPI.getAvailableBalance(minerId);
        (pullFundCache.balance, pullFundCache.abort) = BigInts.toUint256(bigBalance);
        if (pullFundCache.abort) revert BigNumConversion();
        if (_amount > pullFundCache.balance) revert NotEnoughBalance(pullFundCache.balance);

        // -- miner available에서 FIL 꺼내기 --
        (, CommonTypes.BigInt memory withdrawnBInt) = MinerAPI.withdrawBalance(
            CommonTypes.FilActorId.wrap(_minerId),
            BigInts.fromUint256(_amount)
        );
        // 제대로 꺼내졌는지 검사
        (pullFundCache.withdrawn, pullFundCache.abort) = BigInts.toUint256(withdrawnBInt);
        if (pullFundCache.abort) revert BigNumConversion();
        if (pullFundCache.withdrawn != _amount) revert IncorrectWithdrawal();

        // -- miner available에서 꺼내온 FIL을 wFIL로 wrapping --
        wFIL.deposit{value: pullFundCache.withdrawn}();
        emit PullFund(_minerId, _amount);
    }

    function pushFund(uint64 _minerId, uint256 _amount) public onlyOwner authorized {
        uint256 balanceWETH9 = wFIL.balanceOf(address(this));
        // -- 꺼내려는 양이 wFIL balance 보다 많은지 체크 --
        if (_amount > balanceWETH9) revert IncorrectWithdrawal();

        // -- wFIL를 FIL로 unwrapping하고 miner로 전송 --
        wFIL.withdraw(_amount);
        SendAPI.send(CommonTypes.FilActorId.wrap(_minerId), _amount);
        emit PushFund(_minerId, _amount);
    }

    function setAuthorized(bool _flag) external {
        if (msg.sender != factory) revert OnlyFactory();
        approve = _flag;
        emit SetAuthorized(_flag);
    }

    function minerList() public view returns (uint256[] memory) {
        return ownedMinerSet.values();
    }

    // 필요한 경우 UUPS 업그레이드 가능 기능을 위한 authorizeUpgrade 함수
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
