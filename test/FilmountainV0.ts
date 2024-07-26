import {
    loadFixture,
    } from "@nomicfoundation/hardhat-toolbox/network-helpers";
    import { expect } from "chai";
    import hre, { ethers } from "hardhat";
    import { FilmountainRegistry, FilmountainRegistry__factory, FilmountainPoolV0, FilmountainPoolV0__factory, SPVaultV0, SPVaultV0__factory } from "../typechain-types";
    
    describe("Filmountain", function () {
        async function deployFixture() {
            const [administrator, zetacube, addr1, addr2] = await hre.ethers.getSigners();
    
            // WFIL
            const WFIL = await hre.ethers.getContractFactory("WFIL");
            const wFIL = await WFIL.deploy(administrator);
    
            // FilmountainRegistry
            const FilmountainRegistry: FilmountainRegistry__factory = await hre.ethers.getContractFactory("FilmountainRegistry");
            const filmountainRegistry: FilmountainRegistry = await FilmountainRegistry.deploy(zetacube);
    
            // FilmountainPool
            const FilmountainPoolV0: FilmountainPoolV0__factory = await hre.ethers.getContractFactory("FilmountainPoolV0");
            const filmountainPoolV0: FilmountainPoolV0 = await hre.upgrades.deployProxy(
                FilmountainPoolV0,
                [await wFIL.getAddress(), await filmountainRegistry.getAddress()],
                { initializer: "initialize"} 
            ) as unknown as FilmountainPoolV0;
    
            // SPVault
            const SPVaultV0: SPVaultV0__factory = await hre.ethers.getContractFactory("SPVaultV0");
            const sPVaultV0: SPVaultV0 = await hre.upgrades.deployProxy(
                SPVaultV0,
                [await wFIL.getAddress(), await filmountainRegistry.getAddress()],
                { 
                    initializer: "initialize",
                    unsafeAllow: ["delegatecall"]
                }
            ) as unknown as SPVaultV0;

            await filmountainRegistry.setPool(await filmountainPoolV0.getAddress());
            await filmountainRegistry.setVault(await sPVaultV0.getAddress());

            return { administrator, zetacube, addr1, addr2, wFIL, filmountainRegistry, filmountainPoolV0, sPVaultV0 };
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
    
        describe("FilmountainRegisty", function () {
            it("Set the right owner", async function () {
                const { administrator, filmountainRegistry } = await loadFixture(deployFixture);
                expect(await filmountainRegistry.owner()).to.equal(administrator.address);
            });
    
            it("Non user can't pass isUser()", async function () {
                const { addr1, filmountainRegistry } = await loadFixture(deployFixture);
                expect(await filmountainRegistry.isUser(addr1.address)).to.equal(false);
            });
    
            it("User pass isUser()", async function () {
                const { addr1, filmountainRegistry } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1.address);
                expect(await filmountainRegistry.isUser(addr1.address)).to.equal(true);
            });
    
            it("Add multiple users", async function () {
                const { addr1, addr2, filmountainRegistry } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1.address);
                await filmountainRegistry.addUser(addr2.address);
                const userList = await filmountainRegistry.userList();
                expect(userList.length).to.equal(2);
            })

            it("Remove user", async function () {
                const { addr1, addr2, filmountainRegistry } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1.address);
                await filmountainRegistry.addUser(addr2.address);
                await filmountainRegistry.removeUser(addr1.address);
                expect(await filmountainRegistry.isUser(addr1.address)).to.equal(false);
            })
        });
    
        describe("FilmountainPool", async function () {
            it("Set the right owner", async function () {
                const { administrator, filmountainPoolV0 } = await loadFixture(deployFixture);
                expect(await filmountainPoolV0.owner()).to.equal(administrator);
            });

            it("Only registered user can deposit", async function () {
                const { addr1, filmountainPoolV0 } = await loadFixture(deployFixture);
                await expect(filmountainPoolV0.connect(addr1)["deposit()"]({ value: ethers.parseEther("1")})).to.revertedWithCustomError(filmountainPoolV0, "OnlyRegisteredUser");
            });
    
            it("Deposit in pool", async function () {
                const { addr1, addr2, filmountainRegistry, filmountainPoolV0 } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1);
                await filmountainRegistry.addUser(addr2);
                await filmountainPoolV0.connect(addr1)["deposit()"]({ value: ethers.parseEther("500")});
                expect(await filmountainPoolV0.balanceOf(addr1)).to.equal(ethers.parseEther("500"));
                await filmountainPoolV0.connect(addr2)["deposit()"]({ value: ethers.parseEther("300")});
                expect(await filmountainPoolV0.balanceOf(addr1)).to.equal(ethers.parseEther("500"));
            });

            it("Only registered user can withdraw", async function () {
                const { addr1, filmountainPoolV0 } = await loadFixture(deployFixture);
                await expect(filmountainPoolV0.connect(addr1)["withdraw(uint256)"](ethers.parseEther("1"))).to.revertedWithCustomError(filmountainPoolV0, "OnlyRegisteredUser");
            });

            it("Withdraw from pool", async function () {
                const { addr1, filmountainRegistry, filmountainPoolV0 } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1.address);
                await filmountainPoolV0.connect(addr1)["deposit()"]({ value: ethers.parseEther("100")});
                await filmountainPoolV0.connect(addr1)["withdraw(uint256)"](ethers.parseEther("100"));
                expect(await filmountainPoolV0.balanceOf(addr1)).to.equal(ethers.parseEther("0"));
            })

            it("Only vault can execute pool's borrow()", async function () {
                const { filmountainPoolV0 } = await loadFixture(deployFixture);
                await expect(filmountainPoolV0.borrow(ethers.parseEther("100"))).to.revertedWithCustomError(filmountainPoolV0, "UnauthorizedVault");
            })
        });
    
        describe("SPVault", async function () {
            it("Set the right owner", async function () {
                const { administrator, sPVaultV0 } = await loadFixture(deployFixture);
                expect(await sPVaultV0.owner()).to.equal(administrator.address);
            });
        });

        describe("Vault -- Pool interaction", async function() {
            it("Vault borrow from pool", async function () {
                const { addr1, filmountainRegistry, filmountainPoolV0, sPVaultV0 } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1.address);
                await filmountainPoolV0.connect(addr1)["deposit()"]({ value: ethers.parseEther("8000")});
                await sPVaultV0.borrow(ethers.parseEther("8000"));
                expect(await ethers.provider.getBalance(await sPVaultV0.getAddress())).to.equal(ethers.parseEther("8000"));
            });

            it("Vault pay interest to pool", async function () {
                const { zetacube, addr1, addr2, wFIL, filmountainRegistry, filmountainPoolV0, sPVaultV0 } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1);
                await sPVaultV0.addMiner(addr1, addr2);
                const tx = await addr1.sendTransaction({
                    to: sPVaultV0.getAddress(),
                    value: ethers.parseEther("100"),
                });
                await tx.wait();
                const zcAmount = await ethers.provider.getBalance(zetacube) - BigInt("10000000000000000000000");
                const spAmount = await ethers.provider.getBalance(addr2) - BigInt("10000000000000000000000");
                const lpAmount = await wFIL.balanceOf(filmountainPoolV0.getAddress());
                expect(ethers.parseEther("100")).to.equal(spAmount + lpAmount + zcAmount);
            });

            // pushFund는 직접 테스트해야함

            it("Vault pay principal to user", async function () {
                const { administrator, addr1, filmountainRegistry, filmountainPoolV0, sPVaultV0 } = await loadFixture(deployFixture);
                await filmountainRegistry.addUser(addr1);
                const initialBalance = await ethers.provider.getBalance(addr1.address);
                await filmountainPoolV0.connect(addr1)["deposit()"]({ value: ethers.parseEther("1000") });
                const finalBalance = await ethers.provider.getBalance(addr1.address);
                const gasFee = (initialBalance - ethers.parseEther("1000")) - finalBalance;
                await sPVaultV0.borrow(ethers.parseEther("500"));
                await filmountainPoolV0.connect(administrator).payPrincipal(addr1, { value: ethers.parseEther("500") });
                const userBalance = await ethers.provider.getBalance(addr1) + gasFee;
                expect(await filmountainPoolV0.balanceOf(await addr1.getAddress()) + userBalance).to.equal(BigInt("10000000000000000000000"));
            });

            // it("", async function () {

            // });
        })
    });