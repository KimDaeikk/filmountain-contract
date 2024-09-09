// npx hardhat msig-get-transaction --network <network>
task("msig-get-transaction", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("MultiSigWallet");
		const Deployment = await hre.deployments.get("MultiSigWallet");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.getTransaction(0);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};