# 🚀 HƯỚNG DẪN CHẠY DỰ ÁN FOOD TRACEABILITY

## 📋 Yêu cầu hệ thống

- **Node.js**: Phiên bản 18.x trở lên
- **npm** hoặc **yarn**: Package manager
- **MetaMask**: Extension trình duyệt (để tương tác với blockchain)
- **Git**: Để clone dự án (nếu cần)

---

## 🔧 BƯỚC 1: CÀI ĐẶT DỰ ÁN

### 1.1. Cài đặt dependencies

Mở terminal tại thư mục dự án và chạy:

```bash
npm install
```

Lệnh này sẽ cài đặt tất cả các package cần thiết:
- Hardhat 3.x (framework phát triển smart contract)
- Viem (thư viện tương tác Ethereum)
- TypeScript
- Các công cụ testing và deployment

---

## 🧪 BƯỚC 2: COMPILE SMART CONTRACT

### 2.1. Biên dịch contract

```bash
npx hardhat compile
```

Lệnh này sẽ:
- Biên dịch file `contracts/FoodTraceability.sol`
- Tạo artifacts trong thư mục `artifacts/`
- Kiểm tra lỗi cú pháp Solidity

### 2.2. Kiểm tra kết quả

Nếu thành công, bạn sẽ thấy:
```
Compiled 1 Solidity file successfully
```

---

## 🧪 BƯỚC 3: CHẠY TEST (Tùy chọn)

### 3.1. Tạo file test (nếu chưa có)

Tạo file `test/FoodTraceability.ts`:

```typescript
import { describe, it } from "node:test";
import { expect } from "chai";
import hre from "hardhat";

describe("FoodTraceability", function () {
  it("Should deploy successfully", async function () {
    const contract = await hre.viem.deployContract("FoodTraceability");
    expect(contract.address).to.be.properAddress;
  });
});
```

### 3.2. Chạy test

```bash
npx hardhat test
```

---

## 🌐 BƯỚC 4: CHẠY LOCAL BLOCKCHAIN

### 4.1. Khởi động Hardhat Network

Mở terminal mới và chạy:

```bash
npx hardhat node
```

Lệnh này sẽ:
- Khởi động blockchain local tại `http://127.0.0.1:8545`
- Tạo 20 tài khoản test với 10,000 ETH mỗi tài khoản
- Hiển thị private keys để import vào MetaMask

**⚠️ LƯU Ý**: Giữ terminal này chạy, đừng tắt!

### 4.2. Kết quả mong đợi

```
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/

Accounts
========
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...
```

---

## 🚀 BƯỚC 5: DEPLOY CONTRACT LÊN LOCAL

### 5.1. Tạo Ignition module

Tạo file `ignition/modules/FoodTraceability.ts`:

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const FoodTraceabilityModule = buildModule("FoodTraceabilityModule", (m) => {
  const foodTraceability = m.contract("FoodTraceability");
  return { foodTraceability };
});

export default FoodTraceabilityModule;
```

### 5.2. Deploy contract

Mở terminal mới (giữ `hardhat node` chạy) và chạy:

```bash
npx hardhat ignition deploy ignition/modules/FoodTraceability.ts --network localhost
```

### 5.3. Lưu địa chỉ contract

Sau khi deploy thành công, bạn sẽ thấy:

```
✔ Confirm deploy to network localhost (31337)? … yes
...
Deployed Addresses:
FoodTraceabilityModule#FoodTraceability - 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

**📝 QUAN TRỌNG**: Copy địa chỉ contract này (ví dụ: `0x5FbDB2315678afecb367f032d93F642f64180aa3`)

---

## 🌐 BƯỚC 6: CẤU HÌNH METAMASK

### 6.1. Thêm Hardhat Network vào MetaMask

1. Mở MetaMask
2. Click vào dropdown network (góc trên bên trái)
3. Click "Add Network" → "Add a network manually"
4. Điền thông tin:
   - **Network Name**: Hardhat Local
   - **RPC URL**: `http://127.0.0.1:8545`
   - **Chain ID**: `31337`
   - **Currency Symbol**: `ETH`
5. Click "Save"

### 6.2. Import tài khoản test

1. Click vào icon tài khoản → "Import Account"
2. Paste private key từ `hardhat node` (ví dụ Account #0)
3. Click "Import"

**⚠️ CẢNH BÁO**: Chỉ dùng private key này cho mục đích test local, KHÔNG BAO GIỜ dùng trên mainnet!

---

## 🎨 BƯỚC 7: CHẠY FRONTEND

### 7.1. Cập nhật địa chỉ contract trong frontend

Mở file `frontend/js/contract.js` và cập nhật:

```javascript
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Địa chỉ vừa deploy
```

### 7.2. Khởi động web server

**Cách 1: Dùng Live Server (VSCode Extension)**
1. Cài extension "Live Server" trong VSCode
2. Right-click vào `frontend/index.html`
3. Chọn "Open with Live Server"
4. Trình duyệt sẽ tự động mở tại `http://127.0.0.1:5500`

**Cách 2: Dùng Python**
```bash
cd frontend
python -m http.server 8000
```
Mở trình duyệt tại `http://localhost:8000`

**Cách 3: Dùng Node.js http-server**
```bash
npx http-server frontend -p 8000
```

### 7.3. Kết nối MetaMask

1. Mở trang web frontend
2. Click nút "Connect Wallet"
3. MetaMask sẽ popup → chọn tài khoản → "Connect"
4. Đảm bảo đang ở network "Hardhat Local"

---

## 🎯 BƯỚC 8: TEST CHỨC NĂNG

### 8.1. Đăng nhập với vai trò Admin

- Tài khoản deploy contract tự động là Admin
- Bạn sẽ thấy giao diện Admin Panel

### 8.2. Thêm người tham gia

**Thêm Farmer:**
1. Copy địa chỉ Account #1 từ `hardhat node`
2. Trong Admin Panel, điền:
   - Address: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
   - Name: `Nông trại Đà Lạt`
   - Role: `Farmer`
3. Click "Add Participant"
4. MetaMask popup → "Confirm"

**Thêm Manufacturer, Distributor, Retailer tương tự**

### 8.3. Chuyển đổi tài khoản và test workflow

1. **Switch sang Farmer account** trong MetaMask
2. Refresh trang → Thấy Farmer Panel
3. Tạo sản phẩm mới:
   - Product Name: `Cà phê Arabica`
   - Farm Location: `Đà Lạt, Lâm Đồng`
   - Click "Create Product"
4. Đánh dấu "Harvest" khi thu hoạch

5. **Switch sang Manufacturer account**
6. Click "Process Product" với Product ID vừa tạo

7. **Switch sang Distributor account**
8. Click "Ship Product"

8. **Switch sang Retailer account**
9. Click "Receive Product" và đặt giá

### 8.4. Tra cứu sản phẩm (Public)

- Không cần đăng nhập
- Nhập Product ID
- Xem toàn bộ lịch sử từ farm → consumer

---

## 📊 BƯỚC 9: DEPLOY LÊN TESTNET (Sepolia)

### 9.1. Lấy Sepolia ETH

1. Truy cập faucet: https://sepoliafaucet.com/
2. Paste địa chỉ ví của bạn
3. Nhận 0.5 SepoliaETH (miễn phí)

### 9.2. Cấu hình private key

```bash
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

Nhập private key của bạn khi được hỏi.

### 9.3. Cấu hình RPC URL

Thêm vào file `.env` (tạo mới nếu chưa có):

```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

Lấy API key miễn phí tại: https://www.alchemy.com/

### 9.4. Deploy lên Sepolia

```bash
npx hardhat ignition deploy ignition/modules/FoodTraceability.ts --network sepolia
```

### 9.5. Verify contract (Tùy chọn)

```bash
npx hardhat verify --network sepolia DEPLOYED_CONTRACT_ADDRESS
```

---

## 🐛 XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi 1: "Cannot find module"
```bash
npm install
```

### Lỗi 2: "Nonce too high"
- Reset MetaMask: Settings → Advanced → Clear activity tab data

### Lỗi 3: "Insufficient funds"
- Đảm bảo tài khoản có đủ ETH
- Trên local: dùng tài khoản từ `hardhat node`
- Trên testnet: lấy ETH từ faucet

### Lỗi 4: "Contract not deployed"
- Kiểm tra lại địa chỉ contract trong `contract.js`
- Đảm bảo đã deploy thành công

### Lỗi 5: MetaMask không kết nối
- Refresh trang
- Kiểm tra network đúng chưa
- Unlock MetaMask

---

## 📁 CẤU TRÚC DỰ ÁN

```
food-traceability/
├── contracts/              # Smart contracts
│   └── FoodTraceability.sol
├── frontend/              # Giao diện web
│   ├── index.html
│   ├── js/
│   │   ├── app.js        # Logic chính
│   │   ├── contract.js   # Tương tác contract
│   │   └── ui.js         # Xử lý UI
│   └── panels/           # Các panel theo role
├── ignition/modules/     # Deploy scripts
├── test/                 # Test files
├── hardhat.config.ts     # Cấu hình Hardhat
└── package.json          # Dependencies
```

---

## 🎓 TÀI LIỆU THAM KHẢO

- **Hardhat Docs**: https://hardhat.org/docs
- **Viem Docs**: https://viem.sh/
- **Solidity Docs**: https://docs.soliditylang.org/
- **MetaMask Guide**: https://metamask.io/

---

## 📞 HỖ TRỢ

Nếu gặp vấn đề, hãy:
1. Kiểm tra console log trong browser (F12)
2. Kiểm tra terminal output
3. Đọc lại hướng dẫn từng bước
4. Google error message cụ thể

---

## ✅ CHECKLIST HOÀN THÀNH

- [ ] Cài đặt Node.js và npm
- [ ] Clone/download dự án
- [ ] Chạy `npm install`
- [ ] Compile contract thành công
- [ ] Khởi động `hardhat node`
- [ ] Deploy contract lên local
- [ ] Cấu hình MetaMask
- [ ] Import tài khoản test
- [ ] Cập nhật địa chỉ contract trong frontend
- [ ] Chạy web server
- [ ] Kết nối MetaMask với frontend
- [ ] Test workflow hoàn chỉnh

---

**🎉 Chúc bạn thành công với dự án Food Traceability!**

*Dự án học tập - Blockchain Programming Course*  
*Đại học Công Nghệ Đồng Nai*
