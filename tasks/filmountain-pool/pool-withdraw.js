// npx hardhat pool-withdraw --amount <amount> --to <to> --network <network>
task("pool-withdraw", "add user address to registry")
	.addParam("amount", "Withdraw amount")
	.addParam("to", "Send to")
	.setAction(async (taskArgs) => {
		let { amount, to } = taskArgs;

		const Factory = await ethers.getContractFactory("FilmountainPool");
		const Deployment = await hre.deployments.get("FilmountainPool");
		const pool = Factory.attach(Deployment.address);

		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);
		console.log(signer.address)

		try {
			const receipt = await pool.connect(signer).withdraw(to, amount);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};