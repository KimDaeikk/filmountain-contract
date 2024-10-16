// npx hardhat address-registry-set-pool --network <network>
task("address-registry-set-pool", "check address is registered")
.setAction(async (taskArgs) => {
    const AddressRegistryFactory = await ethers.getContractFactory("FilmountainAddressRegistry");
    const addressRegistryDeployment = await hre.deployments.get("FilmountainAddressRegistry");
    const addressRegistry = AddressRegistryFactory.attach(addressRegistryDeployment.address);

    try {
        const poolAddress = await addressRegistry.setPool("0xEaBc200EA446B2d6d6ec3d48583793342a39bb7c");
        console.log("owner: ", poolAddress);
    } catch (e) {
        console.log(e);
    }
});

module.exports = {};