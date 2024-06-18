// npx hardhat get-owner-id --network calibrationnet
task("get-owner-id", "test miner actor api get owner id")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const owner = await minerApiTest.getOwnerId(19572);

            // ID값은 Big Int 타입으로 리턴됨
			console.log("owner id is: ", owner);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};