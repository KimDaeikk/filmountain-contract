// npx hardhat vault-v0-add-miner --amount <borrow amount> --owner <owner address> --network <network>
task("vault-v0-borrow", "add user address to registry")
    .addParam("amount", "borrow amount")
	.setAction(async (taskArgs) => {
		let { amount } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const spVault = Factory.attach(Deployment.address);

		try {
			const receipt = await spVault.borrow(amount);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};