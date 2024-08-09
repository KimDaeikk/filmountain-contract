// npx hardhat address-registry-transfer-ownership --address <eth address> --network <network>
task("address-registry-transfer-ownership", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;
		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		const AddressRegistryFactory = await ethers.getContractFactory("FilmountainAddressRegistry");
		const addressRegistryDeployment = await hre.deployments.get("FilmountainAddressRegistry");
		const addressRegistry = AddressRegistryFactory.attach(addressRegistryDeployment.address);

		try {
			const receipt = await addressRegistry.transferOwnership(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};