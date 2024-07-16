import {
time,
loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import {FilmountainPool, FilmountainPool__factory, SPVault, SPVault__factory, SPVaultFactory, SPVaultFactory__factory} from "../typechain-types";

describe("Filmountain", function () {
    async function deployFixture() {
        const [administrator, addr1, addr2] = await hre.ethers.getSigners();

        // WFIL
        const WFIL = await hre.ethers.getContractFactory("WFIL");
        const wFIL = await WFIL.deploy(administrator);

        // UserRegistry
        const UserRegistry = await hre.ethers.getContractFactory("UserRegistry");
        const userRegistry = await UserRegistry.deploy();

        // FilmountainPool
        const FilmountainPool: FilmountainPool__factory = await hre.ethers.getContractFactory("FilmountainPool");
        const filmountainPool: FilmountainPool = await hre.upgrades.deployProxy(
            FilmountainPool,
            [await wFIL.getAddress(), await userRegistry.getAddress()],
            { initializer: "initialize" } 
        ) as unknown as FilmountainPool;

        // SPVault
        const SPVault: SPVault__factory = await hre.ethers.getContractFactory("SPVault");
        const sPVault: SPVault = await SPVault.deploy();

        // SPVaultFactory
        const SPVaultFactory: SPVaultFactory__factory = await hre.ethers.getContractFactory("SPVaultFactory");
        const sPVaultFactory: SPVaultFactory = await SPVaultFactory.deploy(await wFIL.getAddress(), await filmountainPool.getAddress(), await sPVault.getAddress());
        
        return { administrator, addr1, addr2, wFIL, userRegistry, filmountainPool, sPVaultFactory, sPVault };
    }

    describe("WFIL", function () {
        it("Set the right owner", async function () {
            const { wFIL, administrator } = await loadFixture(deployFixture);
            expect(await wFIL.owner()).to.equal(administrator.address);
        });

        it("Deposit", async function () {
            const { wFIL, addr1 } = await loadFixture(deployFixture);
            await wFIL.connect(addr1).deposit({ value: ethers.parseEther("1") });
            expect(await wFIL.balanceOf(addr1)).to.equal(ethers.parseEther("1"));
        });

        it("Withdraw", async function () {
            const { wFIL, addr1 } = await loadFixture(deployFixture);
            await wFIL.connect(addr1).deposit({ value: ethers.parseEther("1") });
            await wFIL.connect(addr1).withdraw(ethers.parseEther("1"));
            expect(await wFIL.balanceOf(addr1)).to.equal(0);
        });
    });

    describe("UserRegisty", function () {
        it("Set the right owner", async function () {
            const { administrator, userRegistry } = await loadFixture(deployFixture);
            expect(await userRegistry.owner()).to.equal(administrator.address);
        });

        it("Non user can't pass isUser()", async function () {
            const { addr1, userRegistry } = await loadFixture(deployFixture);
            expect(await userRegistry.isUser(addr1.address)).to.equal(false);
        });

        it("User pass isUser()", async function () {
            const { addr1, userRegistry } = await loadFixture(deployFixture);
            await userRegistry.addUser(addr1.address);
            expect(await userRegistry.isUser(addr1.address)).to.equal(true);
        });

        it("Add multiple users", async function () {
            const {addr1, addr2, userRegistry} = await loadFixture(deployFixture);
            await userRegistry.addUser(addr1.address);
            await userRegistry.addUser(addr2.address);
            const userList = await userRegistry.userList();
            expect(userList.length).to.equal(2);
        })
    });

    describe("FilmountainPool Deployment", async function () {
        it("Set the right owner", async function () {
            const { administrator, filmountainPool } = await loadFixture(deployFixture);
            expect(await filmountainPool.owner()).to.equal(administrator);
        });

        it("Deposit in pool", async function () {
            const { addr1, userRegistry, filmountainPool } = await loadFixture(deployFixture);
            await userRegistry.addUser(addr1.address);
            await filmountainPool.connect(addr1)["deposit(uint256)"](ethers.parseEther("1"), { value: ethers.parseEther("1")});
            expect(await filmountainPool.balanceOf(addr1)).to.equal(ethers.parseEther("1"));
        });
    });

    describe("SPVault Deployment", async function () {
        it("Can't reinitializing", async function () {
            const { sPVault } = await loadFixture(deployFixture);
            await expect(sPVault.initialize(ethers.ZeroAddress, ethers.ZeroAddress, ethers.ZeroAddress, ethers.ZeroAddress)
            ).to.be.revertedWith("Initializable: contract is already initialized");
        });
    });

    describe("SPVaultFactory Deployment", async function () {
        it("Set the right owner", async function () {
            const { administrator, sPVaultFactory } = await loadFixture(deployFixture);
            expect(await sPVaultFactory.owner()).to.equal(administrator);
        });
    });

    describe("SPVaultFactory Deployment", async function () {
        it("Deploy SPVault by createVault()", async function () {
            const { addr1, sPVaultFactory } = await loadFixture(deployFixture);
            const tx = await sPVaultFactory.connect(addr1).createVault();
            const receipt = await tx.wait();
            if (!receipt) {
                throw new Error("Transaction receipt is null");
            }
            console.log(await receipt.toJSON().logs[3])
        });
    });
});
