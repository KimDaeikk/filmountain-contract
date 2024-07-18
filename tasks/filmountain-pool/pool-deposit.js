// npx hardhat pool-deposit --amount <amount> --network <network>
task("pool-deposit", "add user address to registry")
	.addParam("amount", "deposit amount")
	.setAction(async (taskArgs) => {
		let { amount } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool_change_owner");
		const Deployment = await hre.deployments.get("FilmountainPool_change_owner");
		const pool = Factory.attach(Deployment.address);

		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		try {
			const receipt = await pool.connect(signer)["deposit(uint256)"](amount, { value: amount });
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};