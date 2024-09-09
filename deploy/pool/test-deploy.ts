import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveUpgradeableContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags Test --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // WFIL, Registry
    await deployAndSaveUpgradeableContract("Test", [], hre);
};

export default deployFunction;
deployFunction.tags = ["Test"];