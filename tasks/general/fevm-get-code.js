const { task } = require("hardhat/config");
const { ethers } = require("ethers");
const { newDelegatedEthAddress } = require("@glif/filecoin-address");

task("fevm-get-code", "Convert Ethereum address to Filecoin address and check validity")
  .addParam("address", "The Ethereum address to convert")
  .setAction(async (taskArgs, hre) => {
    const ethAddress = taskArgs.address;

    // Convert Ethereum address to Filecoin f4 address
    const filecoinF4Address = newDelegatedEthAddress(ethAddress);
    console.log("Filecoin f4 Address:", filecoinF4Address.toString());

    // Convert f4 address to t4 address for local testnet
    const t4Address = `t4${filecoinF4Address.toString().substring(2)}`;
    console.log("Filecoin t4 Address:", t4Address);

    // Connect to Filecoin local network
    const provider = new ethers.JsonRpcProvider(hre.network.config.url);

    try {
      // Check the balance of the Filecoin t4 address
      const balance = await provider.getBalance(t4Address);
      console.log(`Balance of ${t4Address}: ${ethers.utils.formatEther(balance)} FIL`);
      
      // Check if the address is a contract
      const code = await provider.getCode(t4Address);
      if (code !== "0x") {
        console.log(`${t4Address} is a contract address`);
      } else {
        console.log(`${t4Address} is an externally owned account (EOA)`);
      }
    } catch (error) {
      console.error(`Failed to get the state of address ${t4Address}:`, error);
    }
  });

module.exports = {};
