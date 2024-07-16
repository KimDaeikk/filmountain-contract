// npx hardhat sp-vault-owner --network <network>
task("sp-vault-owner", "get owner address")
	.setAction(async (taskArgs) => {
		const Factory = await ethers.getContractFactory("SPVault");
		const Deployment = await hre.deployments.get("SPVault");
		const spVault = Factory.attach(Deployment.address);
		
		try {
			const owner = await spVault.owner();
			console.log("owner address: ", owner);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};