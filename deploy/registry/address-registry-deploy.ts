import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags FilmountainAddressRegistry --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("FilmountainAddressRegistry", ["0x0A98EB5471779f1a22377d5DD492b8433aA950D5"], hre);
};

export default deployFunction;
deployFunction.tags = ["FilmountainAddressRegistry"];