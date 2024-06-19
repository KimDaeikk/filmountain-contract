// npx hardhat get-owner --network calibrationnet
task("get-vesting-funds", "test miner actor api get vesting funds")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const funds = await minerApiTest.getVestingFunds(3751);

			// fil address값은 정확히 어떤 주소인지 모르겠음
			// resolveAddress로 actor ID값을 얻을 수 있다는 점만 확실
			console.log("vesting funds: ", funds);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};