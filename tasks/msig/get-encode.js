// npx hardhat msig-get-encode --network <network>
task("msig-get-encode", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("WalletSimple");
		const Deployment = await hre.deployments.get("WalletSimple");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.getEncode();
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};