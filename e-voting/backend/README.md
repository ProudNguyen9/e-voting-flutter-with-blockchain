# 🗳️ E-Voting Backend

Backend API cho hệ thống bỏ phiếu điện tử trên blockchain với xác thực người dùng, quản lý PIN và theo dõi hoàn phí gas.

## ✨ Tính năng

- ✅ **Xác thực người dùng**: Đăng ký, đăng nhập với JWT token
- ✅ **Quản lý admin**: Phê duyệt user, tạo cuộc bầu cử
- ✅ **Hệ thống PIN**: Mã PIN unique cho mỗi user/election, gửi qua email
- ✅ **Đăng ký sớm**: User có thể đăng ký 3 ngày trước khi bầu cử bắt đầu
- ✅ **Tích hợp blockchain**: Tự động đăng ký voter lên smart contract
- ✅ **Theo dõi gas**: Lưu thông tin gas để hoàn phí sau bầu cử
- ✅ **SQL Server**: Database enterprise-grade

## 🏗️ Kiến trúc

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Frontend  │─────▶│   Backend    │─────▶│  Blockchain │
│  (MetaMask) │      │  (Node.js)   │      │  (Hardhat)  │
└─────────────┘      └──────────────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  SQL Server  │
                     └──────────────┘
```

## 📁 Cấu trúc thư mục

```
backend/
├── server.js           # Main server file với tất cả API endpoints
├── database.js         # SQL Server connection pool
├── setup-database.js   # Script tạo database và tables
├── package.json        # Dependencies
├── .env.example        # Template cấu hình
├── test-ui.html        # Giao diện test đơn giản
├── SETUP.md           # Hướng dẫn chi tiết
└── README.md          # File này
```

## 🚀 Quick Start

### 1. Cài đặt dependencies

```bash
npm install
```

### 2. Cấu hình

```bash
copy .env.example .env
# Chỉnh sửa .env với thông tin của bạn
```

### 3. Setup database

```bash
npm run setup-db
```

### 4. Chạy server

```bash
npm start
```

Server sẽ chạy tại `http://localhost:3000`

## 📖 Hướng dẫn chi tiết

Xem file [`SETUP.md`](./SETUP.md) để biết hướng dẫn đầy đủ về:
- Cài đặt SQL Server
- Cấu hình email
- Deploy smart contract
- Test API endpoints
- Troubleshooting

## 🔑 Admin mặc định

Sau khi chạy `npm run setup-db`:

```
Username: admin
Password: admin123
Email: admin@evoting.com
```

## 🧪 Test

Mở file [`test-ui.html`](./test-ui.html) trong browser để test tất cả chức năng qua giao diện đơn giản.

## 📊 Database Schema

- **users**: Thông tin người dùng
- **admins**: Thông tin admin
- **elections**: Danh sách cuộc bầu cử
- **election_registrations**: Đăng ký tham gia + PIN codes
- **gas_tracking**: Theo dõi gas để hoàn phí

## 🔄 Luồng hoạt động chính

### Đăng ký và phê duyệt
1. User đăng ký tài khoản
2. Admin phê duyệt
3. User đăng nhập

### Tham gia bầu cử
1. Admin tạo cuộc bầu cử (blockchain + DB)
2. User đăng ký tham gia (3 ngày trước)
3. Backend đăng ký lên blockchain
4. Tạo PIN và gửi email

### Bỏ phiếu
1. User nhập PIN để xác thực
2. User bỏ phiếu qua MetaMask
3. Backend lưu thông tin gas
4. Admin hoàn phí sau khi bầu cử kết thúc

## 🛠️ Tech Stack

- **Node.js** + Express
- **SQL Server** (mssql driver)
- **ethers.js** v6 (blockchain interaction)
- **JWT** (authentication)
- **bcrypt** (password hashing)
- **nodemailer** (email)

## 📝 API Endpoints

### Authentication
- `POST /api/auth/register` - Đăng ký user
- `POST /api/auth/login` - Đăng nhập user
- `POST /api/admin/login` - Đăng nhập admin

### Admin Management
- `GET /api/admin/pending-users` - Danh sách user chờ duyệt
- `POST /api/admin/approve-user/:userId` - Phê duyệt user
- `POST /api/admin/elections` - Tạo cuộc bầu cử
- `GET /api/admin/gas-refunds/:electionId` - Danh sách gas cần hoàn
- `POST /api/admin/refund-gas/:gasTrackingId` - Hoàn phí gas

### Elections
- `GET /api/elections` - Danh sách cuộc bầu cử
- `POST /api/elections/:electionId/join` - Đăng ký tham gia
- `POST /api/elections/:electionId/verify-pin` - Xác thực PIN

### Gas Tracking
- `POST /api/gas-tracking` - Lưu thông tin gas

## 🔐 Security

- Password được hash với bcrypt (10 rounds)
- JWT token với expiration 24h
- SQL injection protection với parameterized queries
- CORS enabled cho frontend integration

## 📚 Tài liệu liên quan

- [Luồng xác thực chi tiết](../LUONG_XAC_THUC.md)
- [Smart Contract](../contracts/EVoting.sol)
- [Frontend](../frontend/)

## ⚠️ Lưu ý

Đây là phiên bản demo cho đồ án blockchain. Trong production cần:
- Sử dụng password mạnh hơn
- Thay đổi JWT_SECRET
- Cấu hình HTTPS
- Thêm rate limiting
- Thêm input validation chi tiết
- Logging và monitoring

## 📄 License

MIT License - Đồ án môn Blockchain
