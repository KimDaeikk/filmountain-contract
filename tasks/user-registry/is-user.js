// npx hardhat user-registry-is-user --address <eth address> --network <network>
task("user-registry-is-user", "check address is registered")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const UserRegistryFactory = await ethers.getContractFactory("UserRegistry");
		const userRegistryDeployment = await hre.deployments.get("UserRegistry");
		const userRegistry = UserRegistryFactory.attach(userRegistryDeployment.address);

		try {
			const isUser = await userRegistry.isUser(address);
			console.log(address, "is user: ", isUser);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};