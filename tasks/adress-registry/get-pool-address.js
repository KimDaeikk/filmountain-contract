// npx hardhat address-registry-get-pool --network <network>
task("address-registry-get-pool", "check address is registered")
.setAction(async (taskArgs) => {
    const AddressRegistryFactory = await ethers.getContractFactory("FilmountainAddressRegistry");
    const addressRegistryDeployment = await hre.deployments.get("FilmountainAddressRegistry");
    const addressRegistry = AddressRegistryFactory.attach(addressRegistryDeployment.address);

    try {
        const poolAddress = await addressRegistry.pool();
        console.log("pool address: ", poolAddress);
    } catch (e) {
        console.log(e);
    }
});

module.exports = {};