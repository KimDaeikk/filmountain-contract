// npx hardhat get-owner --network calibrationnet
task("is-controlling-address", "test miner actor api is controlling address")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const control = await minerApiTest.isControllingAddress(118000, "beneficiary등 주소");

			// fil address값은 정확히 어떤 주소인지 모르겠음
			// resolveAddress로 actor ID값을 얻을 수 있다는 점만 확실
			console.log("owner address is: ", control);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};