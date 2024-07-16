// npx hardhat wfil-balance-of --address <eth address> --network <network>
task("wfil-balance-of", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("WFIL");
		const Deployment = await hre.deployments.get("WFIL");
		const wfil = Factory.attach(Deployment.address);

		try {
			const amount = await wfil.balanceOf(address);
			console.log("wFIL amount: ", amount);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};