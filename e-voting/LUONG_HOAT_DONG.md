# 🗳️ LUỒNG HOẠT ĐỘNG HỆ THỐNG E-VOTING

## 📊 Tổng quan kiến trúc

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Frontend      │◄────►│   Backend API    │◄────►│   Blockchain    │
│  (HTML/JS)      │      │   (Node.js)      │      │   (Hardhat)     │
│  + MetaMask     │      │   + SQL Server   │      │   EVoting.sol   │
└─────────────────┘      └──────────────────┘      └─────────────────┘
        │                         │                          │
        │                         │                          │
        └─────────────────────────┴──────────────────────────┘
                    Tương tác qua API và Smart Contract
```

---

## 🔄 LUỒNG HOẠT ĐỘNG CHI TIẾT

### 📝 GIAI ĐOẠN 1: ĐĂNG KÝ VÀ PHÊ DUYỆT USER

#### 1.1. User đăng ký tài khoản

**Frontend (test-ui.html):**
```
User điền form:
├── Email
├── Password
├── Họ tên
└── Địa chỉ ví MetaMask
```

**Backend API:** `POST /api/auth/register`
```javascript
1. Kiểm tra email đã tồn tại chưa
2. Kiểm tra địa chỉ ví đã tồn tại chưa
3. Hash password với bcrypt
4. Lưu vào database (is_approved = 0)
5. Gửi email thông báo đăng ký thành công
```

**Database:**
```sql
INSERT INTO users (email, password, wallet_address, full_name, is_approved)
VALUES ('user@test.com', '$2b$10$...', '0x123...', 'Nguyễn Văn A', 0)
```

#### 1.2. Admin phê duyệt user

**Frontend (test-ui.html):**
```
Admin đăng nhập → Xem danh sách user chờ duyệt → Click "Phê duyệt"
```

**Backend API:** `POST /api/admin/approve-user/:userId`
```javascript
1. Cập nhật is_approved = 1
2. Gửi email thông báo đã được phê duyệt
```

**Database:**
```sql
UPDATE users SET is_approved = 1 WHERE id = 1
```

#### 1.3. User đăng nhập

**Backend API:** `POST /api/auth/login`
```javascript
1. Kiểm tra email tồn tại
2. So sánh password với bcrypt
3. Kiểm tra is_approved = 1
4. Tạo JWT token (expires 24h)
5. Trả về token + thông tin user
```

---

### 🏛️ GIAI ĐOẠN 2: TẠO CUỘC BẦU CỬ

#### 2.1. Admin tạo cuộc bầu cử trên Blockchain

**Frontend (index.html):**
```javascript
Admin kết nối MetaMask → Điền form:
├── Title: "Bầu cử chủ tịch"
├── Description: "Bầu cử chủ tịch năm 2024"
├── Start time: 2024-12-01 00:00
└── End time: 2024-12-31 23:59

→ Gọi contract.createElection()
→ MetaMask confirm transaction
→ Nhận election_id = 0 (từ blockchain)
```

**Smart Contract (EVoting.sol):**
```solidity
function createElection(
    string memory _title,
    string memory _description,
    uint256 _startTime,
    uint256 _endTime
) external onlyAdmin {
    elections[electionCount] = Election({
        title: _title,
        description: _description,
        startTime: _startTime,
        endTime: _endTime,
        phase: ElectionPhase.Configuration
    });
    emit ElectionCreated(electionCount, _title, _startTime, _endTime);
    electionCount++;
}
```

#### 2.2. Admin thêm ứng cử viên

**Frontend (index.html):**
```javascript
Admin điền:
├── Election ID: 0
├── Candidate name: "Ứng viên A"
└── Description: "Mô tả ứng viên"

→ Gọi contract.addCandidate()
→ MetaMask confirm
```

**Smart Contract:**
```solidity
function addCandidate(
    uint256 _electionId,
    string memory _name,
    string memory _description
) external onlyAdmin {
    candidates[_electionId][candidateCount] = Candidate({
        name: _name,
        description: _description,
        voteCount: 0
    });
    emit CandidateAdded(_electionId, candidateCount, _name);
    candidateCount++;
}
```

#### 2.3. Admin tạo cuộc bầu cử trong Database

**Backend API:** `POST /api/admin/elections`
```javascript
{
    "electionId": 0,  // ID từ blockchain
    "title": "Bầu cử chủ tịch",
    "description": "Bầu cử chủ tịch năm 2024",
    "startTime": "2024-12-01T00:00:00",
    "endTime": "2024-12-31T23:59:59"
}
```

**Database:**
```sql
INSERT INTO elections (election_id, title, description, start_time, end_time)
VALUES (0, 'Bầu cử chủ tịch', '...', '2024-12-01', '2024-12-31')
```

---

### 🎫 GIAI ĐOẠN 3: ĐĂNG KÝ THAM GIA (3 NGÀY TRƯỚC)

#### 3.1. User xem danh sách cuộc bầu cử

**Backend API:** `GET /api/elections`
```javascript
→ Trả về danh sách tất cả cuộc bầu cử
```

#### 3.2. User click "Đăng ký tham gia"

**Điều kiện:**
```javascript
const now = new Date();
const startTime = new Date(election.start_time);
const threeDaysBefore = new Date(startTime - 3 * 24 * 60 * 60 * 1000);

if (now < threeDaysBefore) {
    return "Chưa đến thời gian đăng ký (3 ngày trước)";
}
if (now > startTime) {
    return "Cuộc bầu cử đã bắt đầu, không thể đăng ký";
}
```

**Backend API:** `POST /api/elections/:electionId/join`
```javascript
1. Kiểm tra thời gian (3 ngày trước)
2. Kiểm tra user đã đăng ký chưa
3. Tạo PIN code (6 số ngẫu nhiên)
4. Đăng ký voter lên blockchain:
   → contract.registerVoter(electionId, walletAddress)
   → Admin wallet trả phí gas
5. Lưu vào database:
   → election_registrations (user_id, election_id, pin_code)
6. Gửi email với PIN code
```

**Smart Contract:**
```solidity
function registerVoter(
    uint256 _electionId,
    address _voter
) external onlyAdmin {
    voters[_electionId][_voter] = true;
    emit VoterRegistered(_electionId, _voter);
}
```

**Database:**
```sql
INSERT INTO election_registrations 
(user_id, election_id, pin_code, registered_to_blockchain)
VALUES (1, 1, '123456', 1)
```

**Email gửi cho user:**
```
Chào Nguyễn Văn A!

Bạn đã đăng ký thành công cho cuộc bầu cử: Bầu cử chủ tịch

Mã PIN của bạn: 123456

Thời gian bắt đầu: 01/12/2024 00:00
Thời gian kết thúc: 31/12/2024 23:59

Lưu ý: Mã PIN chỉ sử dụng được một lần.
```

---

### 🗳️ GIAI ĐOẠN 4: BỎ PHIẾU

#### 4.1. Admin chuyển phase sang Casting

**Frontend (index.html):**
```javascript
Admin → Click "Start Voting"
→ contract.startVoting(electionId)
→ Phase chuyển từ Configuration → Casting
```

#### 4.2. User xác thực PIN

**Backend API:** `POST /api/elections/:electionId/verify-pin`
```javascript
{
    "pinCode": "123456"
}

→ Kiểm tra:
1. PIN đúng không
2. PIN đã dùng chưa (is_pin_used = 0)
3. Cuộc bầu cử đã bắt đầu chưa
4. Cuộc bầu cử chưa kết thúc

→ Đánh dấu PIN đã sử dụng:
UPDATE election_registrations SET is_pin_used = 1
```

#### 4.3. User bỏ phiếu qua MetaMask

**Frontend (index.html):**
```javascript
User kết nối MetaMask với account đã đăng ký
→ Chọn ứng cử viên
→ Click "Bỏ phiếu"
→ contract.castVote(electionId, encryptedVote, commitment)
→ MetaMask confirm (user trả phí gas)
→ Nhận transaction hash
```

**Smart Contract:**
```solidity
function castVote(
    uint256 _electionId,
    bytes calldata _encryptedVote,
    bytes calldata _commitment
) external 
  isRegistered(_electionId)
  hasNotVoted(_electionId)
  inPhase(_electionId, ElectionPhase.Casting) 
{
    ballots[_electionId].push(EncryptedBallot({
        encryptedVote: _encryptedVote,
        commitment: _commitment,
        timestamp: block.timestamp
    }));
    
    hasVoted[_electionId][msg.sender] = true;
    emit VoteCast(_electionId, msg.sender, _encryptedVote, _commitment);
}
```

#### 4.4. Lưu thông tin Gas

**Backend API:** `POST /api/gas-tracking`
```javascript
{
    "electionId": 1,
    "txHash": "0xabc123..."
}

→ Lấy thông tin transaction từ blockchain:
const receipt = await provider.getTransactionReceipt(txHash);
const gasUsed = receipt.gasUsed;
const tx = await provider.getTransaction(txHash);
const gasPrice = tx.gasPrice;
const totalCost = gasUsed * gasPrice;

→ Lưu vào database:
INSERT INTO gas_tracking 
(user_id, election_id, wallet_address, tx_hash, gas_used, gas_price, total_cost)
VALUES (1, 1, '0x123...', '0xabc...', 21000, 20, 0.00042)
```

---

### 🔐 GIAI ĐOẠN 5: ANONYMIZATION & DECRYPTION

#### 5.1. Admin shuffle ballots

**Frontend (index.html):**
```javascript
Admin → Click "Shuffle Ballots"
→ contract.shuffleBallots(electionId, shuffledIndices, zkProof)
→ Phase: Casting → Anonymization
```

**Smart Contract:**
```solidity
function shuffleBallots(
    uint256 _electionId,
    uint256[] calldata _shuffledIndices,
    bytes calldata _zkProof
) external onlyAdmin {
    // Shuffle ballots để ẩn danh
    // Verify ZK proof
    election.phase = ElectionPhase.Anonymization;
}
```

#### 5.2. Admin decrypt và tally

**Frontend (index.html):**
```javascript
Admin → Click "Decrypt & Tally"
→ contract.decryptAndTally(electionId, decryptedVotes, zkProof)
→ Phase: Anonymization → Decryption
```

**Smart Contract:**
```solidity
function decryptAndTally(
    uint256 _electionId,
    uint256[] calldata _decryptedVotes,
    bytes calldata _zkProof
) external onlyAdmin {
    // Decrypt votes
    // Tally results
    for (uint256 i = 0; i < _decryptedVotes.length; i++) {
        candidates[_electionId][_decryptedVotes[i]].voteCount++;
    }
    election.phase = ElectionPhase.Completed;
}
```

---

### 💰 GIAI ĐOẠN 6: HOÀN PHÍ GAS

#### 6.1. Admin xem danh sách gas cần hoàn

**Backend API:** `GET /api/admin/gas-refunds/:electionId`
```javascript
→ Trả về danh sách:
[
    {
        id: 1,
        user_id: 1,
        full_name: "Nguyễn Văn A",
        wallet_address: "0x123...",
        total_cost: "0.00042",
        is_refunded: false
    }
]
```

#### 6.2. Admin hoàn phí

**Backend API:** `POST /api/admin/refund-gas/:gasTrackingId`
```javascript
1. Lấy thông tin gas tracking
2. Gửi ETH từ admin wallet:
   const tx = await adminWallet.sendTransaction({
       to: user.wallet_address,
       value: ethers.parseEther(totalCost)
   });
3. Cập nhật database:
   UPDATE gas_tracking 
   SET is_refunded = 1, refund_tx_hash = '0x...', refunded_at = NOW()
```

---

## 📊 SƠ ĐỒ TỔNG QUAN

```
┌─────────────────────────────────────────────────────────────────┐
│                    LUỒNG HOẠT ĐỘNG E-VOTING                     │
└─────────────────────────────────────────────────────────────────┘

1. ĐĂNG KÝ & PHÊ DUYỆT
   User đăng ký → Admin phê duyệt → User đăng nhập
   
2. TẠO CUỘC BẦU CỬ
   Admin tạo election (blockchain) → Thêm candidates → Tạo election (database)
   
3. ĐĂNG KÝ THAM GIA (3 ngày trước)
   User click "Join" → Backend đăng ký lên blockchain → Tạo PIN → Gửi email
   
4. BỎ PHIẾU
   User nhập PIN → Xác thực → Bỏ phiếu qua MetaMask → Lưu gas tracking
   
5. ANONYMIZATION & DECRYPTION
   Admin shuffle ballots → Admin decrypt & tally → Kết quả
   
6. HOÀN PHÍ GAS
   Admin xem danh sách → Admin hoàn phí → User nhận ETH
```

---

## 🔑 ĐIỂM QUAN TRỌNG

### Bảo mật
- ✅ Password hash với bcrypt (10 rounds)
- ✅ JWT token authentication (expires 24h)
- ✅ PIN code unique cho mỗi user/election
- ✅ PIN chỉ dùng được 1 lần
- ✅ Kiểm tra thời gian đăng ký (3 ngày trước)
- ✅ Kiểm tra voter đã bỏ phiếu chưa (trên blockchain)

### Phân quyền
- **Admin:** Tạo election, thêm candidates, phê duyệt user, hoàn phí gas
- **User:** Đăng ký, đăng ký tham gia election, bỏ phiếu

### Blockchain
- **Smart Contract:** Lưu elections, candidates, votes (encrypted)
- **Events:** VoteCast, VoterRegistered (để backend tracking)
- **Phases:** Configuration → Casting → Anonymization → Decryption → Completed

### Database
- **users:** Thông tin user, trạng thái phê duyệt
- **admins:** Thông tin admin
- **elections:** Danh sách cuộc bầu cử
- **election_registrations:** Đăng ký tham gia + PIN codes
- **gas_tracking:** Theo dõi gas để hoàn phí

---

## 📝 API ENDPOINTS

### Authentication
- `POST /api/auth/register` - Đăng ký user
- `POST /api/auth/login` - Đăng nhập user
- `POST /api/admin/login` - Đăng nhập admin

### Admin
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

---

**Tài liệu chi tiết:** [`LUONG_XAC_THUC.md`](../LUONG_XAC_THUC.md:1)
