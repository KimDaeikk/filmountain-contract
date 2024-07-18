// npx hardhat pool-balance-of --address <eth address> --network <network>
task("pool-balance-of", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool_change_owner");
		const Deployment = await hre.deployments.get("FilmountainPool_change_owner");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.balanceOf(address);
			console.log("zFIL amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};