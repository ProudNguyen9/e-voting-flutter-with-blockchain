/**
 * Script Deploy EVoting Contract sử dụng Viem
 *
 * Chạy: npx hardhat run scripts/deploy-evoting-viem.js --network localhost
 */

import hre from "hardhat";

async function main() {
    console.log("\n🗳️  BẮT ĐẦU DEPLOY E-VOTING CONTRACT\n");
    console.log("=".repeat(70));

    // Hardhat v3: lấy viem từ network.connect()
    const { viem } = await hre.network.connect();

    // Lấy các accounts
    const [admin, voter1, voter2, voter3, voter4, voter5] = await viem.getWalletClients();

    console.log("\n📋 THÔNG TIN TÀI KHOẢN:");
    console.log("-".repeat(70));
    console.log(`👤 Admin:   ${admin.account.address}`);
    console.log(`🗳️  Voter 1: ${voter1.account.address}`);
    console.log(`🗳️  Voter 2: ${voter2.account.address}`);
    console.log(`🗳️  Voter 3: ${voter3.account.address}`);
    console.log(`🗳️  Voter 4: ${voter4.account.address}`);
    console.log(`🗳️  Voter 5: ${voter5.account.address}`);

    // Deploy contract
    console.log("\n📦 ĐANG DEPLOY CONTRACT...");
    console.log("-".repeat(70));

    const contract = await viem.deployContract("EVoting");
    const contractAddress = contract.address;

    console.log(`✅ Contract deployed tại: ${contractAddress}`);

    // ========================================
    // PHASE 1: CONFIGURATION
    // ========================================
    console.log("\n" + "=".repeat(70));
    console.log("📝 PHASE 1: CONFIGURATION - THIẾT LẬP BẦU CỬU");
    console.log("=".repeat(70));

    // Tạo bầu cử
    console.log("\n1️⃣ Tạo bầu cử mới...");
    const startTime = BigInt(Math.floor(Date.now() / 1000) + 60); // Bắt đầu sau 1 phút
    const endTime = startTime + 3600n; // Kết thúc sau 1 giờ

    await contract.write.createElection([
        "Bầu cử Chủ tịch Hội Sinh viên 2024",
        "Bầu chọn Chủ tịch Hội Sinh viên nhiệm kỳ 2024-2025",
        startTime,
        endTime
    ]);
    console.log("   ✅ Đã tạo bầu cử ID: 1");

    // Thêm ứng cử viên
    console.log("\n2️⃣ Thêm ứng cử viên...");

    const candidates = [
        { name: "Nguyễn Văn An", desc: "Ứng viên độc lập - Kinh nghiệm 3 năm" },
        { name: "Trần Thị Bình", desc: "Đại diện Khoa CNTT - GPA 3.8" },
        { name: "Lê Hoàng Cường", desc: "Phó Chủ tịch nhiệm kỳ trước" },
        { name: "Phạm Thị Dung", desc: "Trưởng ban Văn nghệ" }
    ];

    for (const candidate of candidates) {
        await contract.write.addCandidate([
            1n,
            candidate.name,
            candidate.desc,
            "https://via.placeholder.com/150"
        ]);
        console.log(`   ✅ Đã thêm: ${candidate.name}`);
    }

    // Đăng ký cử tri
    console.log("\n3️⃣ Đăng ký cử tri...");
    const voters = [
        voter1.account.address,
        voter2.account.address,
        voter3.account.address,
        voter4.account.address,
        voter5.account.address
    ];

    await contract.write.registerVotersBatch([1n, voters]);
    console.log(`   ✅ Đã đăng ký ${voters.length} cử tri`);

    // Lấy thông tin bầu cử
    const electionInfo = await contract.read.getElectionInfo([1n]);
    console.log("\n📊 Thông tin bầu cử:");
    console.log(`   Tiêu đề: ${electionInfo[0]}`);
    console.log(`   Tổng cử tri: ${electionInfo[4]}`);
    console.log(`   Số ứng viên: ${electionInfo[5]}`);
    console.log(`   Trạng thái: Configuration`);

    // Tổng kết
    console.log("\n" + "=".repeat(70));
    console.log("✅ HOÀN THÀNH DEPLOY E-VOTING!");
    console.log("=".repeat(70));

    console.log("\n📝 THÔNG TIN QUAN TRỌNG:");
    console.log(`   Contract Address: ${contractAddress}`);
    console.log(`   Network: ${hre.network.name}`);
    console.log(`   Admin: ${admin.account.address}`);
    console.log(`   Election ID: 1`);

    console.log("\n🎯 BƯỚC TIẾP THEO:");
    console.log("   1. Copy địa chỉ contract vào frontend/js/contract.js");
    console.log("   2. Cập nhật CONTRACT_ADDRESS = '" + contractAddress + "'");
    console.log("   3. Mở frontend/index.html bằng Live Server");
    console.log("   4. Kết nối MetaMask với Hardhat Network (Chain ID: 31337)");
    console.log("   5. Import các tài khoản test vào MetaMask");
    console.log("   6. Bắt đầu sử dụng hệ thống E-Voting!\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ LỖI:", error);
        process.exit(1);
    });
