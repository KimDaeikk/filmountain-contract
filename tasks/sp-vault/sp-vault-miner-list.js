// npx hardhat sp-vault-miner-list --network <network>
task("sp-vault-miner-list", "add user address to registry")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("SPVault");
		const Deployment = await hre.deployments.get("SPVault");
		const spVault = Factory.attach(Deployment.address);

		try {
			const list = await spVault.minerList();
			console.log("vault miner list: ", list);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};