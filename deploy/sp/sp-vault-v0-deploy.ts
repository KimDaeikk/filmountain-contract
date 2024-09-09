import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveUpgradeableContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags SPVaultV0 --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveUpgradeableContract("SPVaultV0", ["0xE19420E4Faeb42c0da508B462e36D490099917ad", "0x8335093c9CFC4d56a0CB24fC15B4FF2a613E38Bc"], hre);
};

export default deployFunction;
deployFunction.tags = ["SPVaultV0"];