// npx hardhat vault-v0-add-miner --glif <glif address> --owner <owner address> --network <network>
task("vault-v0-add-miner", "add user address to registry")
    .addParam("glif", "glif address")
	.addParam("owner", "owner address")
	.setAction(async (taskArgs) => {
		let { glif, owner } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.addMiner(glif, owner);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};