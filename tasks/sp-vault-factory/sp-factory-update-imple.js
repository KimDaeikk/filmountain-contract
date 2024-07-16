// npx hardhat sp-factory-update-imple --address <eth address> --network <network>
task("sp-factory-update-imple", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultFactory");
		const Deployment = await hre.deployments.get("SPVaultFactory");
		const spFactory = Factory.attach(Deployment.address);

		try {
			const receipt = await spFactory.updateImplementation(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};