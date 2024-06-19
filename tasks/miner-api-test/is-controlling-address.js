// npx hardhat is-controlling-address --network calibrationnet
task("is-controlling-address", "test miner actor api is controlling address")
.setAction(async () => {
    const { newFromString } = require('@glif/filecoin-address');
    const { ethers, deployments } = hre;
    
    const MinerApiTestFactory = await ethers.getContractFactory("MinerApiTest");
    const MinerApiTestDeployment = await deployments.get("MinerApiTest");
		const minerApiTest = MinerApiTestFactory.attach(MinerApiTestDeployment.address);

		try {
            // Filecoin 주소
            const filecoinAddress = 't1fgnqcnwo25kv52yczu3u47vkrlqtwq5nonvv3ey';
            // 주소 변환
            const filAddress = newFromString(filecoinAddress);
            // Buffer로 변환
            const buffer = Buffer.from(filAddress.bytes);
			const control = await minerApiTest.isControllingAddress(118000, buffer);

			// fil address값은 정확히 어떤 주소인지 모르겠음
			// resolveAddress로 actor ID값을 얻을 수 있다는 점만 확실
			console.log("is controlling address?: ", control);
		} catch (e) {
			console.log(e);
        }
    });

module.exports = {};