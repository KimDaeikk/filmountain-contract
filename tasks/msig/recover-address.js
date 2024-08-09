// npx hardhat msig-recover-address --network <network>
task("msig-recover-address", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("WalletSimple");
		const Deployment = await hre.deployments.get("WalletSimple");
		const wallet = Factory.attach(Deployment.address);
		
		try {
			const receipt = await wallet.recoverAddressFromSignature(
                "0x353997c180ed6470ee93ca931b480f28078dd3ba4b076fd2101d51a857bec31b",
                "0x37287be5c30670289ff2c5a68c5ee23326b549d325263f8fbd612c851fb7ad293ee68220df6483b2406706c9afd57a5ba5106fdfa983936f34807aaed2fe04401c"
            );
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});
    
module.exports = {};