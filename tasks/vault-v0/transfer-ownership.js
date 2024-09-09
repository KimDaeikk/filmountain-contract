// npx hardhat vault-v0-transfer-ownership --address <eth address> --network <network>
task("vault-v0-transfer-ownership", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const poolV0 = Factory.attach(Deployment.address);

		try {
			const receipt = await poolV0.transferOwnership(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};