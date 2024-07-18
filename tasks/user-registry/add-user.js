// npx hardhat user-registry-add-user --address <eth address> --network <network>
task("user-registry-add-user", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;
		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		const UserRegistryFactory = await ethers.getContractFactory("UserRegistry");
		const userRegistryDeployment = await hre.deployments.get("UserRegistry");
		const userRegistry = UserRegistryFactory.attach(userRegistryDeployment.address);

		try {
			const receipt = await userRegistry.addUser(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};