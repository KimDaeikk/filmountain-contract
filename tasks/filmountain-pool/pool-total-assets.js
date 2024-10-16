// npx hardhat pool-total-assets --network <network>
task("pool-total-assets", "add user address to registry")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("FilmountainPoolV0");
		const Deployment = await hre.deployments.get("FilmountainPoolV0");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.totalAssets();
			console.log("total asset amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};