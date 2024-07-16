import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags WFIL --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("WFIL", ["0x8edCbdEA640d18Df98A0A1D5bd8718Af9540D2D0"], hre);
};

export default deployFunction;
deployFunction.tags = ["WFIL"];