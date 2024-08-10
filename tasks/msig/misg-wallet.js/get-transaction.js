// npx hardhat msig-get-encode --network <network>
task("msig-get-encode", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("MultiSigWallet");
		const Deployment = await hre.deployments.get("MultiSigWallet");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.getTransaction(3);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};