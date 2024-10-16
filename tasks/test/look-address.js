// npx hardhat test-look-address --network <network>
task("test-look-address", "add user address to registry")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;
		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		const Factory = await ethers.getContractFactory("Test");
		const deployment = await hre.deployments.get("Test");
		const test = Factory.attach(deployment.address);

		try {
			const receipt = await test.lookAddress();
			console.log("address: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};