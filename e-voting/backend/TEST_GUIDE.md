# 🧪 Hướng dẫn Test Backend E-Voting

Hướng dẫn test từng bước cho backend e-voting với SQL Server.

## 📋 Chuẩn bị

### 1. Cài đặt SQL Server

**Windows:**
1. Tải SQL Server Express: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Chọn "Basic" installation
3. Sau khi cài xong, mở **SQL Server Configuration Manager**
4. Enable TCP/IP:
   - SQL Server Network Configuration → Protocols for MSSQLSERVER → TCP/IP → Enable
5. Restart SQL Server service

**Kiểm tra SQL Server đang chạy:**
```bash
# Mở Command Prompt
sc query MSSQLSERVER
# Phải thấy STATE: RUNNING
```

### 2. Cài đặt dependencies

```bash
cd backend
npm install
```

### 3. Tạo file .env

```bash
copy .env.example .env
```

Chỉnh sửa `backend/.env`:
```env
# Blockchain (giữ nguyên nếu dùng Hardhat local)
PROVIDER_URL=http://127.0.0.1:8545
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
ADMIN_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# SQL Server
DB_SERVER=localhost
DB_NAME=evoting_db
DB_USER=sa
DB_PASSWORD=YourStrong@Passw0rd  # ĐỔI PASSWORD NÀY

# JWT Secret
JWT_SECRET=my-super-secret-key-123456

# Email (Gmail) - CẦN CẤU HÌNH
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com      # ĐỔI EMAIL
EMAIL_PASSWORD=your-app-password      # ĐỔI APP PASSWORD
EMAIL_FROM=E-Voting <your-email@gmail.com>

# Server
PORT=3000
```

**Lưu ý về Email:**
- Vào https://myaccount.google.com/apppasswords
- Tạo App Password (cần bật 2-Step Verification trước)
- Dùng App Password này, KHÔNG dùng password Gmail thường

### 4. Setup Database

```bash
npm run setup-db
```

Nếu thành công, bạn sẽ thấy:
```
✅ Cài đặt database thành công!
📝 Admin mặc định:
   Username: admin
   Password: admin123
   Email: admin@evoting.com
```

## 🚀 Chạy hệ thống

### Terminal 1: Hardhat Node

```bash
# Ở thư mục gốc project (không phải backend)
cd ..
npx hardhat node
```

Giữ terminal này chạy. Bạn sẽ thấy danh sách accounts.

### Terminal 2: Deploy Contract

```bash
# Ở thư mục gốc project
npx hardhat run scripts/deploy-evoting.js --network localhost
```

Lưu lại **Contract Address** (ví dụ: `0x5FbDB2315678afecb367f032d93F642f64180aa3`)

Cập nhật vào `backend/.env`:
```env
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
```

### Terminal 3: Backend Server

```bash
cd backend
npm start
```

Nếu thành công, bạn sẽ thấy:
```
🚀 Server đang chạy tại http://localhost:3000
📝 Contract Address: 0x5FbDB...
👤 Admin Wallet: 0xf39Fd...
```

## 🧪 Test với Test UI

### Bước 1: Mở Test UI

Mở file `backend/test-ui.html` trong browser:
- **Cách 1**: Double-click file
- **Cách 2**: Chuột phải → Open with → Chrome/Firefox
- **Cách 3**: Trong VS Code, cài extension "Live Server" và click "Go Live"

### Bước 2: Test đăng ký User

1. Ở tab **"Đăng ký User"**:
   - Email: `user1@test.com`
   - Password: `123456`
   - Họ tên: `Nguyễn Văn A`
   - Địa chỉ ví: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (Account #1 từ Hardhat)
   
2. Click **"Đăng ký"**

3. Kiểm tra response:
   ```json
   {
     "message": "Đăng ký thành công! Vui lòng đợi admin phê duyệt.",
     "success": true
   }
   ```

4. Kiểm tra email (nếu đã cấu hình đúng)

### Bước 3: Test đăng nhập Admin

1. Chuyển sang tab **"Đăng nhập Admin"**:
   - Username: `admin`
   - Password: `admin123`

2. Click **"Đăng nhập Admin"**

3. Lưu lại **Token** hiển thị (sẽ dùng cho các bước sau)

### Bước 4: Phê duyệt User

1. Chuyển sang tab **"Admin Panel"**

2. Click **"Tải danh sách"** ở phần "User chờ phê duyệt"

3. Bạn sẽ thấy user vừa đăng ký trong bảng

4. Click **"Phê duyệt"** cho user đó

5. Alert hiển thị: "Phê duyệt thành công!"

### Bước 5: Test đăng nhập User

1. Chuyển sang tab **"Đăng nhập User"**:
   - Email: `user1@test.com`
   - Password: `123456`

2. Click **"Đăng nhập"**

3. Lưu lại **Token** hiển thị

### Bước 6: Tạo cuộc bầu cử

**Trước tiên, tạo trên blockchain (Frontend):**

1. Mở `frontend/index.html` trong browser
2. Kết nối MetaMask với Account #0 (Admin)
3. Tạo cuộc bầu cử mới:
   - Title: "Bầu cử chủ tịch"
   - Description: "Bầu cử chủ tịch năm 2024"
   - Start time: Chọn thời gian trong tương lai
   - End time: Sau start time
4. Thêm ứng cử viên (ví dụ: "Ứng viên A", "Ứng viên B")

**Sau đó, tạo trong database (Backend):**

1. Quay lại Test UI, tab **"Admin Panel"**

2. Ở phần "Tạo cuộc bầu cử mới":
   - Election ID: `0` (ID từ blockchain, bắt đầu từ 0)
   - Tiêu đề: `Bầu cử chủ tịch`
   - Mô tả: `Bầu cử chủ tịch năm 2024`
   - Thời gian bắt đầu: Chọn thời gian (ví dụ: 3 ngày sau)
   - Thời gian kết thúc: Chọn thời gian sau start time

3. Click **"Tạo cuộc bầu cử"**

### Bước 7: Đăng ký tham gia cuộc bầu cử

1. Chuyển sang tab **"Cuộc bầu cử"**

2. Click **"Tải danh sách"**

3. Bạn sẽ thấy cuộc bầu cử vừa tạo

4. Click **"Đăng ký"** cho cuộc bầu cử đó

5. Nếu thành công, bạn sẽ thấy:
   ```json
   {
     "message": "Đăng ký thành công! Mã PIN đã được gửi qua email.",
     "success": true,
     "pinCode": "123456"
   }
   ```

6. Lưu lại **PIN code** (hoặc kiểm tra email)

**Lưu ý:** Chỉ đăng ký được từ 3 ngày trước khi bầu cử bắt đầu. Nếu chưa đến thời gian, bạn sẽ thấy lỗi.

### Bước 8: Xác thực PIN

1. Chuyển sang tab **"Bỏ phiếu"**

2. Nhập:
   - Election ID: `1` (ID trong database, không phải blockchain)
   - Mã PIN: `123456` (PIN nhận được)

3. Click **"Xác thực PIN"**

4. Nếu thành công:
   ```json
   {
     "message": "Xác thực PIN thành công",
     "success": true,
     "canVote": true
   }
   ```

**Lưu ý:** Chỉ xác thực được khi cuộc bầu cử đã bắt đầu.

### Bước 9: Bỏ phiếu (Frontend)

1. Mở `frontend/index.html`

2. Kết nối MetaMask với Account #1 (User đã đăng ký)

3. Chọn ứng cử viên

4. Click **"Bỏ phiếu"**

5. Xác nhận transaction trong MetaMask

6. Lưu lại **Transaction Hash** (ví dụ: `0xabc123...`)

### Bước 10: Lưu Gas Tracking

1. Quay lại Test UI, tab **"Bỏ phiếu"**

2. Ở phần "Lưu thông tin Gas":
   - Election ID: `1`
   - Transaction Hash: `0xabc123...` (hash vừa lưu)

3. Click **"Lưu Gas Tracking"**

4. Backend sẽ tự động lấy thông tin gas từ blockchain

### Bước 11: Hoàn phí Gas (Admin)

**Sử dụng cURL hoặc Postman:**

1. Lấy danh sách gas cần hoàn:
```bash
curl http://localhost:3000/api/admin/gas-refunds/1 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

2. Hoàn phí cho user (thay `1` bằng gas_tracking_id):
```bash
curl -X POST http://localhost:3000/api/admin/refund-gas/1 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## ✅ Checklist Test

- [ ] SQL Server đang chạy
- [ ] Database đã được setup (`npm run setup-db`)
- [ ] File `.env` đã cấu hình đúng
- [ ] Hardhat node đang chạy
- [ ] Contract đã deploy
- [ ] Backend server đang chạy
- [ ] Test UI mở được trong browser
- [ ] Đăng ký user thành công
- [ ] Admin đăng nhập được
- [ ] Admin phê duyệt user được
- [ ] User đăng nhập được
- [ ] Tạo cuộc bầu cử thành công
- [ ] Đăng ký tham gia thành công
- [ ] Nhận được PIN qua email (hoặc trong response)
- [ ] Xác thực PIN thành công
- [ ] Bỏ phiếu qua MetaMask thành công
- [ ] Lưu gas tracking thành công

## 🐛 Troubleshooting

### Lỗi: "Failed to connect to localhost:1433"

**Nguyên nhân:** SQL Server không chạy hoặc TCP/IP chưa enable

**Giải pháp:**
1. Mở SQL Server Configuration Manager
2. SQL Server Services → SQL Server (MSSQLSERVER) → Start
3. SQL Server Network Configuration → Protocols → TCP/IP → Enable
4. Restart SQL Server

### Lỗi: "Login failed for user 'sa'"

**Nguyên nhân:** Password sai hoặc SQL Authentication chưa enable

**Giải pháp:**
1. Mở SQL Server Management Studio (SSMS)
2. Connect với Windows Authentication
3. Server Properties → Security → SQL Server and Windows Authentication mode
4. Restart SQL Server
5. Đổi password cho user `sa`

### Lỗi: "Invalid login" khi gửi email

**Nguyên nhân:** Chưa dùng App Password

**Giải pháp:**
1. Vào https://myaccount.google.com/apppasswords
2. Tạo App Password mới
3. Copy password đó vào `EMAIL_PASSWORD` trong `.env`

### Lỗi: "could not detect network"

**Nguyên nhân:** Hardhat node không chạy

**Giải pháp:**
```bash
# Terminal riêng
npx hardhat node
```

### Lỗi: "Chưa đến thời gian đăng ký"

**Nguyên nhân:** Thời gian bắt đầu cuộc bầu cử quá xa (> 3 ngày)

**Giải pháp:**
- Tạo lại cuộc bầu cử với thời gian bắt đầu gần hơn (ví dụ: 1 ngày sau)
- Hoặc đợi đến 3 ngày trước khi bắt đầu

### Lỗi: "Cuộc bầu cử chưa bắt đầu" khi xác thực PIN

**Nguyên nhân:** Thời gian hiện tại chưa đến start_time

**Giải pháp:**
- Đợi đến thời gian bắt đầu
- Hoặc tạo lại cuộc bầu cử với start_time là thời gian hiện tại

## 📊 Kiểm tra Database

Nếu muốn xem dữ liệu trong database:

```bash
# Mở SQL Server Management Studio (SSMS)
# Connect với:
# Server: localhost
# Authentication: SQL Server Authentication
# Login: sa
# Password: YourStrong@Passw0rd
```

Chạy queries:
```sql
-- Xem users
SELECT * FROM evoting_db.dbo.users;

-- Xem elections
SELECT * FROM evoting_db.dbo.elections;

-- Xem registrations
SELECT * FROM evoting_db.dbo.election_registrations;

-- Xem gas tracking
SELECT * FROM evoting_db.dbo.gas_tracking;
```

## 🎯 Test nhanh với cURL

Nếu không muốn dùng Test UI:

```bash
# 1. Đăng ký user
curl -X POST http://localhost:3000/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@test.com\",\"password\":\"123456\",\"fullName\":\"Test User\",\"walletAddress\":\"0x70997970C51812dc3A010C7d01b50e0d17dc79C8\"}"

# 2. Đăng nhập admin
curl -X POST http://localhost:3000/api/admin/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"admin\",\"password\":\"admin123\"}"

# Lưu token vào biến (PowerShell)
$token = "eyJhbGc..."

# 3. Phê duyệt user
curl -X POST http://localhost:3000/api/admin/approve-user/1 ^
  -H "Authorization: Bearer $token"
```

---

**Chúc bạn test thành công! 🎉**
