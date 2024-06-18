import { Contract, ContractFactory } from "ethers";
import { DeploymentsExtension } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export const getZFIL = async (chainId: number, deployments: DeploymentsExtension): Promise<string> => {
	if (chainId == 31337 || chainId === 31415926) {
		return (await deployments.get("WFIL")).address;
	} else if (chainId == 314159) {
		return "0xaC26a4Ab9cF2A8c5DBaB6fb4351ec0F4b07356c4";
	} else if (chainId == 314) {
		return "0x60E1773636CF5E4A227d9AC24F20fEca034ee25A";
	} else {
        throw new Error(`Unsupported chainId: ${chainId}`);
    }
};

export const deployAndSaveContract = async (name: string, args: unknown[], hre: HardhatRuntimeEnvironment): Promise<void> => {
	const { ethers, deployments } = hre;
	const { save } = deployments;

	const feeData = await ethers.provider.getFeeData();

	let Factory: ContractFactory;
	Factory = await ethers.getContractFactory(name);

	let contract: Contract;

	// EIP-1559 트랜잭션 사용
	contract = await Factory.deploy(...args, {
		maxFeePerGas: feeData.maxFeePerGas || ethers.parseUnits('2', 'gwei'),
		maxPriorityFeePerGas: feeData.maxPriorityFeePerGas || ethers.parseUnits('1', 'gwei'),
		gasLimit: 150000000,
        timeout: 200000000,
	}) as Contract;
	await contract.waitForDeployment();

	const contractAddress = await contract.getAddress();
	console.log(name + " Address---> " + contractAddress);

	const artifact: any = await deployments.getExtendedArtifact(name);
	let contractDeployments = {
		address: contractAddress,
		...artifact,
	};

	await save(name, contractDeployments);
};

export const deployAndSaveUpgradeableContract = async (name: string, args: unknown[], hre: HardhatRuntimeEnvironment): Promise<void> => {
	const { ethers, deployments, upgrades } = hre;
	const { save } = deployments;

	let Factory: ContractFactory;

	Factory = await ethers.getContractFactory(name);

	let contract: Contract;

	contract = await upgrades.deployProxy(Factory, args, {
		initializer: "initialize",
		unsafeAllow: ["delegatecall"],
		kind: "uups",
		timeout: 100000000,
	});
	await contract.waitForDeployment();

	console.log(name + " Address---> " + contract.address);

	const implAddr = await contract.getImplementation();
	console.log("Implementation address for " + name + " is " + implAddr);

	const artifact: any = await deployments.getExtendedArtifact(name);
	let proxyDeployments = {
		address: contract.address,
		...artifact,
	};

	await save(name, proxyDeployments);
};