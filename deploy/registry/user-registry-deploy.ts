import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags FilmountainUserRegistry --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("FilmountainUserRegistry", [], hre);
};

export default deployFunction;
deployFunction.tags = ["FilmountainUserRegistry"];