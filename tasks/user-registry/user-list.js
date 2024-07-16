// npx hardhat user-registry-user-list --network <network>
task("user-registry-user-list", "get registered user list")
	.setAction(async () => {
		const UserRegistryFactory = await ethers.getContractFactory("UserRegistry");
		const userRegistryDeployment = await hre.deployments.get("UserRegistry");
		const userRegistry = UserRegistryFactory.attach(userRegistryDeployment.address);

		try {
			const userList = await userRegistry.userList();
			console.log("user list: ", userList);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};