// npx hardhat sp-vault-push-fund --address <eth address> --network <network>
task("sp-vault-push-fund", "add user address to registry")
	.addParam("address", "User address")
	.setAction(async (taskArgs) => {
		let { address } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVault");
		const Deployment = await hre.deployments.get("SPVault");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.pushFund(address);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};