// npx hardhat sp-factory-vault-list --address <eth address> --network <network>
task("sp-factory-vault-list", "add user address to registry")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("SPVaultFactory");
		const Deployment = await hre.deployments.get("SPVaultFactory");
		const spFactory = Factory.attach(Deployment.address);

		try {
			const list = await spFactory.vaultList();
			console.log("vault list: ", list);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};