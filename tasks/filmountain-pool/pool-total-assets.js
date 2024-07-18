// npx hardhat pool-total-assets --network <network>
task("pool-total-assets", "add user address to registry")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("FilmountainPool_change_owner");
		const Deployment = await hre.deployments.get("FilmountainPool_change_owner");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.totalAssets();
			console.log("total asset amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};