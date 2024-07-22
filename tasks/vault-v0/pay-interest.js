// npx hardhat vault-v0-add-miner --glif <glif address> --owner <owner address> --network <network>
task("vault-v0-pay-interest", "add user address to registry")
    .addParam("amount", "interest amount")
	.setAction(async (taskArgs) => {
		let { amount } = taskArgs;

		const Factory = await ethers.getContractFactory("SPVaultV0");
		const Deployment = await hre.deployments.get("SPVaultV0");
		const spVault = Factory.attach(Deployment.address);

		try {
			const tx = await sender.sendTransaction({
                to: spVault.address,
                value: ethers.utils.parseEther(amount), // amount in ether
            });
            const receipt = await tx.wait();
            console.log("Transaction receipt: ", receipt);
        } catch (e) {
			console.log(e);
		}
	});

module.exports = {};