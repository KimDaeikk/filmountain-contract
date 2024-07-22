// npx hardhat vault-v0-add-miner --glif <glif address> --owner <owner address> --network <network>
task("vault-v0-push-fund", "add user address to registry")
    .addParam("minerId", "miner id")
	.addParam("amount", "fil amount")
	.setAction(async (taskArgs) => {
		let { minerId, amount } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.pushFund(minerId, amount);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};