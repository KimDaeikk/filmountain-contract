// npx hardhat vault-v0-add-miner --glif <glif address> --owner <owner address> --network <network>
task("vault-v0-remove-miner", "add user address to registry")
    .addParam("glif", "glif address")
	.setAction(async (taskArgs) => {
		let { glif } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.removeMiner(glif);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};