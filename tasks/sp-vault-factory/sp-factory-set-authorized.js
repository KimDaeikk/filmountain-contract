// npx hardhat sp-factory-set-authorized --address <eth address> --network <network>
task("sp-factory-set-authorized", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultFactory");
		const Deployment = await hre.deployments.get("SPVaultFactory");
		const spFactory = Factory.attach(Deployment.address);

		try {
			const receipt = await spFactory.setAuthorized(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};