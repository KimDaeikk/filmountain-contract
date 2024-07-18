// npx hardhat pool-available-assets --network <network>
task("pool-available-assets", "add user address to registry")
	.setAction(async (taskArgs) => {
		const Factory = await ethers.getContractFactory("FilmountainPool_change_owner");
		const Deployment = await hre.deployments.get("FilmountainPool_change_owner");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.availableAssets();
			console.log("available amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};