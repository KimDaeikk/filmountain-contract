// npx hardhat pool-available-assets --network <network>
task("pool-available-assets", "add user address to registry")
	.setAction(async (taskArgs) => {
		const Factory = await ethers.getContractFactory("FilmountainPoolV0");
		const Deployment = await hre.deployments.get("FilmountainPoolV0");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.availableAssets();
			console.log("available amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};