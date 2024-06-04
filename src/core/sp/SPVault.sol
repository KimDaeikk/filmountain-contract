// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FilAddress} from "fevmate/utils/FilAddress.sol";
import {BigInts} from "filecoin-solidity/contracts/v0.8/utils/BigInts.sol";
import {MinerAPI, MinerTypes, CommonTypes} from "filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import {PrecompilesAPI} from "filecoin-solidity/contracts/v0.8/PrecompilesAPI.sol";
import {FilAddresses} from "filecoin-solidity/contracts/v0.8/utils/FilAddresses.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract SPVault is 
    ReentrancyGuard,
    Ownable
{
    using FilAddress for address;
    using MinerAPI for CommonTypes.FilActorId;
    using EnumerableSet for EnumerableSet.UintSet;

    error NotOwner(address, address);
    error InactiveActor();
    error FailToChangeOwner();

    // 특정 address가 보유한 miner actor들의 리스트
    EnumerableSet.UintSet private ownedMinerSet;
    mapping(address => EnumerableSet.UintSet) ownedMinerMap;
    // miner actor => owner, 특정 miner actor의 기존 소유자 정보
    mapping(uint64 => address) public minerOwnerMap;


    /* -=-=-=-=-=-=-=-=-=-=-=- REGISTRATION -=-=-=-=-=-=-=-=-=-=-=- */
    function addMiner(uint64 _minerId) public {
        // 로컬 변수를 struct로 관리하여 stack too deep 방지
        DataTypes.AddMinerCache memory addMinerCache;

        // -- 기존 소유자(add함수 실행자) 정보 임시 저장 --
        addMinerCache.ownerAddr = msg.sender.normalize();
		// 함수 실행자의 actor ID 가져오기
		(addMinerCache.isID, addMinerCache.msgSenderId) = addMinerCache.ownerAddr.getActorID();
        if (!addMinerCache.isID) revert InactiveActor();
        
        // -- miner actor 소유권 변경 --
        // 기존 owner가 이 컨트랙트에 changeOwnerAddress()를 먼저 실행하여 제안
        // 이 컨트랙트가 changeOwnerAddress()를 실행시키면 accept
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        CommonTypes.FilAddress memory thisFilAddress = FilAddresses.fromEthAddress(address(this).normalize());
        minerId.changeOwnerAddress(thisFilAddress);

        // -- miner actor 소유권 변경 성공 여부 검사 --
        // changeOwnerAddress() 이후 miner 소유자 주소 가져오기
        CommonTypes.FilActorId actorId = CommonTypes.FilActorId.wrap(_minerId);
		MinerTypes.GetOwnerReturn memory ownerReturn = MinerAPI.getOwner(actorId);
        // miner 소유자의 actor ID 가져오기
		addMinerCache.ownerId = PrecompilesAPI.resolveAddress(ownerReturn.owner);
        // miner actor의 소유자가 정상적으로 바뀌었는지 체크
        
        (addMinerCache.isID, addMinerCache.thisId)= address(this).normalize().getActorID();
        if (!addMinerCache.isID) revert InactiveActor();
		if (addMinerCache.ownerId != addMinerCache.thisId) revert FailToChangeOwner();

        // -- 기존 소유자 정보 저장 --
        ownedMinerMap[addMinerCache.ownerAddr].add(_minerId);
        minerOwnerMap[_minerId] = addMinerCache.ownerAddr;
    }

    function removeMiner(uint64 _minerId) public {
        DataTypes.RemoveMinerCache memory removeMinerCache;

        // 함수 실행자 정보 임시 저장
        removeMinerCache.msgSenderAddr = msg.sender.normalize();
        
        removeMinerCache.minerOwner = minerOwnerMap[_minerId].normalize();
        // -- 함수 실행자가 miner의 owner가 아니라면 revert --
        if (removeMinerCache.msgSenderAddr != removeMinerCache.minerOwner) {
            revert NotOwner(removeMinerCache.msgSenderAddr, removeMinerCache.minerOwner);
        }

        // -- 대출 중인 담보가 남아있다면 revert --
        // if () {
        //     revert ();
        // }
        
        // -- miner를 owner에게 반환 --
        // % 반환 이후 vesting, available도 owner로 넘어가는지 체크 %
        CommonTypes.FilActorId minerId = CommonTypes.FilActorId.wrap(_minerId);
        CommonTypes.FilAddress memory minerFilAddress = FilAddresses.fromActorID(_minerId);
        minerId.changeOwnerAddress(minerFilAddress);

        // -- Map에서 정보 삭제 --
        ownedMinerMap[removeMinerCache.minerOwner].remove(_minerId);
        delete minerOwnerMap[_minerId];
    }


    /* -=-=-=-=-=-=-=-=-=-=-=- SERVICE -=-=-=-=-=-=-=-=-=-=-=- */
    function borrow() public {
        // -- 대출 조건을 충족하는지 확인 --

        // -- pool의 borrow 메서드 호출 --
    }

    function pay() public {
        // -- 남은 대출이 있는지 확인 --
        
        // -- pool의 pay 메서드 호출 -- 
    }

    function withdraw(uint256 _amount) public {
        // -- Available 잔액이 있는지 확인 --
        CommonTypes.BigInt memory amount = BigInts.fromUint256(_amount);
        // -- 환금 로직 --
        // 리턴값은 환금된 amount
        // CommonTypes.BigInt memory withdrawedAmount = MinerAPI.withdrawBalance(amount);
    }

    /* -=-=-=-=-=-=-=-=-=-=-=- SETTING -=-=-=-=-=-=-=-=-=-=-=- */
    
}