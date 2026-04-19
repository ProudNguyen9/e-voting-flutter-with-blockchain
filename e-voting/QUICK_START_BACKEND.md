# 🗳️ E-Voting Blockchain System - Quick Start Guide

Hệ thống bỏ phiếu điện tử trên blockchain với backend xác thực và quản lý PIN.

## 📦 Cấu trúc Project

```
e-voting/
├── contracts/              # Smart contracts
│   └── EVoting.sol        # Main voting contract
├── frontend/              # Giao diện người dùng
│   ├── index.html
│   └── js/
├── backend/               # Backend API (MỚI)
│   ├── server.js         # Main server
│   ├── database.js       # SQL Server config
│   ├── setup-database.js # Database setup
│   ├── test-ui.html      # Test interface
│   ├── SETUP.md          # Hướng dẫn chi tiết
│   └── README.md         # Backend docs
├── scripts/              # Deploy scripts
└── LUONG_XAC_THUC.md    # Luồng xác thực chi tiết
```

## 🚀 Chạy toàn bộ hệ thống

### Bước 1: Cài đặt dependencies

```bash
# Root project (Hardhat + Smart Contract)
npm install

# Backend
cd backend
npm install
cd ..
```

### Bước 2: Setup SQL Server

Xem hướng dẫn chi tiết trong [`backend/SETUP.md`](backend/SETUP.md)

```bash
# Sau khi cài SQL Server, setup database
cd backend
npm run setup-db
cd ..
```

### Bước 3: Chạy Hardhat Node (Terminal 1)

```bash
npx hardhat node
```

Giữ terminal này chạy.

### Bước 4: Deploy Smart Contract (Terminal 2)

```bash
npx hardhat run scripts/deploy-evoting.js --network localhost
```

Lưu lại **Contract Address** và cập nhật vào [`backend/.env`](backend/.env.example)

### Bước 5: Chạy Backend (Terminal 3)

```bash
cd backend
npm start
```

Backend chạy tại: `http://localhost:3000`

### Bước 6: Mở Frontend (Terminal 4)

```bash
# Mở frontend/index.html trong browser
# Hoặc dùng Live Server trong VS Code
```

### Bước 7: Test Backend (Optional)

Mở [`backend/test-ui.html`](backend/test-ui.html) trong browser để test API.

## 🔄 Luồng hoạt động đầy đủ

### 1️⃣ Setup Admin và User

**Backend Test UI:**
1. Đăng nhập admin (username: `admin`, password: `admin123`)
2. Đăng ký user mới với địa chỉ ví MetaMask
3. Admin phê duyệt user
4. User đăng nhập

### 2️⃣ Tạo cuộc bầu cử

**Frontend (Admin):**
1. Kết nối MetaMask với account admin
2. Tạo cuộc bầu cử trên blockchain
3. Thêm ứng cử viên

**Backend Test UI (Admin):**
1. Tạo cuộc bầu cử trong database với cùng Election ID

### 3️⃣ Đăng ký tham gia (3 ngày trước)

**Backend Test UI (User):**
1. Xem danh sách cuộc bầu cử
2. Click "Đăng ký" cho cuộc bầu cử
3. Nhận mã PIN qua email

### 4️⃣ Bỏ phiếu

**Backend Test UI (User):**
1. Nhập mã PIN để xác thực

**Frontend (User):**
1. Kết nối MetaMask
2. Chọn ứng cử viên
3. Bỏ phiếu (MetaMask sẽ yêu cầu xác nhận)

**Backend Test UI (User):**
1. Lưu thông tin gas với Transaction Hash

### 5️⃣ Hoàn phí gas

**Backend (Admin):**
1. Xem danh sách gas cần hoàn
2. Hoàn phí cho từng user

## 📝 Tài liệu chi tiết

- **Backend Setup**: [`backend/SETUP.md`](backend/SETUP.md)
- **Backend API**: [`backend/README.md`](backend/README.md)
- **Luồng xác thực**: [`LUONG_XAC_THUC.md`](LUONG_XAC_THUC.md)
- **Smart Contract**: [`contracts/EVoting.sol`](contracts/EVoting.sol)

## 🔧 Cấu hình quan trọng

### Backend `.env`

```env
# Blockchain
PROVIDER_URL=http://127.0.0.1:8545
CONTRACT_ADDRESS=0x... # Từ deploy script
ADMIN_PRIVATE_KEY=0xac09... # Account #0 từ Hardhat

# SQL Server
DB_SERVER=localhost
DB_NAME=evoting_db
DB_USER=sa
DB_PASSWORD=YourStrong@Passw0rd

# Email (Gmail)
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# JWT
JWT_SECRET=your-secret-key
```

### Frontend `contract.js`

```javascript
var CONTRACT_ADDRESS = "0x..."; // Cùng với backend
```

## 🎯 Điểm khác biệt so với version cũ

### ✅ Có Backend (Version mới)

- User phải đăng ký và được admin phê duyệt
- Hệ thống PIN qua email
- Đăng ký sớm 3 ngày trước
- Theo dõi và hoàn phí gas tự động
- Database SQL Server

### ❌ Không Backend (Version cũ)

- User tự do kết nối MetaMask
- Admin phải thêm voter thủ công
- Không có xác thực
- Không theo dõi gas

## 🧪 Test nhanh

### Test Backend API

```bash
# Đăng ký user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456","fullName":"Test User","walletAddress":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8"}'

# Đăng nhập admin
curl -X POST http://localhost:3000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Test Smart Contract

```bash
npx hardhat console --network localhost
```

```javascript
const EVoting = await ethers.getContractFactory("EVoting");
const contract = await EVoting.attach("0x...");
await contract.getElectionInfo(0);
```

## ⚠️ Troubleshooting

### Backend không kết nối được SQL Server
- Kiểm tra SQL Server đang chạy
- Kiểm tra TCP/IP enabled
- Thử kết nối bằng SSMS trước

### Frontend không kết nối được Backend
- Kiểm tra CORS trong [`server.js`](backend/server.js)
- Kiểm tra backend đang chạy tại port 3000

### MetaMask không thấy transaction
- Kiểm tra Hardhat node đang chạy
- Reset MetaMask account (Settings → Advanced → Reset Account)

### Email không gửi được
- Dùng Gmail App Password, không phải password thường
- Bật 2-Step Verification trước

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra tất cả services đang chạy (SQL Server, Hardhat, Backend)
2. Xem log trong terminal
3. Đọc [`backend/SETUP.md`](backend/SETUP.md) để biết chi tiết

## 🎓 Dành cho đồ án

Project này phù hợp cho:
- Đồ án môn Blockchain
- Demo hệ thống e-voting
- Học tập về Smart Contract + Backend integration

**Lưu ý**: Đây là version demo, không dùng cho production thực tế.

---

**Happy Coding! 🚀**
