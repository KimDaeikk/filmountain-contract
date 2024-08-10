import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployAndSaveContract } from "../../utils";

// 안되면 여러번 시도해야함
// npx hardhat deploy --tags MultiSigWallet --network calibrationnet
const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    await deployAndSaveContract("MultiSigWallet", [[
        "0xaf846f42c2367effc37d1266c1a2f55c69e687f8", 
        "0x5dd96ca6a3c59e0cbf7c6198cc48c6497569a87f", 
        "0x8edCbdEA640d18Df98A0A1D5bd8718Af9540D2D0",
        "0x6E6608De293F3e737aeE48d410d60904c918D9FF",
    ], 2], hre);
};

export default deployFunction;
deployFunction.tags = ["MultiSigWallet"];