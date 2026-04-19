# 🗳️ E-Voting Backend - Hướng dẫn Setup

## 📋 Bước 1: Cài đặt SQL Server

1. Tải SQL Server Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Cài đặt với chế độ Basic
3. Mở **SQL Server Management Studio (SSMS)**

## 📊 Bước 2: Chạy Database Script

1. Mở SSMS và connect đến SQL Server
2. Mở file [`database-setup.sql`](database-setup.sql:1)
3. Nhấn **F5** hoặc click **Execute**
4. Kiểm tra kết quả:
   - Database `evoting_db` đã được tạo
   - 5 tables đã được tạo
   - Admin mặc định: `admin` / `admin123`

## ⚙️ Bước 3: Cấu hình Backend

Chỉnh sửa file [`backend/.env`](backend/.env:1):

```env
# Blockchain
PROVIDER_URL=http://127.0.0.1:8545
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# SQL Server (Connection String như .NET Core)
DB_CONNECTION_STRING=Server=localhost;Database=evoting_db;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=true;

# JWT Secret
JWT_SECRET=your-secret-key-change-this

# Email (Gmail App Password)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_FROM=E-Voting <your-email@gmail.com>

# Server
PORT=3000
```

**Quan trọng:**
- Đổi `YOUR_PASSWORD` thành password SQL Server của bạn
- Tạo Gmail App Password tại: https://myaccount.google.com/apppasswords

## 🚀 Bước 4: Chạy Backend

```bash
# Cài dependencies
npm install

# Chạy server
npm start
```

Server sẽ chạy tại: http://localhost:3000

## 🧪 Bước 5: Test

Mở file [`test-ui.html`](test-ui.html:1) trong browser để test các API.

**Admin mặc định:**
- Username: `admin`
- Password: `admin123`

## 📝 Luồng test

1. **Đăng ký User** → Nhập thông tin + địa chỉ ví MetaMask
2. **Đăng nhập Admin** → Phê duyệt user
3. **Đăng nhập User** → Xem danh sách cuộc bầu cử
4. **Đăng ký tham gia** → Nhận PIN qua email
5. **Xác thực PIN** → Bỏ phiếu qua MetaMask
6. **Lưu gas tracking** → Admin hoàn phí

## 🔧 Troubleshooting

### Lỗi kết nối SQL Server

Kiểm tra connection string trong `.env`:
```env
# Thử các cách này:
DB_CONNECTION_STRING=Server=localhost;Database=evoting_db;User Id=sa;Password=123456;TrustServerCertificate=true;
# Hoặc
DB_CONNECTION_STRING=Server=.;Database=evoting_db;User Id=sa;Password=123456;TrustServerCertificate=true;
# Hoặc
DB_CONNECTION_STRING=Server=(local);Database=evoting_db;User Id=sa;Password=123456;TrustServerCertificate=true;
```

### Lỗi gửi email

- Phải dùng Gmail App Password, không phải password thường
- Bật 2-Step Verification trước
- Tạo App Password tại: https://myaccount.google.com/apppasswords

## 📚 Tài liệu

- API Endpoints: [`README.md`](README.md:1)
- Test chi tiết: [`TEST_GUIDE.md`](TEST_GUIDE.md:1)
- Luồng xác thực: [`../LUONG_XAC_THUC.md`](../LUONG_XAC_THUC.md:1)

---

**Lưu ý:** Đây là version demo cho đồ án. Trong production cần bảo mật tốt hơn.
