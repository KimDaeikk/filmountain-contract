// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import "../src/core/sp/SPVault.sol";

// forge script --chain 314159 script/DeploySPVault.s.sol:DeploySPVaultScript --rpc-url $TESTNET_RPC_URL --broadcast -g 625 --skip-simulation --slow --retries 100 --verify --ehterscan-api-key
contract DeploySPVaultScript is Script {
    function setUp() public {}

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        SPVault spVault = new SPVault();
        vm.stopBroadcast();
    }

}
