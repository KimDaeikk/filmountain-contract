// npx hardhat msig-get-ophash --network <network>
task("msig-get-ophash", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("WalletSimple");
		const Deployment = await hre.deployments.get("WalletSimple");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.getOperationHash("0x683791072BB8B18f465A679889480e78A00eC298", "0", "0x4437152a0000000000000000000000006e6608de293f3e737aee48d410d60904c918d9ff", 1723199240, 1, 0);
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};