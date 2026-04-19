/**
 * Script Deploy và Test FoodTraceability Contract
 * 
 * Chạy: npx hardhat run scripts/deploy-food-traceability.js --network localhost
 */

const hre = require("hardhat");

async function main() {
    console.log("\n🚀 BẮT ĐẦU DEPLOY FOODTRACEABILITY CONTRACT\n");
    console.log("=".repeat(60));

    // Lấy các accounts
    const [deployer, farmer, manufacturer, distributor, retailer] = await hre.ethers.getSigners();

    console.log("\n📋 THÔNG TIN TÀI KHOẢN:");
    console.log("-".repeat(60));
    console.log(`👤 Deployer (Admin): ${deployer.address}`);
    console.log(`🌾 Farmer:           ${farmer.address}`);
    console.log(`🏭 Manufacturer:     ${manufacturer.address}`);
    console.log(`🚚 Distributor:      ${distributor.address}`);
    console.log(`🏪 Retailer:         ${retailer.address}`);

    // Deploy contract
    console.log("\n📦 ĐANG DEPLOY CONTRACT...");
    console.log("-".repeat(60));

    const FoodTraceability = await hre.ethers.getContractFactory("FoodTraceability");
    const contract = await FoodTraceability.deploy();
    await contract.waitForDeployment();

    const contractAddress = await contract.getAddress();

    console.log(`✅ Contract deployed tại: ${contractAddress}`);
    console.log(`⛽ Gas used: ${(await contract.deploymentTransaction().wait()).gasUsed.toString()}`);

    // Thêm participants
    console.log("\n👥 ĐANG THÊM NGƯỜI THAM GIA...");
    console.log("-".repeat(60));

    // Thêm Farmer
    let tx = await contract.addParticipant(
        farmer.address,
        "Nông trại Đà Lạt",
        1 // Role.Farmer
    );
    await tx.wait();
    console.log("✅ Đã thêm Farmer: Nông trại Đà Lạt");

    // Thêm Manufacturer
    tx = await contract.addParticipant(
        manufacturer.address,
        "Nhà máy chế biến Việt Nam",
        2 // Role.Manufacturer
    );
    await tx.wait();
    console.log("✅ Đã thêm Manufacturer: Nhà máy chế biến Việt Nam");

    // Thêm Distributor
    tx = await contract.addParticipant(
        distributor.address,
        "Công ty vận chuyển Nhanh",
        3 // Role.Distributor
    );
    await tx.wait();
    console.log("✅ Đã thêm Distributor: Công ty vận chuyển Nhanh");

    // Thêm Retailer
    tx = await contract.addParticipant(
        retailer.address,
        "Siêu thị Co.opMart",
        4 // Role.Retailer
    );
    await tx.wait();
    console.log("✅ Đã thêm Retailer: Siêu thị Co.opMart");

    // Test workflow hoàn chỉnh
    console.log("\n🧪 TEST WORKFLOW HOÀN CHỈNH");
    console.log("=".repeat(60));

    // 1. Farmer tạo sản phẩm
    console.log("\n1️⃣ FARMER: Tạo sản phẩm mới");
    const farmerContract = contract.connect(farmer);
    tx = await farmerContract.createProduct(
        "Cà phê Arabica Đà Lạt",
        "Tọa độ: 11.9404° N, 108.4583° E"
    );
    const receipt = await tx.wait();
    console.log(`   ✅ Đã tạo sản phẩm ID: 1`);
    console.log(`   📅 Thời gian: ${new Date().toLocaleString('vi-VN')}`);

    // 2. Farmer thu hoạch
    console.log("\n2️⃣ FARMER: Thu hoạch sản phẩm");
    tx = await farmerContract.harvestProduct(1);
    await tx.wait();
    console.log(`   ✅ Đã thu hoạch sản phẩm ID: 1`);

    // 3. Manufacturer chế biến
    console.log("\n3️⃣ MANUFACTURER: Chế biến sản phẩm");
    const manufacturerContract = contract.connect(manufacturer);
    tx = await manufacturerContract.processProduct(1);
    await tx.wait();
    console.log(`   ✅ Đã chế biến sản phẩm ID: 1`);

    // 4. Distributor vận chuyển
    console.log("\n4️⃣ DISTRIBUTOR: Vận chuyển sản phẩm");
    const distributorContract = contract.connect(distributor);
    tx = await distributorContract.shipProduct(1);
    await tx.wait();
    console.log(`   ✅ Đã vận chuyển sản phẩm ID: 1`);

    // 5. Retailer nhận hàng và đặt giá
    console.log("\n5️⃣ RETAILER: Nhận hàng và đặt giá");
    const retailerContract = contract.connect(retailer);
    const price = hre.ethers.parseEther("0.05"); // 0.05 ETH
    tx = await retailerContract.receiveProduct(1, price);
    await tx.wait();
    console.log(`   ✅ Đã nhận hàng và đặt giá: 0.05 ETH`);

    // Xem lịch sử sản phẩm
    console.log("\n📜 LỊCH SỬ SẢN PHẨM HOÀN CHỈNH");
    console.log("=".repeat(60));

    const history = await contract.getProductHistory(1);

    console.log(`\n🏷️  Tên sản phẩm: ${history[0]}`);
    console.log(`📊 Trạng thái: ${await contract.stateToString(history[1])}`);
    console.log(`\n🌾 GIAI ĐOẠN TRỒNG TRỌT:`);
    console.log(`   👤 Nông dân: ${history[2]}`);
    console.log(`   📍 Vị trí: ${history[3]}`);
    console.log(`   📅 Ngày gieo trồng: ${new Date(Number(history[4]) * 1000).toLocaleString('vi-VN')}`);

    console.log(`\n🏭 GIAI ĐOẠN CHẾ BIẾN:`);
    console.log(`   👤 Nhà máy: ${history[5]}`);
    console.log(`   📅 Ngày chế biến: ${new Date(Number(history[6]) * 1000).toLocaleString('vi-VN')}`);

    console.log(`\n🚚 GIAI ĐOẠN VẬN CHUYỂN:`);
    console.log(`   👤 Nhà phân phối: ${history[7]}`);
    console.log(`   📅 Ngày vận chuyển: ${new Date(Number(history[8]) * 1000).toLocaleString('vi-VN')}`);

    console.log(`\n🏪 GIAI ĐOẠN BÁN LẺ:`);
    console.log(`   👤 Siêu thị: ${history[9]}`);
    console.log(`   📅 Ngày nhận hàng: ${new Date(Number(history[10]) * 1000).toLocaleString('vi-VN')}`);
    console.log(`   💰 Giá bán: ${hre.ethers.formatEther(history[11])} ETH`);

    // Tổng kết
    console.log("\n" + "=".repeat(60));
    console.log("✅ HOÀN THÀNH DEPLOY VÀ TEST!");
    console.log("=".repeat(60));

    console.log("\n📝 THÔNG TIN QUAN TRỌNG:");
    console.log(`   Contract Address: ${contractAddress}`);
    console.log(`   Network: ${hre.network.name}`);
    console.log(`   Admin: ${deployer.address}`);

    console.log("\n🎯 BƯỚC TIẾP THEO:");
    console.log("   1. Copy địa chỉ contract vào frontend/js/contract.js");
    console.log("   2. Mở frontend/index.html bằng Live Server");
    console.log("   3. Kết nối MetaMask với Hardhat Network");
    console.log("   4. Import các tài khoản test vào MetaMask");
    console.log("   5. Bắt đầu sử dụng ứng dụng!\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ LỖI:", error);
        process.exit(1);
    });
