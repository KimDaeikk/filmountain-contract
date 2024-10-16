// npx hardhat address-registry-set-vault --network <network>
task("address-registry-set-vault", "check address is registered")
.setAction(async (taskArgs) => {
    const AddressRegistryFactory = await ethers.getContractFactory("FilmountainAddressRegistry");
    const addressRegistryDeployment = await hre.deployments.get("FilmountainAddressRegistry");
    const addressRegistry = AddressRegistryFactory.attach(addressRegistryDeployment.address);

    try {
        const poolAddress = await addressRegistry.setVault("0x004BB6Ef95836C35a6b4FEC1a9905610C004ea58");
        console.log("owner: ", poolAddress);
    } catch (e) {
        console.log(e);
    }
});

module.exports = {};