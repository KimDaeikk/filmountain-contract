// npx hardhat sp-factory-is-authorized --address <eth address> --network <network>
task("sp-factory-is-authorized", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultFactory");
		const Deployment = await hre.deployments.get("SPVaultFactory");
		const spFactory = Factory.attach(Deployment.address);

		try {
			const authorized = await spFactory.isAuthorized(address);
			console.log(address, "autorized: ", authorized);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};