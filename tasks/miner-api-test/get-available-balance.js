// npx hardhat get-available-balance --network calibrationnet
task("get-available-balance", "test miner actor api get owner")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const attoBalance = await minerApiTest.getAvailableBalance(118000);
            const filBalance = BigInt(attoBalance) / BigInt('1000000000000000000');

			console.log("available balance is: ", filBalance);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};