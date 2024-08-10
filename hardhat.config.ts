import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";
import "./tasks";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY) {
    throw new Error("Please set your PRIVATE_KEY in a .env file");
}

const config: HardhatUserConfig = {
    solidity: {
		compilers: [
			{
				version: "0.8.18",
				settings: {
					optimizer: {
						enabled: true,
						runs: 0,
						details: {
							yul: false,
							constantOptimizer: true,
						},
					},
				},
			},
			{
				version: "0.8.19",
				settings: {
					optimizer: {
						enabled: true,
						runs: 0,
						details: {
							yul: false,
							constantOptimizer: true,
						},
					},
				},
			},
		],
	},
	defaultNetwork: "hardhat",
    networks: {
        hardhat:{},
        localnet: {
			url: "http://127.0.0.1:1234/rpc/v1",
			chainId: 31415926,
			accounts: [PRIVATE_KEY],
			saveDeployments: true,
			// gasPrice: 100000000,
			// gasMultiplier: 8000,
			live: true,
		},
        calibrationnet: {
            chainId: 314159,
            url: "http://192.168.0.14:1234/rpc/v1",
            accounts: [PRIVATE_KEY],
            live: true,
			saveDeployments: true,
			timeout: 2600000,
        },
        filecoinmainnet: {
            chainId: 314,
            url: "https://api.node.glif.io",
            accounts: [PRIVATE_KEY],
            live: true,
			saveDeployments: true,
			timeout: 2600000,
        },
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
};

export default config;
