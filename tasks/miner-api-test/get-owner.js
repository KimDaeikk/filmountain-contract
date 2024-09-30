// npx hardhat get-owner --network calibrationnet
task("get-owner", "test miner actor api get owner")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const owner = await minerApiTest.getOwner(19572);

			// fil address값은 정확히 어떤 주소인지 모르겠음
			// resolveAddress로 actor ID값을 얻을 수 있다는 점만 확실
			console.log("owner address is: ", owner);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};