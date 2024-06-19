// npx hardhat get-beneficiary --network calibrationnet
task("get-beneficiary", "test miner actor api get beneficiary")
	.setAction(async () => {
        const { ethers, deployments } = hre;

		const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
		const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
			const beneficiary = await minerApiTest.getBeneficiary(19572);

            // 주소는 fil address 형식으로 리턴됨
			console.log("beneficiary: ", beneficiary);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};