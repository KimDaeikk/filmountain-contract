// npx hardhat get-sector-size --network calibrationnet
task("get-sector-size", "test miner actor api get sector size")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const size = await minerApiTest.getSectorSize(118000);
            // 34359738368 bytes = 1024^3(1 GB) * 32 = 32 GB
			console.log("miner sector size is: ", size);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};