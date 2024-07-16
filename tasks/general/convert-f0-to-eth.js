const fa = require("@glif/filecoin-address");

// Hardhat task 정의
task("convert-f0-to-eth", "Converts Filecoin f0 address to Ethereum style address")
  .addParam("id", "The Filecoin f0 address to convert")
  .setAction(async (taskArgs) => {
    const ethIDAddress = fa.ethAddressFromID(taskArgs.id);
    console.log(ethIDAddress.toString());
  });

module.exports = {};