// npx hardhat address-registry-get-owner --network <network>
task("address-registry-get-owner", "check address is registered")
.setAction(async (taskArgs) => {
    const AddressRegistryFactory = await ethers.getContractFactory("FilmountainAddressRegistry");
    const addressRegistryDeployment = await hre.deployments.get("FilmountainAddressRegistry");
    const addressRegistry = AddressRegistryFactory.attach(addressRegistryDeployment.address);

    try {
        const poolAddress = await addressRegistry.owner();
        console.log("owner: ", poolAddress);
    } catch (e) {
        console.log(e);
    }
});

module.exports = {};