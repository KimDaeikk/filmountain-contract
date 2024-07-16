// npx hardhat pool-set-stable-mode --bool <bool> --network <network>
task("pool-set-stable-mode", "set pool stable mode")
	.addParam("bool", "select mode")
	.setAction(async (taskArgs) => {
		let { bool } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool");
		const Deployment = await hre.deployments.get("FilmountainPool");
		const pool = Factory.attach(Deployment.bool);

		try {
			const receipt = await pool.setStableMode(mode);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};