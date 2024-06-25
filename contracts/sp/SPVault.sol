// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IWFIL} from "../interfaces/IWFIL.sol";
import {FilAddress} from "fevmate/contracts/utils/FilAddress.sol";
import {BigInts} from "filecoin-solidity-api/contracts/v0.8/utils/BigInts.sol";
import {FilAddresses} from "filecoin-solidity-api/contracts/v0.8/utils/FilAddresses.sol";
import {PrecompilesAPI} from "filecoin-solidity-api/contracts/v0.8/PrecompilesAPI.sol";
import {SendAPI} from "filecoin-solidity-api/contracts/v0.8/SendAPI.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity-api/contracts/v0.8/MinerAPI.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

contract SPVault is 
    ReentrancyGuard,
    Ownable
{
    using FilAddress for address;
    using MinerAPI for CommonTypes.FilActorId;
    using EnumerableSet for EnumerableSet.UintSet;

    error InactiveActor();
    error InvalidProposed();
    error FailToChangeOwner();
    error NotOwnedMiner();
    error NotEnoughBalance(uint256);
    error BigNumConversion();
    error IncorrectWithdrawal();

    IWFIL public WFIL;

    // 보유한 miner actor들의 리스트
    EnumerableSet.UintSet private ownedMinerSet;
    address operator;

    constructor(address _wFIL, address _operator) {
        WFIL = IWFIL(_wFIL);
        operator = _operator;
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- REGISTRATION -=-=-=-=-=-=-=-=-=-=-=- */
    function addMiner(uint64 _minerId) public onlyOwner {
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

        // -- beneficiary 주소를 Vault contract로 변경 --

        // -- 추가된 miner 정보 저장 --
        ownedMinerSet.add(_minerId);
    }

    function removeMiner(uint64 _minerId) public onlyOwner {
        DataTypes.RemoveMinerCache memory removeMinerCache;

        // -- Vault에 맡긴 miner가 아니라면 revert --
        if(!ownedMinerSet.contains(_minerId)) revert NotOwnedMiner();

        // -- 해당 miner로 대출 중인 담보가 남아있다면 revert --
        // if () {
        //     revert ();
        // }
        
        // -- miner를 기존 owner에게 반환 --
        // % 반환 이후 vesting, available도 owner로 넘어가는지 체크 %
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        CommonTypes.FilAddress memory minerFilAddress = FilAddresses.fromActorID(_minerId);
        minerId.changeOwnerAddress(minerFilAddress);

        // -- 배열에서 정보 삭제 --
        ownedMinerSet.remove(_minerId);
    }


    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function borrow() public onlyOwner {
        // -- 대출 조건을 충족하는지 확인 --

        // -- pool의 borrow 메서드 호출 --
    }

    function pay() public onlyOwner {
        // -- 남은 대출이 있는지 확인 --
        
        // -- pool의 pay 메서드 호출 -- 
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        uint256 balanceWETH9 = WFIL.balanceOf(address(this));
        // -- 꺼내려는 양이 wFIL balance 보다 많은지 체크 --
		if (_amount > balanceWETH9) revert IncorrectWithdrawal();

        // -- wFIL를 FIL로 unwrapping하고 miner로 전송 --
		WFIL.withdraw(_amount);
        SafeTransferLib.safeTransferETH(_to, _amount);
    }

    function pullFund(uint64 _minerId, uint256 _amount) public onlyOwner {
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
        WFIL.deposit{value: pullFundCache.withdrawn}();
    }

    function pushFund(uint64 _minerId, uint256 _amount) public onlyOwner {
        uint256 balanceWETH9 = WFIL.balanceOf(address(this));
        // -- 꺼내려는 양이 wFIL balance 보다 많은지 체크 --
		if (_amount > balanceWETH9) revert IncorrectWithdrawal();

        // -- wFIL를 FIL로 unwrapping하고 miner로 전송 --
		WFIL.withdraw(_amount);
		SendAPI.send(CommonTypes.FilActorId.wrap(_minerId), _amount);
    }
}