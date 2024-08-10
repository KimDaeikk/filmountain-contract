// npx hardhat msig-set-pool --network <network>
task("msig-set-pool", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("MultiSigWallet");
		const Deployment = await hre.deployments.get("MultiSigWallet");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.executeTransaction(1);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};