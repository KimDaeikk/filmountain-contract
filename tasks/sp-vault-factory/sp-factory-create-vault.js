const { task } = require("hardhat/config");

task("sp-factory-create-vault", "create vault")
  .addParam("id", "User address")
  .setAction(async (taskArgs, hre) => {
    let { id } = taskArgs;
    const { ethers, deployments } = hre;
    const { save } = deployments
    const Factory = await ethers.getContractFactory("SPVaultFactory");
    const Deployment = await deployments.get("SPVaultFactory");
    const spFactory = Factory.attach(Deployment.address);
    const provider = new ethers.JsonRpcProvider(hre.network.config.url);
		const signer = new ethers.Wallet("672bcf690adf8dc6f3110991dc222ad6e9450479e049bcaae43cf437997c3d9c", provider);

    try {
      const tx = await spFactory.connect(signer).createVault(id);
      const receipt = await tx.wait();  // 트랜잭션이 완료될 때까지 대기

      console.log("Transaction receipt: ", receipt);

      // Check if receipt.logs is defined and extract the vault address from the CreateVault event
      if (receipt.logs) {
        const iface = new ethers.Interface([
          "event CreateVault(address vault)"
        ]);

        const log = receipt.logs.find((log) => {
          try {
            const parsedLog = iface.parseLog(log);
            return parsedLog.name === "CreateVault";
          } catch (e) {
            return false;
          }
        });

        if (log) {
          const parsedLog = iface.parseLog(log);
          const vaultAddress = parsedLog.args.vault;
          console.log("New vault address:", vaultAddress);

          const artifact = await deployments.getExtendedArtifact("SPVault");
          let contractDeployments = {
            address: vaultAddress,
            ...artifact,
          };
		      await save("SPVault", contractDeployments);
        } else {
          console.log("CreateVault event not found in receipt.logs");
        }
      } else {
        console.log("No logs found in transaction receipt");
      }
    } catch (e) {
      console.log(e);
    }
  });

module.exports = {};
