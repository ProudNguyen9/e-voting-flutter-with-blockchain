# LUỒNG XÁC THỰC VÀ BỎ PHIẾU - HỆ THỐNG E-VOTING

## 📋 TỔNG QUAN

Hệ thống cho phép user đăng ký 1 lần, sau đó tham gia nhiều cuộc bầu cử khác nhau. Mỗi cuộc bầu cử có mã PIN riêng cho từng user.

**Đặc điểm:** User có thể đăng ký và nhận PIN **TRƯỚC 3 NGÀY** khi bầu cử bắt đầu để giảm tải server.

---

## 🔄 LUỒNG CHI TIẾT

### **PHASE 1: ĐĂNG KÝ TÀI KHOẢN (1 LẦN DUY NHẤT)**

#### 1.1. User đăng ký
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "Nguyễn Văn A",
  "citizenId": "001234567890",
  "walletAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
}
```

**Backend xử lý:**
1. Validate dữ liệu
2. Hash password
3. Lưu database với `status = 'pending'`
4. Tạo token xác thực email
5. Gửi email xác thực

**Email template:**
```
Xin chào Nguyễn Văn A,

Vui lòng click link dưới đây để xác thực email:
https://evoting.com/verify-email?token=abc123...

Link có hiệu lực trong 24 giờ.
```

#### 1.2. User xác thực email
```http
GET /api/auth/verify-email?token=abc123...
```

**Backend xử lý:**
1. Kiểm tra token hợp lệ
2. Update `status = 'verified'`
3. Redirect đến trang thông báo

#### 1.3. Admin phê duyệt
```http
POST /api/admin/users/{userId}/approve
Authorization: Bearer {admin_token}
```

**Backend xử lý:**
1. Kiểm tra CCCD, thông tin
2. Update `status = 'approved'`
3. Gửi email thông báo

**→ Tài khoản sẵn sàng cho TẤT CẢ cuộc bầu cử**

---

### **PHASE 2: XEM DANH SÁCH CUỘC BẦU CỬ**

#### 2.1. User đăng nhập
```http
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "walletAddress": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
  }
}
```

#### 2.2. Lấy danh sách cuộc bầu cử
```http
GET /api/elections
Authorization: Bearer {user_token}
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "Bầu Chủ Tịch Hội Sinh Viên 2024",
    "description": "Bầu chủ tịch nhiệm kỳ 2024-2025",
    "startTime": "2024-01-15T00:00:00Z",
    "endTime": "2024-01-20T23:59:59Z",
    "status": "ongoing",
    "totalVoters": 1234,
    "totalVoted": 567,
    "userStatus": {
      "isRegistered": false,
      "hasVoted": false,
      "canJoin": true
    }
  },
  {
    "id": 2,
    "title": "Bầu Ban Đại Diện Lớp",
    "startTime": "2024-02-10T00:00:00Z",
    "endTime": "2024-02-15T23:59:59Z",
    "status": "upcoming",
    "userStatus": {
      "canJoin": false,
      "reason": "Chưa đến thời gian"
    }
  }
]
```

---

### **PHASE 3: THAM GIA BẦU CỬ**

#### 3.1. User click "Tham gia bỏ phiếu"
```http
POST /api/voter/join-election
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "electionId": 1
}
```

#### 3.2. Backend xử lý (QUAN TRỌNG)

**Bước 1: Kiểm tra điều kiện**
```javascript
// 1. Kiểm tra user
if (user.status !== 'approved') {
  return error("Tài khoản chưa được phê duyệt");
}

// 2. Kiểm tra thời gian
const now = new Date();
const election = await getElection(electionId);

// Cho phép đăng ký TRƯỚC 3 NGÀY
const allowRegisterFrom = new Date(election.startTime);
allowRegisterFrom.setDate(allowRegisterFrom.getDate() - 3);

if (now < allowRegisterFrom) {
  const daysLeft = Math.ceil((allowRegisterFrom - now) / (1000 * 60 * 60 * 24));
  return error(`Chưa mở đăng ký. Vui lòng quay lại sau ${daysLeft} ngày.`);
}

if (now > election.endTime) {
  return error("Cuộc bầu cử đã kết thúc");
}

// 3. Kiểm tra đã đăng ký chưa
const isRegistered = await contract.isRegisteredVoter(
  electionId, 
  user.walletAddress
);

if (isRegistered) {
  return error("Bạn đã đăng ký cuộc bầu cử này rồi");
}

// 4. Kiểm tra đã vote chưa
const hasVoted = await contract.hasVoted(
  electionId,
  user.walletAddress
);

if (hasVoted) {
  return error("Bạn đã bỏ phiếu rồi");
}
```

**Bước 2: Đăng ký lên blockchain**
```javascript
// Gọi smart contract
const tx = await contract.registerVoter(
  BigInt(electionId),
  user.walletAddress
);

await tx.wait();

// Lưu vào database
await db.voter_registrations.create({
  user_id: user.id,
  election_id: electionId,
  registered_on_blockchain: true,
  registration_tx_hash: tx.hash
});
```

**Bước 3: Tạo mã PIN riêng**
```javascript
// Tạo PIN 6 số unique
const pinCode = generatePIN(); // "123456"

// Thời hạn = Thời gian kết thúc bầu cử
const expiresAt = election.endTime;

// Tính số ngày còn lại đến khi bắt đầu
const daysUntilStart = Math.ceil((election.startTime - now) / (1000 * 60 * 60 * 24));

// Lưu database
await db.voting_pins.create({
  user_id: user.id,
  election_id: electionId,
  pin_code: pinCode,
  expires_at: expiresAt,
  used: false,
  can_vote_from: election.startTime // Chỉ được vote từ thời điểm này
});
```

**Bước 4: Gửi email**
```javascript
// Tạo nội dung email khác nhau tùy thời điểm
let emailContent = '';

if (now < election.startTime) {
  // Đăng ký TRƯỚC khi bắt đầu
  const daysUntilStart = Math.ceil((election.startTime - now) / (1000 * 60 * 60 * 24));
  emailContent = `
    <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
      <strong>⏰ Lưu ý:</strong> Cuộc bầu cử sẽ bắt đầu sau <strong>${daysUntilStart} ngày</strong>.
      <br>Bạn chỉ có thể bỏ phiếu từ <strong>${formatDate(election.startTime)}</strong>.
    </div>
  `;
} else {
  // Đăng ký KHI đang diễn ra
  emailContent = `
    <div style="background: #d4edda; padding: 15px; border-radius: 5px; margin: 20px 0;">
      <strong>✅ Cuộc bầu cử đang diễn ra!</strong>
      <br>Bạn có thể bỏ phiếu ngay bây giờ.
    </div>
  `;
}

const emailHtml = `
  <h2>Mã PIN Tham Gia Bỏ Phiếu</h2>
  <p>Xin chào ${user.fullName},</p>
  <p>Bạn đã đăng ký thành công cuộc bầu cử:</p>
  <h3>${election.title}</h3>
  
  ${emailContent}
  
  <p>Mã PIN của bạn để tham gia bỏ phiếu là:</p>
  <h1 style="color: #007bff; font-size: 48px; letter-spacing: 5px;">
    ${pinCode}
  </h1>
  <p><strong>Mã này có hiệu lực đến: ${formatDate(expiresAt)}</strong></p>
  <p style="color: #dc3545;"><strong>⚠️ Vui lòng giữ mã này bí mật và không chia sẻ với ai!</strong></p>
  <hr>
  <p>Thông tin bầu cử:</p>
  <ul>
    <li><strong>Thời gian bỏ phiếu:</strong> ${formatDate(election.startTime)} - ${formatDate(election.endTime)}</li>
    <li><strong>Địa chỉ ví của bạn:</strong> ${user.walletAddress}</li>
  </ul>
  <p style="color: #666; font-size: 12px;">
    Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.
  </p>
`;

await sendEmail(
  user.email,
  `Mã PIN - ${election.title}`,
  emailHtml
);
```

**Response:**
```json
{
  "success": true,
  "message": "Đã đăng ký thành công! Mã PIN đã được gửi qua email.",
  "election": {
    "id": 1,
    "title": "Bầu Chủ Tịch Hội Sinh Viên 2024"
  },
  "pinExpiresAt": "2024-01-20T23:59:59Z",
  "registrationTxHash": "0x123abc..."
}
```

---

### **PHASE 4: NHẬP MÃ PIN VÀ VÀO VOTE**

#### 4.1. User click "Bỏ phiếu" → Hiện form nhập PIN

#### 4.2. User nhập PIN
```http
POST /api/voter/verify-pin
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "electionId": 1,
  "pinCode": "123456"
}
```

#### 4.3. Backend xác thực
```javascript
// 1. Tìm PIN
const pin = await db.voting_pins.findOne({
  user_id: user.id,
  election_id: electionId,
  pin_code: pinCode,
  used: false
});

if (!pin) {
  return error("Mã PIN không đúng hoặc đã được sử dụng");
}

// 2. Kiểm tra hết hạn
const now = new Date();
if (now > new Date(pin.expires_at)) {
  return error("Mã PIN đã hết hạn");
}

// 3. Kiểm tra đã đến thời gian vote chưa
if (now < new Date(pin.can_vote_from)) {
  const hoursLeft = Math.ceil((new Date(pin.can_vote_from) - now) / (1000 * 60 * 60));
  return error(`Cuộc bầu cử chưa bắt đầu. Vui lòng quay lại sau ${hoursLeft} giờ.`);
}

// 3. Đánh dấu đã sử dụng
await db.voting_pins.update(
  { id: pin.id },
  { used: true, used_at: now }
);

// 4. Tạo voting token (30 phút)
const votingToken = jwt.sign(
  {
    userId: user.id,
    electionId: electionId,
    walletAddress: user.walletAddress,
    type: 'voting',
    pinId: pin.id
  },
  JWT_SECRET,
  { expiresIn: '30m' }
);
```

**Response:**
```json
{
  "success": true,
  "message": "Xác thực thành công! Bạn có 30 phút để bỏ phiếu.",
  "votingToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 1800,
  "election": {
    "id": 1,
    "title": "Bầu Chủ Tịch Hội Sinh Viên 2024"
  }
}
```

---

### **PHASE 5: BỎ PHIẾU**

#### 5.1. Frontend redirect đến trang vote
- Hiển thị danh sách ứng viên
- User chọn ứng viên
- Kết nối MetaMask
- Ký transaction
- Gửi lên blockchain

#### 5.2. Backend listen event
```javascript
contract.on("VoteCast", async (electionId, voter, commitment, timestamp, event) => {
  // Lưu gas cost để hoàn phí sau
  const receipt = await provider.getTransactionReceipt(event.log.transactionHash);
  const gasCost = receipt.gasUsed * receipt.gasPrice;
  
  await db.gas_refunds.create({
    election_id: electionId,
    voter_address: voter,
    tx_hash: event.log.transactionHash,
    gas_cost: gasCost.toString()
  });
});
```

---

## 🎯 ĐẶC ĐIỂM QUAN TRỌNG

### 1. Cho phép đăng ký TRƯỚC 3 NGÀY
```javascript
const allowRegisterFrom = new Date(election.startTime);
allowRegisterFrom.setDate(allowRegisterFrom.getDate() - 3);

// User có thể đăng ký từ 3 ngày trước
// Nhưng chỉ vote được khi bầu cử bắt đầu
```

### 2. Mỗi user + mỗi cuộc = 1 PIN riêng
```
User A - Election 1: PIN = "123456"
User A - Election 2: PIN = "789012"
User B - Election 1: PIN = "345678"
```

### 3. PIN có thời hạn = Thời gian kết thúc bầu cử
```javascript
pin.expires_at = election.endTime
pin.can_vote_from = election.startTime
```

### 4. Đăng ký blockchain ĐÚNG LÚC user muốn tham gia
```
❌ KHÔNG: Admin đăng ký trước tất cả
✅ ĐÚNG: User click "Tham gia" → Backend đăng ký ngay
```

### 5. Kiểm tra thời gian tự động
```javascript
// Cho phép đăng ký trước 3 ngày
if (now < allowRegisterFrom) → "Chưa mở đăng ký"

// Cho phép vote khi bắt đầu
if (now < election.startTime) → "Đã có PIN, chờ đến giờ vote"

// Hết hạn
if (now > election.endTime) → "Đã kết thúc"
```

### 6. Voting token có thời hạn ngắn (30 phút)
```
Sau khi nhập PIN đúng → 30 phút để vote
```

---

## 📊 DATABASE SCHEMA

### Table: users
```sql
id              INTEGER PRIMARY KEY
email           TEXT UNIQUE
password_hash   TEXT
full_name       TEXT
citizen_id      TEXT UNIQUE
wallet_address  TEXT UNIQUE
status          TEXT (pending/verified/approved/rejected)
email_verified  BOOLEAN DEFAULT 0
created_at      DATETIME
```

### Table: voter_registrations
```sql
id                          INTEGER PRIMARY KEY
user_id                     INTEGER
election_id                 INTEGER
registered_on_blockchain    BOOLEAN
registration_tx_hash        TEXT
created_at                  DATETIME
UNIQUE(user_id, election_id)
```

### Table: voting_pins
```sql
id              INTEGER PRIMARY KEY
user_id         INTEGER
election_id     INTEGER
pin_code        TEXT (6 digits)
expires_at      DATETIME
can_vote_from   DATETIME (thời gian bắt đầu được vote)
used            BOOLEAN DEFAULT 0
used_at         DATETIME
created_at      DATETIME
UNIQUE(user_id, election_id, pin_code)
```

---

## 🔐 BẢO MẬT

1. **Email verification** - Xác thực email thật
2. **Admin approval** - Kiểm tra CCCD
3. **Time-based PIN** - Hết hạn theo bầu cử
4. **One-time PIN** - Chỉ dùng 1 lần
5. **Short-lived voting token** - 30 phút
6. **Blockchain verification** - Không vote 2 lần

---

## 📝 NOTES

- User đăng ký tài khoản 1 lần, dùng cho nhiều cuộc
- Mỗi cuộc bầu cử user phải "Tham gia" riêng
- **User có thể đăng ký và nhận PIN TRƯỚC 3 NGÀY** để giảm tải server
- Nhưng chỉ được vote KHI bầu cử bắt đầu
- Mỗi lần tham gia = 1 PIN mới qua email
- PIN khác nhau cho mỗi user, mỗi cuộc
- Backend tự động check thời gian
- Không cần admin đăng ký thủ công từng user

## 🎯 LỢI ÍCH CỦA "ĐĂNG KÝ TRƯỚC 3 NGÀY"

1. **Giảm tải server:** User đăng ký dàn trải, không tập trung ngày đầu
2. **User có thời gian:** Không vội vàng, chuẩn bị kỹ
3. **Giảm lỗi:** Ít congestion, transaction success rate cao hơn
4. **Linh hoạt:** User tự chọn thời điểm đăng ký
5. **Vẫn bảo mật:** PIN chỉ dùng được khi bầu cử bắt đầu
