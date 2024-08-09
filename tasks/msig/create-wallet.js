// npx hardhat msig-create-wallet --network <network>
task("msig-create-wallet", "get pool available balance")
	.setAction(async () => {
		const Factory = await ethers.getContractFactory("WalletFactory");
		const Deployment = await hre.deployments.get("WalletFactory");
		const walletFactory = Factory.attach(Deployment.address);
		
		try {
			const receipt = await walletFactory.createWallet([
                "0xaf846f42c2367effc37d1266c1a2f55c69e687f8", 
                "0x5dd96ca6a3c59e0cbf7c6198cc48c6497569a87f", 
                "0x8edCbdEA640d18Df98A0A1D5bd8718Af9540D2D0",
                "0x6E6608De293F3e737aeE48d410d60904c918D9FF",
            ], hre.ethers.keccak256(hre.ethers.toUtf8Bytes("zetacube")));
			console.log("receipt: ", receipt);
		} catch (e) {
			console.log(e);
		}
	});

module.exports = {};