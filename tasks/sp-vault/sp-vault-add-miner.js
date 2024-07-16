// npx hardhat sp-vault-add-miner --id <miner id> --network <network>
task("sp-vault-add-miner", "add user address to registry")
	.addParam("id", "User address")
	.setAction(async (taskArgs) => {
		let { id } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVault");
		const Deployment = await hre.deployments.get("SPVault");
		const spVault = Factory.attach(Deployment.address);
		const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

		try {
			const receipt = await spVault.connect(signer).addMiner(id);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};