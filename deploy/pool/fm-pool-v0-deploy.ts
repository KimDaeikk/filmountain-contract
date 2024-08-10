import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveUpgradeableContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags FilmountainPoolV0 --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // WFIL, Registry
    await deployAndSaveUpgradeableContract("FilmountainPoolV0", ["0x7d6C3fBfad6200E3Ff5acB61BE3B45CEE935d88c", "0xfFbDBE284855de09E05d1ea51efFe39B51302098", "0xfFbDBE284855de09E05d1ea51efFe39B51302098"], hre);
};

export default deployFunction;
deployFunction.tags = ["FilmountainPoolV0"];