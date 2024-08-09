import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags MultiSigWalletFactory --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("WalletFactory", ["0xc0C9E4A24AaA642491A8583ba381ceb92c2982D6"], hre);
};

export default deployFunction;
deployFunction.tags = ["MultiSigWalletFactory"];