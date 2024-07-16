// npx hardhat sp-vault-remove-miner --address <eth address> --network <network>
task("sp-vault-remove-miner", "add user address to registry")
	.addParam("id", "User address")
	.setAction(async (taskArgs) => {
		let { id } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVault");
		const Deployment = await hre.deployments.get("SPVault");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.removeMiner(id);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};