import { describe, it, before } from "node:test";
import { expect } from "chai";
import hre from "hardhat";
import type { Address } from "viem";

/**
 * Test Suite cho FoodTraceability Smart Contract
 * Chạy: npx hardhat test
 */
describe("FoodTraceability Contract", function () {
    let contractAddress: Address;
    let adminAccount: Address;
    let farmerAccount: Address;
    let manufacturerAccount: Address;
    let distributorAccount: Address;
    let retailerAccount: Address;

    before(async function () {
        // Lấy các test accounts
        const [admin, farmer, manufacturer, distributor, retailer] = await hre.viem.getWalletClients();

        adminAccount = admin.account.address;
        farmerAccount = farmer.account.address;
        manufacturerAccount = manufacturer.account.address;
        distributorAccount = distributor.account.address;
        retailerAccount = retailer.account.address;

        // Deploy contract
        const contract = await hre.viem.deployContract("FoodTraceability");
        contractAddress = contract.address;

        console.log(`\n✅ Contract deployed at: ${contractAddress}`);
        console.log(`👤 Admin: ${adminAccount}`);
    });

    describe("Deployment", function () {
        it("Should set the deployer as admin", async function () {
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress);
            const admin = await contract.read.admin();
            expect(admin.toLowerCase()).to.equal(adminAccount.toLowerCase());
        });

        it("Should initialize product counter to 0", async function () {
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress);
            const counter = await contract.read.productCounter();
            expect(counter).to.equal(0n);
        });
    });

    describe("Participant Management", function () {
        it("Should allow admin to add a farmer", async function () {
            const [admin] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: admin }
            });

            await contract.write.addParticipant([
                farmerAccount,
                "Nông trại Đà Lạt",
                1 // Role.Farmer
            ]);

            const participant = await contract.read.getParticipant([farmerAccount]);
            expect(participant[0]).to.equal("Nông trại Đà Lạt");
            expect(participant[1]).to.equal(1); // Role.Farmer
            expect(participant[2]).to.be.true; // isActive
        });

        it("Should allow admin to add manufacturer, distributor, retailer", async function () {
            const [admin] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: admin }
            });

            // Add Manufacturer
            await contract.write.addParticipant([
                manufacturerAccount,
                "Nhà máy chế biến",
                2 // Role.Manufacturer
            ]);

            // Add Distributor
            await contract.write.addParticipant([
                distributorAccount,
                "Công ty vận chuyển",
                3 // Role.Distributor
            ]);

            // Add Retailer
            await contract.write.addParticipant([
                retailerAccount,
                "Siêu thị Co.opMart",
                4 // Role.Retailer
            ]);

            const manufacturer = await contract.read.getParticipant([manufacturerAccount]);
            expect(manufacturer[2]).to.be.true;
        });

        it("Should not allow non-admin to add participants", async function () {
            const [, farmer] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: farmer }
            });

            try {
                await contract.write.addParticipant([
                    "0x0000000000000000000000000000000000000001" as Address,
                    "Test",
                    1
                ]);
                expect.fail("Should have thrown an error");
            } catch (error: any) {
                expect(error.message).to.include("Chi admin moi duoc thuc hien hanh dong nay");
            }
        });
    });

    describe("Product Lifecycle", function () {
        let productId: bigint;

        it("Should allow farmer to create a product", async function () {
            const [, farmer] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: farmer }
            });

            const hash = await contract.write.createProduct([
                "Cà phê Arabica",
                "Đà Lạt, Lâm Đồng"
            ]);

            // Lấy product ID từ event
            const publicClient = await hre.viem.getPublicClient();
            const receipt = await publicClient.waitForTransactionReceipt({ hash });

            productId = 1n; // First product

            const product = await contract.read.products([productId]);
            expect(product[1]).to.equal("Cà phê Arabica"); // name
            expect(product[2]).to.equal(0); // State.Planted
        });

        it("Should allow farmer to harvest the product", async function () {
            const [, farmer] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: farmer }
            });

            await contract.write.harvestProduct([productId]);

            const state = await contract.read.getProductState([productId]);
            expect(state).to.equal(1); // State.Harvested
        });

        it("Should allow manufacturer to process the product", async function () {
            const [, , manufacturer] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: manufacturer }
            });

            await contract.write.processProduct([productId]);

            const state = await contract.read.getProductState([productId]);
            expect(state).to.equal(2); // State.Processed
        });

        it("Should allow distributor to ship the product", async function () {
            const [, , , distributor] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: distributor }
            });

            await contract.write.shipProduct([productId]);

            const state = await contract.read.getProductState([productId]);
            expect(state).to.equal(3); // State.Shipped
        });

        it("Should allow retailer to receive and price the product", async function () {
            const [, , , , retailer] = await hre.viem.getWalletClients();
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress, {
                client: { wallet: retailer }
            });

            const price = hre.viem.parseEther("0.01"); // 0.01 ETH
            await contract.write.receiveProduct([productId, price]);

            const state = await contract.read.getProductState([productId]);
            expect(state).to.equal(5); // State.ForSale
        });

        it("Should return complete product history", async function () {
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress);

            const history = await contract.read.getProductHistory([productId]);

            expect(history[0]).to.equal("Cà phê Arabica"); // name
            expect(history[1]).to.equal(5); // State.ForSale
            expect(history[2]).to.equal("Nông trại Đà Lạt"); // farmerName
            expect(history[3]).to.equal("Đà Lạt, Lâm Đồng"); // farmLocation
            expect(history[5]).to.equal("Nhà máy chế biến"); // manufacturerName
            expect(history[7]).to.equal("Công ty vận chuyển"); // distributorName
            expect(history[9]).to.equal("Siêu thị Co.opMart"); // retailerName
        });
    });

    describe("Helper Functions", function () {
        it("Should convert state enum to string", async function () {
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress);

            const planted = await contract.read.stateToString([0]);
            expect(planted).to.equal("Da gieo trong");

            const forSale = await contract.read.stateToString([5]);
            expect(forSale).to.equal("Dang ban");
        });

        it("Should convert role enum to string", async function () {
            const contract = await hre.viem.getContractAt("FoodTraceability", contractAddress);

            const admin = await contract.read.roleToString([0]);
            expect(admin).to.equal("Quan tri vien");

            const farmer = await contract.read.roleToString([1]);
            expect(farmer).to.equal("Nong dan");
        });
    });
});
