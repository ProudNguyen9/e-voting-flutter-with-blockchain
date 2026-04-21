/**
 * Script Deploy EVoting Contract sử dụng Viem
 *
 * Chạy: npx hardhat run scripts/deploy-evoting.js --network localhost
 */

import hre from "hardhat";

async function main() {
    console.log("\n🗳️  DEPLOY E-VOTING CONTRACT\n");
    console.log("=".repeat(70));

    // Hardhat v3: lấy viem từ network.connect()
    const { viem } = await hre.network.connect();

    // Lấy deployer account
    const [deployer] = await viem.getWalletClients();

    console.log("📦 Đang deploy contract...");
    console.log(`   Deployer: ${deployer.account.address}`);
    console.log(`   Network: ${hre.network.name}`);

    // Deploy contract
    const contract = await viem.deployContract("EVoting");
    const contractAddress = contract.address;

    console.log("\n✅ Deploy thành công!");
    console.log("=".repeat(70));
    console.log(`📍 Contract Address: ${contractAddress}`);
    console.log(`👤 Admin Address: ${deployer.account.address}`);
    console.log("=".repeat(70));

    console.log("\n🎯 Bước tiếp theo:");
    console.log(`   1. Cập nhật CONTRACT_ADDRESS trong backend/.env`);
    console.log(`   2. CONTRACT_ADDRESS=${contractAddress}`);
    console.log(`   3. Restart backend nếu đang chạy\n`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ LỖI:", error);
        process.exit(1);
    });
