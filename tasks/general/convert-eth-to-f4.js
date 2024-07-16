const fa = require("@glif/filecoin-address");

task("convert-eth-to-f4", "Gets Filecoin f4 address and corresponding Ethereum address.")
	.addParam("address", "The Ethereum address to convert")
	.setAction(async (taskArgs) => {
		const filAddress = fa.newDelegatedEthAddress(taskArgs.address);
		console.log(filAddress.toString());
	});

module.exports = {};