# E-Voting - Hệ thống Bỏ phiếu Điện tử

Hệ thống bỏ phiếu điện tử phi tập trung sử dụng Blockchain với giao diện web đơn giản.

## 🚀 Cấu trúc Project

```
e-voting/
├── contracts/
│   └── EVoting.sol           # Smart contract bỏ phiếu
├── frontend/
│   ├── index.html            # Giao diện web chính
│   └── js/
│       ├── contract.js       # Tương tác với smart contract
│       └── app.js            # Logic UI
├── scripts/
│   └── deploy-evoting.js     # Script deploy và test
└── hardhat.config.ts         # Cấu hình Hardhat
```

## 📋 Yêu cầu

- Node.js v16+
- MetaMask extension
- Live Server (VS Code extension) hoặc web server bất kỳ

## 🔧 Cài đặt

### 1. Cài đặt dependencies

```bash
cd e-voting
npm install
```

### 2. Chạy Hardhat Node

Mở terminal mới và chạy:

```bash
npx hardhat node
```

Giữ terminal này chạy. Bạn sẽ thấy danh sách 20 accounts với private keys.

### 3. Deploy Smart Contract

Mở terminal mới và chạy:

```bash
npx hardhat run scripts/deploy-evoting.js --network localhost
```

Script sẽ:
- Deploy contract EVoting
- Tạo bầu cử mẫu
- Thêm 4 ứng viên
- Đăng ký 5 cử tri
- Thực hiện quy trình bỏ phiếu hoàn chỉnh

**Lưu lại địa chỉ contract** được hiển thị!

### 4. Cấu hình MetaMask

1. Mở MetaMask
2. Thêm network mới:
   - Network Name: `Hardhat Local`
   - RPC URL: `http://127.0.0.1:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

3. Import accounts từ Hardhat Node:
   - Copy private key từ terminal Hardhat Node
   - MetaMask → Import Account → Paste private key

### 5. Chạy Frontend

1. Mở file `frontend/index.html` bằng Live Server
2. Hoặc chạy web server:
   ```bash
   cd frontend
   python -m http.server 8000
   ```
3. Truy cập: `http://localhost:8000`

## 🎯 Hướng dẫn sử dụng

### Bước 1: Kết nối

1. Click "Kết nối MetaMask" trên navbar
2. Chọn account trong MetaMask
3. Nhập địa chỉ contract vào ô "Contract Address"
4. Click "Kết nối Contract"

### Bước 2: Admin - Tạo bầu cử

1. Chuyển sang panel "Admin"
2. Điền thông tin bầu cử:
   - Tiêu đề: "Bầu cử Chủ tịch 2024"
   - Mô tả: "Bầu chọn Chủ tịch nhiệm kỳ 2024-2025"
   - Start Time: Timestamp hiện tại + 60 giây
   - End Time: Timestamp hiện tại + 3600 giây
3. Click "Tạo bầu cử"

**Tính timestamp:**
```javascript
// Trong console trình duyệt:
Math.floor(Date.now() / 1000) + 60  // Start time
Math.floor(Date.now() / 1000) + 3600 // End time
```

### Bước 3: Admin - Thêm ứng viên

1. Nhập Election ID: `1`
2. Nhập thông tin ứng viên:
   - Tên: "Nguyễn Văn A"
   - Mô tả: "Ứng viên độc lập"
   - URL ảnh: (tùy chọn)
3. Click "Thêm ứng viên"
4. Lặp lại cho các ứng viên khác

### Bước 4: Admin - Đăng ký cử tri

1. Nhập Election ID: `1`
2. Nhập địa chỉ ví cử tri (copy từ MetaMask)
3. Click "Đăng ký cử tri"
4. Lặp lại cho các cử tri khác

### Bước 5: Admin - Bắt đầu bỏ phiếu

1. Đợi đến thời gian bắt đầu
2. Nhập Election ID: `1`
3. Click "Bắt đầu bỏ phiếu"

### Bước 6: Cử tri - Bỏ phiếu

1. Đổi account trong MetaMask sang account cử tri đã đăng ký
2. Chuyển sang panel "Cử tri"
3. Nhập Election ID: `1`
4. Click "Xem ứng viên"
5. Click chọn ứng viên muốn bỏ phiếu
6. Click "Bỏ phiếu"
7. Xác nhận transaction trong MetaMask

### Bước 7: Admin - Kết thúc và đếm phiếu

1. Đợi đến thời gian kết thúc
2. Click "Kết thúc bỏ phiếu"
3. Click "Xáo trộn phiếu"
4. Click "Giải mã & Đếm phiếu"
5. Nhập danh sách Candidate IDs theo thứ tự phiếu
   - VD: `1,2,1,3,2` (nếu có 5 phiếu)

### Bước 8: Xem kết quả

1. Chuyển sang panel "Kết quả"
2. Nhập Election ID: `1`
3. Click "Xem kết quả"
4. Xem biểu đồ và thống kê chi tiết

## 🔐 Quy trình 5 giai đoạn

### Phase 1: Configuration (Thiết lập)
- Admin tạo bầu cử
- Thêm ứng viên
- Đăng ký cử tri

### Phase 2: Casting (Bỏ phiếu)
- Cử tri bỏ phiếu (đã mã hóa)
- Lưu commitment để xác minh

### Phase 3: Anonymization (Xáo trộn)
- Xáo trộn phiếu để bảo vệ riêng tư
- Tạo shuffle proof

### Phase 4: Decryption (Giải mã)
- Giải mã phiếu
- Đếm phiếu cho từng ứng viên

### Phase 5: Auditing (Kiểm tra)
- Xem kết quả
- Xác minh tính minh bạch

## 📊 Tính năng

✅ Bỏ phiếu mã hóa  
✅ Xáo trộn phiếu bảo mật  
✅ Minh bạch và có thể kiểm tra  
✅ Không thể bỏ phiếu 2 lần  
✅ Chỉ cử tri đã đăng ký mới được bỏ phiếu  
✅ Quản lý nhiều bầu cử  
✅ Giao diện thân thiện  

## 🛠️ Troubleshooting

### Lỗi "Nonce too high"
- Reset MetaMask: Settings → Advanced → Clear activity tab data

### Lỗi "Contract not found"
- Kiểm tra địa chỉ contract đã đúng chưa
- Đảm bảo Hardhat Node đang chạy

### Lỗi "User rejected transaction"
- Xác nhận transaction trong MetaMask

### Không thấy balance
- Import đúng account từ Hardhat Node
- Mỗi account có 10000 ETH test

## 📝 Lưu ý

- Đây là phiên bản demo, không dùng cho production
- Mã hóa được đơn giản hóa cho mục đích học tập
- Trong thực tế cần sử dụng:
  - Homomorphic Encryption
  - Zero-Knowledge Proofs
  - Mix-Net cho xáo trộn
  - Threshold Cryptography

## 🎓 Học thêm

- [Hardhat Documentation](https://hardhat.org/docs)
- [Ethers.js Documentation](https://docs.ethers.org/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 📄 License

MIT License
