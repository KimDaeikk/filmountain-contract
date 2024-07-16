// npx hardhat sp-factory-is-registered --address <eth address> --network <network>
task("sp-factory-is-registered", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultFactory");
		const Deployment = await hre.deployments.get("SPVaultFactory");
		const spFactory = Factory.attach(Deployment.address);

		try {
			const registered = await spFactory.isRegistered(address);
			console.log(address, " registered: ", registered);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};