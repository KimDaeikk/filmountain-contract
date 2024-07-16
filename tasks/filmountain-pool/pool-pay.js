// npx hardhat pool-pay --amount <eth address> --network <network>
task("pool-pay", "add user address to registry")
	.addParam("amount", "pay amount")
	.setAction(async (taskArgs) => {
		let { amount } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool");
		const Deployment = await hre.deployments.get("FilmountainPool");
		const pool = Factory.attach(Deployment.address);

		try {
			const receipt = await pool.pay(amount);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};