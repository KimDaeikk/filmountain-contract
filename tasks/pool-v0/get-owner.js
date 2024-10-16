// npx hardhat pool-v0-get-owner --network <network>
task("pool-v0-get-owner", "get pool available balance")
	.setAction(async () => {
		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		const Factory = await ethers.getContractFactory("FilmountainPoolV0");
		const Deployment = await hre.deployments.get("FilmountainPoolV0");
		const filmountainPoolV0 = Factory.attach(Deployment.address);

		try {
			const owner = await filmountainPoolV0.owner();
			console.log("owner: ", owner);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};