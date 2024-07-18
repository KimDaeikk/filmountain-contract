// npx hardhat pool-set-factory --address <eth address> --network <network>
task("pool-set-factory", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool_change_owner");
		const Deployment = await hre.deployments.get("FilmountainPool_change_owner");
		const pool = Factory.attach(Deployment.address);

		try {
			const receipt = await pool.setFactory(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};