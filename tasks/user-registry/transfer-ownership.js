// npx hardhat user-registry-transfer-ownership --address <eth address> --network <network>
task("user-registry-transfer-ownership", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;
        const [deployer] = await ethers.getSigners();

		const UserRegistryFactory = await ethers.getContractFactory("FilmountainUserRegistry", deployer);
		const userRegistryDeployment = await hre.deployments.get("FilmountainUserRegistry");
		const userRegistry = UserRegistryFactory.attach(userRegistryDeployment.address);

		try {
			const receipt = await userRegistry.transferOwnership(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};