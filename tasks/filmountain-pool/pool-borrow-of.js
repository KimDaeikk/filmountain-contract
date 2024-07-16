// npx hardhat pool-borrow-of --address <eth address> --network <network>
task("pool-borrow-of", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool");
		const Deployment = await hre.deployments.get("FilmountainPool");
		const pool = Factory.attach(Deployment.address);

		try {
			const amount = await pool.borrowOf(address);
			console.log("sp borrowed amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};