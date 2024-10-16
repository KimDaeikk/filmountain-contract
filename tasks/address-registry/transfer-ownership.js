// npx hardhat address-registry-transfer-ownership --address <eth address> --network <network>
task("address-registry-transfer-ownership", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

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