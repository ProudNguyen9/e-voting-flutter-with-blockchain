# ⚡ HƯỚNG DẪN CHẠY NHANH - 5 PHÚT

## 🎯 Chạy ngay trong 5 bước

### Bước 1: Cài đặt dependencies
```bash
npm install
```

### Bước 2: Compile contract
```bash
npx hardhat compile
```

### Bước 3: Khởi động blockchain local
Mở terminal mới và chạy (giữ terminal này):
```bash
npx hardhat node
```

### Bước 4: Deploy contract
Mở terminal mới và chạy:
```bash
npx hardhat run scripts/deploy-food-traceability.js --network localhost
```

Hoặc dùng Ignition:
```bash
npx hardhat ignition deploy ignition/modules/FoodTraceability.ts --network localhost
```

### Bước 5: Chạy frontend
- Mở `frontend/index.html` bằng Live Server (VSCode extension)
- Hoặc: `npx http-server frontend -p 8000`

---

## 🦊 Cấu hình MetaMask

### Thêm Hardhat Network:
- Network Name: `Hardhat Local`
- RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`
- Currency: `ETH`

### Import tài khoản test:
Copy private key từ terminal `hardhat node`:
```
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

---

## 📝 Cập nhật địa chỉ contract

Sau khi deploy, copy địa chỉ contract và cập nhật trong `frontend/js/contract.js`:

```javascript
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Thay bằng địa chỉ của bạn
```

---

## ✅ Test nhanh

```bash
# Compile
npx hardhat compile

# Test (nếu có)
npx hardhat test

# Deploy local
npx hardhat run scripts/deploy-food-traceability.js --network localhost
```

---

## 🐛 Lỗi thường gặp

**Lỗi: "Cannot find module"**
```bash
npm install
```

**Lỗi: "Nonce too high"**
- MetaMask → Settings → Advanced → Clear activity tab data

**Lỗi: "Network error"**
- Kiểm tra `hardhat node` đang chạy
- Kiểm tra MetaMask đang ở network Hardhat Local

---

## 📚 Xem hướng dẫn đầy đủ

Đọc file [`HUONG_DAN_CHAY_DU_AN.md`](HUONG_DAN_CHAY_DU_AN.md) để biết chi tiết.

---

**🎉 Chúc bạn thành công!**
