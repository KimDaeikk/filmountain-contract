import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../utils";

// npx hardhat deploy --tags MinerApiTest --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("MinerApiTest", [], hre);
};

export default deployFunction;
deployFunction.tags = ["MinerApiTest"];