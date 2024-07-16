// npx hardhat user-registry-remove-user --address <eth address> --network <network>
task("user-registry-remove-user", "remove user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const UserRegistryFactory = await ethers.getContractFactory("UserRegistry");
		const userRegistryDeployment = await hre.deployments.get("UserRegistry");
		const userRegistry = UserRegistryFactory.attach(userRegistryDeployment.address);

		try {
			const receipt = await userRegistry.removeUser(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};