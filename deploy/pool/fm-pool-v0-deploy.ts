import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveUpgradeableContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags FilmountainPoolV0 --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // WFIL, Registry
    await deployAndSaveUpgradeableContract("FilmountainPoolV0", [
        "0xE19420E4Faeb42c0da508B462e36D490099917ad",
        // "0x8335093c9CFC4d56a0CB24fC15B4FF2a613E38Bc", 
        "0x7359837fb1E8a411f6f85acc3D8620999707e35c"
    ], hre);
};

export default deployFunction;
deployFunction.tags = ["FilmountainPoolV0"];