// npx hardhat get-owner --network calibrationnet
task("get-owner", "test miner actor api get owner")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const owner = await minerApiTest.getOwner(118000);

			console.log("owner address is: ", owner);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};