import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags SPVaultFactory --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // WFIL, pool, vault
    await deployAndSaveContract("SPVaultFactory", [
        "0x7d6C3fBfad6200E3Ff5acB61BE3B45CEE935d88c", 
        "0x2d8Cb40BBC7d029861b86EA7AcbDBAA443f74094", 
        "0x859d9A8E0551C6E4A76A5234990e5e04299E817a"
    ], hre);
};

export default deployFunction;
deployFunction.tags = ["SPVaultFactory"];