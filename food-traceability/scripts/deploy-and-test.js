// scripts/deploy-and-test.js
import hre from "hardhat";
import { parseEther, formatEther } from "viem";

async function main() {
  // Hardhat v3: lấy viem từ network.connect()
  const { viem } = await hre.network.connect();

  const [admin, farmer, manufacturer, distributor, retailer] =
    await viem.getWalletClients();

  console.log("========== FOOD TRACEABILITY TEST ==========");
  console.log("Admin:       ", admin.account.address);
  console.log("Farmer:      ", farmer.account.address);
  console.log("Manufacturer:", manufacturer.account.address);
  console.log("Distributor: ", distributor.account.address);
  console.log("Retailer:    ", retailer.account.address);

  // ===== BƯỚC 1: DEPLOY CONTRACT =====
  console.log("\n[BUOC 1] Deploying contract...");
  const contract = await viem.deployContract("FoodTraceability");
  console.log("  Contract deployed tai:", contract.address);

  // ===== BƯỚC 2: THÊM PARTICIPANTS =====
  console.log("\n[BUOC 2] Them participants...");
  await contract.write.addParticipant(
    [farmer.account.address, "Nong Trai Xanh", 1],
    { account: admin.account }
  );
  await contract.write.addParticipant(
    [manufacturer.account.address, "Nha May Sach", 2],
    { account: admin.account }
  );
  await contract.write.addParticipant(
    [distributor.account.address, "Cong Ty Van Tai ABC", 3],
    { account: admin.account }
  );
  await contract.write.addParticipant(
    [retailer.account.address, "Sieu Thi BigC", 4],
    { account: admin.account }
  );
  console.log("  Da them 4 participants thanh cong!");

  // ===== BƯỚC 3: FARMER tạo sản phẩm =====
  console.log("\n[BUOC 3] FARMER: Tao san pham...");
  await contract.write.createProduct(
    ["Ca Phe Arabica", "Bao Loc, Lam Dong, Vietnam"],
    { account: farmer.account }
  );
  console.log("  San pham ID:1 da tao - Trang thai: Da gieo trong");

  // ===== BƯỚC 4: FARMER thu hoạch =====
  console.log("\n[BUOC 4] FARMER: Thu hoach...");
  await contract.write.harvestProduct([1n], { account: farmer.account });
  console.log("  Trang thai: Da thu hoach");

  // ===== BƯỚC 5: MANUFACTURER chế biến =====
  console.log("\n[BUOC 5] MANUFACTURER: Che bien...");
  await contract.write.processProduct([1n], { account: manufacturer.account });
  console.log("  Trang thai: Da che bien");

  // ===== BƯỚC 6: DISTRIBUTOR vận chuyển =====
  console.log("\n[BUOC 6] DISTRIBUTOR: Van chuyen...");
  await contract.write.shipProduct([1n], { account: distributor.account });
  console.log("  Trang thai: Dang van chuyen");

  // ===== BƯỚC 7: RETAILER nhận hàng + đặt giá =====
  console.log("\n[BUOC 7] RETAILER: Nhan hang va dat gia...");
  const price = parseEther("0.05");
  await contract.write.receiveProduct([1n, price], { account: retailer.account });
  console.log("  Trang thai: Dang ban - Gia: 0.05 ETH");

  // ===== BƯỚC 8: Đọc lịch sử sản phẩm =====
  console.log("\n===== LICH SU SAN PHAM #1 =====");
  const h = await contract.read.getProductHistory([1n]);
  console.log("Ten san pham:  ", h[0]);
  console.log("Nong dan:      ", h[2]);
  console.log("Dia diem:      ", h[3]);
  console.log("Nha may:       ", h[5]);
  console.log("Phan phoi:     ", h[7]);
  console.log("Sieu thi:      ", h[9]);
  console.log("Gia ban (ETH): ", formatEther(h[11]));
  console.log("\n HOAN THANH - Toan bo quy trinh test thanh cong!");
}

main()
  .then(() => process.exit(0))
  .catch((err) => { console.error(err); process.exit(1); });