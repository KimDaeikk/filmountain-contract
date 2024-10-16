import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveUpgradeableContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags SPVaultV0 --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveUpgradeableContract("SPVaultV0", ["0xaC26a4Ab9cF2A8c5DBaB6fb4351ec0F4b07356c4", "0xE856731E10842E3E42DE7eC11c6e65996be413b7"], hre);
};

export default deployFunction;
deployFunction.tags = ["SPVaultV0"];