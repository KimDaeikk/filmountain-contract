// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataTypes {
    struct AddMinerCache {
		address ownerAddr;
		bool isID;
        uint64 thisId;
		uint64 sectorSize;
        uint64 proposedId;
		uint64 ownerId;
		uint64 msgSenderId;
        bytes actorIDBytes;
    }

    struct PullFundCache {
        uint256 balance;
        uint256 withdrawn;
        bool abort;
    }
}