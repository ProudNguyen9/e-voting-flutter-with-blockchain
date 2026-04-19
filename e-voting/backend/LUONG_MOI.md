# LUỒNG HOẠT ĐỘNG MỚI - E-VOTING BACKEND

## 📋 Tổng quan thay đổi

### ✅ Thay đổi chính:
1. **User đăng ký tài khoản → TỰ ĐỘNG DUYỆT** (không cần admin phê duyệt)
2. **User đăng ký tham gia bầu cử → CẦN ADMIN DUYỆT** (admin duyệt mới nhận PIN)

---

## 🔄 Luồng hoạt động chi tiết

### 1️⃣ ĐĂNG KỶ TÀI KHOẢN (Tự động duyệt)

**Endpoint:** `POST /api/auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "Nguyễn Văn A",
  "walletAddress": "0x..."
}
```

**Xử lý:**
- Kiểm tra email và wallet chưa tồn tại
- Hash password với bcrypt
- **Lưu vào DB với `is_approved = 1`** (tự động duyệt)
- Gửi email thông báo đăng ký thành công

**Response:**
```json
{
  "message": "Đăng ký thành công! Bạn có thể đăng nhập ngay.",
  "success": true
}
```

---

### 2️⃣ ĐĂNG NHẬP USER

**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Xử lý:**
- Kiểm tra email và password
- Kiểm tra `is_approved = 1` (luôn đúng vì tự động duyệt)
- Tạo JWT token

**Response:**
```json
{
  "message": "Đăng nhập thành công",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "walletAddress": "0x..."
  }
}
```

---

### 3️⃣ ĐĂNG KÝ THAM GIA BẦU CỬ (Cần admin duyệt)

**Endpoint:** `POST /api/elections/:electionId/join`

**Headers:**
```
Authorization: Bearer <user_token>
```

**Xử lý:**
- Kiểm tra thời gian đăng ký (3 ngày trước khi bắt đầu)
- Kiểm tra chưa đăng ký trước đó
- **Lưu vào DB với `is_approved = 0`** (chờ admin duyệt)
- **KHÔNG đăng ký lên blockchain** (chờ admin duyệt)
- **KHÔNG tạo PIN** (chờ admin duyệt)
- Gửi email thông báo chờ duyệt

**Response:**
```json
{
  "message": "Đăng ký thành công! Vui lòng đợi admin phê duyệt.",
  "success": true
}
```

---

### 4️⃣ ADMIN XEM DANH SÁCH ĐĂNG KÝ CHỜ DUYỆT

**Endpoint:** `GET /api/admin/pending-registrations`

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "registrations": [
    {
      "id": 1,
      "user_id": 5,
      "election_id": 1,
      "registered_at": "2024-01-15T10:30:00",
      "email": "user@example.com",
      "full_name": "Nguyễn Văn A",
      "wallet_address": "0x...",
      "election_title": "Bầu cử chủ tịch",
      "start_time": "2024-01-20T08:00:00",
      "end_time": "2024-01-20T18:00:00"
    }
  ]
}
```

---

### 5️⃣ ADMIN PHÊ DUYỆT ĐĂNG KÝ BẦU CỬ

**Endpoint:** `POST /api/admin/approve-registration/:registrationId`

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Xử lý:**
1. Lấy thông tin đăng ký từ DB
2. **Tạo PIN code** (6 số ngẫu nhiên)
3. **Đăng ký voter lên blockchain** (`contract.registerVoter()`)
4. Cập nhật DB:
   - `is_approved = 1`
   - `pin_code = <generated_pin>`
   - `registered_to_blockchain = 1`
   - `approved_at = GETDATE()`
5. **Gửi email với PIN code** cho user

**Response:**
```json
{
  "message": "Phê duyệt đăng ký thành công",
  "success": true
}
```

**Email gửi cho user:**
```
Chúc mừng Nguyễn Văn A!

Đăng ký của bạn cho cuộc bầu cử "Bầu cử chủ tịch" đã được phê duyệt.

Mã PIN của bạn là: 123456

Vui lòng giữ mã PIN này để xác thực khi bỏ phiếu.
```

---

### 6️⃣ USER XÁC THỰC PIN TRƯỚC KHI BỎ PHIẾU

**Endpoint:** `POST /api/elections/:electionId/verify-pin`

**Headers:**
```
Authorization: Bearer <user_token>
```

**Request:**
```json
{
  "pinCode": "123456"
}
```

**Xử lý:**
- Kiểm tra PIN đúng
- **Kiểm tra `is_approved = 1`** (đã được admin duyệt)
- Kiểm tra PIN chưa sử dụng
- Kiểm tra thời gian bỏ phiếu
- Đánh dấu PIN đã sử dụng

**Response:**
```json
{
  "message": "Xác thực PIN thành công! Bạn có thể bỏ phiếu.",
  "success": true
}
```

---

## 🔐 ADMIN LOGIN

**Endpoint:** `POST /api/admin/login`

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Thông tin admin mặc định:**
- Username: `admin`
- Password: `admin123`
- Email: `admin@evoting.com`

**Tạo admin mới:**
```bash
cd backend
npm run create-admin
```

---

## 📊 So sánh luồng cũ vs mới

| Bước | Luồng CŨ | Luồng MỚI |
|------|----------|-----------|
| User đăng ký tài khoản | Chờ admin duyệt | ✅ Tự động duyệt |
| User đăng nhập | Cần admin duyệt trước | ✅ Đăng nhập ngay |
| User đăng ký bầu cử | Tự động nhận PIN | ⏳ Chờ admin duyệt |
| Admin duyệt | Duyệt tài khoản user | ✅ Duyệt đăng ký bầu cử |
| Nhận PIN | Ngay khi đăng ký bầu cử | ✅ Sau khi admin duyệt |
| Đăng ký blockchain | Ngay khi đăng ký bầu cử | ✅ Khi admin duyệt |

---

## 🗂️ Cấu trúc Database

### Bảng `users`
```sql
- id (PK)
- email (UNIQUE)
- password (hashed)
- wallet_address (UNIQUE)
- full_name
- is_approved (BIT) -- Luôn = 1 (tự động duyệt)
- created_at
```

### Bảng `election_registrations`
```sql
- id (PK)
- user_id (FK)
- election_id (FK)
- pin_code (NULL cho đến khi admin duyệt)
- is_approved (BIT) -- 0: chờ duyệt, 1: đã duyệt
- is_pin_used (BIT)
- registered_to_blockchain (BIT) -- 0 cho đến khi admin duyệt
- registered_at
- approved_at (NULL cho đến khi admin duyệt)
```

---

## 🧪 Test với UI

1. **Mở test UI:** `http://localhost:3000/test-ui.html`

2. **Test luồng đầy đủ:**
   - Tab "Đăng ký User" → Đăng ký tài khoản → Thành công ngay
   - Tab "Đăng nhập User" → Đăng nhập → Nhận token
   - Tab "Đăng nhập Admin" → Đăng nhập (admin/admin123) → Nhận token
   - Tab "Admin Panel" → Tạo cuộc bầu cử
   - Tab "Cuộc bầu cử" → Đăng ký tham gia → Chờ admin duyệt
   - Tab "Admin Panel" → Tải danh sách đăng ký chờ duyệt → Phê duyệt
   - Kiểm tra email → Nhận PIN
   - Tab "Bỏ phiếu" → Nhập PIN → Xác thực thành công

---

## ✅ Lợi ích của luồng mới

1. **UX tốt hơn:** User đăng ký xong có thể đăng nhập ngay, không phải chờ
2. **Bảo mật tốt hơn:** Admin kiểm soát ai được tham gia bầu cử cụ thể
3. **Giảm tải admin:** Admin chỉ duyệt đăng ký bầu cử, không duyệt từng tài khoản
4. **Linh hoạt:** User có thể đăng ký nhiều cuộc bầu cử khác nhau
5. **Minh bạch:** Mỗi cuộc bầu cử có danh sách người tham gia riêng

---

## 🔧 API Endpoints tóm tắt

### User APIs
- `POST /api/auth/register` - Đăng ký tài khoản (tự động duyệt)
- `POST /api/auth/login` - Đăng nhập user
- `GET /api/elections` - Xem danh sách cuộc bầu cử
- `POST /api/elections/:id/join` - Đăng ký tham gia bầu cử (chờ admin duyệt)
- `POST /api/elections/:id/verify-pin` - Xác thực PIN trước khi bỏ phiếu
- `POST /api/elections/:id/save-gas` - Lưu thông tin gas sau khi bỏ phiếu

### Admin APIs
- `POST /api/admin/login` - Đăng nhập admin
- `GET /api/admin/pending-registrations` - Xem đăng ký bầu cử chờ duyệt
- `POST /api/admin/approve-registration/:id` - Phê duyệt đăng ký bầu cử
- `POST /api/admin/elections` - Tạo cuộc bầu cử mới
- `POST /api/admin/refund-gas/:userId/:electionId` - Hoàn gas cho user

---

## 📝 Ghi chú quan trọng

1. **Admin password:** Đổi password admin sau khi setup lần đầu
2. **PIN security:** PIN chỉ gửi qua email, không hiển thị trên UI
3. **Blockchain sync:** Đảm bảo blockchain đang chạy trước khi admin duyệt
4. **Email config:** Cấu hình SMTP trong `.env` để gửi email
5. **3 days rule:** User chỉ có thể đăng ký từ 3 ngày trước khi bầu cử bắt đầu
