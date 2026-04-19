# E-Voting - Hệ thống Bỏ phiếu Điện tử Blockchain

Hệ thống bỏ phiếu điện tử phi tập trung sử dụng Smart Contract và giao diện web thuần (không cần backend API).

## 🏗️ Kiến trúc

```
Frontend (HTML/JS) ←→ MetaMask ←→ Smart Contract (Blockchain)
```

**Không có backend API** - Tất cả tương tác thông qua MetaMask và ethers.js

## 📁 Cấu trúc

```
e-voting/
├── contracts/
│   └── EVoting.sol              # Smart contract bỏ phiếu
├── frontend/
│   ├── index.html               # Giao diện web
│   └── js/
│       ├── contract.js          # Tương tác blockchain
│       └── app.js               # Logic UI
├── scripts/
│   └── deploy-evoting.js        # Deploy & test
└── hardhat.config.ts            # Cấu hình Hardhat
```

## 🚀 Quick Start

### 1. Cài đặt

```bash
cd e-voting
npm install
```

### 2. Chạy Hardhat Node

Terminal 1:
```bash
npx hardhat node
```

Hardhat sẽ khởi động local blockchain và hiển thị danh sách accounts:

```
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/

Accounts
========

WARNING: These accounts, and their private keys, are publicly known.
Any funds sent to them on Mainnet or any other live network WILL BE LOST.

Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

Account #2: 0x3C44CdDdB6a900fa2b585dd299e03d12fa4293BC (10000 ETH)
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
...
```

**Lưu lại các private keys này để import vào MetaMask!**

### 3. Deploy Contract

Terminal 2:
```bash
npx hardhat run scripts/deploy-evoting.js --network localhost
```

Script sẽ deploy contract và hiển thị địa chỉ:

```
✅ Contract deployed tại: 0xa513e6e4b8f2a923d98304ec87f64353c4d5c853
```

**Lưu lại địa chỉ contract này!**

### 4. Cấu hình MetaMask (Chi tiết)

#### 4.1. Cài đặt MetaMask

Nếu chưa có MetaMask:
1. Truy cập: https://metamask.io/
2. Click **"Download"** → Chọn trình duyệt của bạn (Chrome/Firefox/Edge)
3. Cài đặt extension
4. Tạo ví mới hoặc import ví hiện có

#### 4.2. Thêm Hardhat Network vào MetaMask

**Bước 1:** Mở MetaMask extension

**Bước 2:** Click vào dropdown network (góc trên bên trái, mặc định là "Ethereum Mainnet")

**Bước 3:** Kéo xuống dưới cùng → Click **"Add network"** hoặc **"Thêm mạng"**

**Bước 4:** Click **"Add a network manually"** (Thêm mạng thủ công)

**Bước 5:** Điền thông tin network:

| Trường | Giá trị |
|--------|---------|
| **Network Name** | `Hardhat Local` |
| **New RPC URL** | `http://127.0.0.1:8545` |
| **Chain ID** | `31337` |
| **Currency Symbol** | `ETH` |
| **Block Explorer URL** | (để trống) |

**Bước 6:** Click **"Save"** → MetaMask sẽ tự động chuyển sang network Hardhat Local

**Kiểm tra:** Dropdown network phải hiển thị "Hardhat Local"

#### 4.3. Import Tài khoản Test từ Hardhat

Bạn cần import ít nhất 2-3 accounts để test:
- **Account #0**: Admin (tạo bầu cử, thêm ứng viên, đăng ký cử tri)
- **Account #1-5**: Cử tri (bỏ phiếu)

**Cách import account:**

**Bước 1:** Mở MetaMask → Click vào **icon tài khoản** (hình tròn góc trên bên phải)

**Bước 2:** Click **"Import Account"** hoặc **"Nhập tài khoản"**

**Bước 3:** Chọn type: **"Private Key"**

**Bước 4:** Copy private key từ terminal Hardhat Node

Ví dụ import Account #0 (Admin):
```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**Bước 5:** Paste vào ô "Private Key" → Click **"Import"**

**Bước 6:** Đổi tên account (tùy chọn):
- Click vào icon 3 chấm bên cạnh tên account
- Chọn "Account details"
- Click vào icon bút chì → Đổi tên thành "Admin" hoặc "Voter 1"

**Lặp lại** để import thêm Account #1, #2, #3... (dùng private keys tương ứng)

#### 4.4. Kiểm tra kết nối

Sau khi import xong:

✅ **Network**: Phải là "Hardhat Local"  
✅ **Số dư**: Mỗi account phải có **10000 ETH**  
✅ **Địa chỉ**: Khớp với địa chỉ trong terminal Hardhat Node  

**Nếu không thấy số dư:**
- Kiểm tra lại RPC URL: `http://127.0.0.1:8545`
- Kiểm tra Chain ID: `31337`
- Đảm bảo Hardhat Node đang chạy (Terminal 1)
- Thử refresh MetaMask (Settings → Advanced → Reset Account)

#### 4.5. Chuyển đổi giữa các accounts

Để test với nhiều vai trò khác nhau:
1. Click vào icon tài khoản (góc trên)
2. Chọn account muốn dùng (Admin, Voter 1, Voter 2...)
3. Frontend sẽ tự động nhận diện account hiện tại

**⚠️ CẢNH BÁO BẢO MẬT:**
- Private keys này là **PUBLIC** và chỉ dùng cho **TEST LOCAL**
- **KHÔNG BAO GIỜ** gửi tiền thật vào các địa chỉ này
- **KHÔNG BAO GIỜ** dùng các private keys này trên Mainnet hoặc Testnet công khai
- Mọi tiền gửi vào sẽ **MẤT VĨNH VIỄN**

### 5. Mở Frontend

Mở `frontend/index.html` bằng Live Server hoặc:

```bash
cd frontend
python -m http.server 8000
```

Truy cập: `http://localhost:8000`

## 🎯 Sử dụng

### Bước 1: Kết nối MetaMask
1. Mở frontend trong trình duyệt
2. Click nút **"Kết nối MetaMask"**
3. MetaMask sẽ popup → Click **"Connect"**
4. Chọn account muốn kết nối (Admin hoặc Voter)

### Bước 2: Nhập địa chỉ Contract
1. Paste địa chỉ contract từ bước deploy vào ô input
2. Click **"Kết nối Contract"**
3. Giao diện sẽ load thông tin bầu cử

### Bước 3: Admin - Tạo bầu cử
1. Chuyển sang account **Admin** trong MetaMask
2. Điền thông tin bầu cử:
   - Tiêu đề: "Bầu cử Chủ tịch Hội Sinh viên 2024"
   - Mô tả: "Bầu chọn Chủ tịch nhiệm kỳ 2024-2025"
   - Thời gian bắt đầu và kết thúc
3. Click **"Tạo bầu cử"** → Xác nhận transaction trong MetaMask

### Bước 4: Admin - Thêm ứng viên
1. Điền thông tin ứng viên:
   - Tên: "Nguyễn Văn An"
   - Mô tả: "Ứng viên độc lập - Kinh nghiệm 3 năm"
   - URL ảnh (tùy chọn)
2. Click **"Thêm ứng viên"** → Xác nhận transaction
3. Lặp lại để thêm nhiều ứng viên

### Bước 5: Admin - Đăng ký cử tri
1. Nhập địa chỉ ví của cử tri (copy từ MetaMask)
2. Click **"Đăng ký cử tri"** → Xác nhận transaction
3. Hoặc dùng **"Đăng ký hàng loạt"** để thêm nhiều cử tri cùng lúc

### Bước 6: Admin - Bắt đầu bỏ phiếu
1. Click **"Bắt đầu bỏ phiếu"** → Xác nhận transaction
2. Trạng thái chuyển sang **"Casting"**

### Bước 7: Cử tri - Bỏ phiếu
1. Chuyển sang account **Voter** trong MetaMask
2. Xem danh sách ứng viên
3. Click **"Bỏ phiếu"** cho ứng viên mong muốn → Xác nhận transaction
4. Mỗi cử tri chỉ được bỏ phiếu **1 lần**

### Bước 8: Admin - Kết thúc và đếm phiếu
1. Chuyển về account **Admin**
2. Click **"Kết thúc bỏ phiếu"**
3. Click **"Xáo trộn phiếu"** (bảo mật)
4. Click **"Giải mã và đếm phiếu"**

### Bước 9: Xem kết quả
1. Dashboard hiển thị kết quả chi tiết
2. Biểu đồ phân bố phiếu
3. Lịch sử giao dịch có thể kiểm tra trên blockchain

## 🔐 Quy trình 5 giai đoạn

1. **Configuration** - Thiết lập bầu cử, thêm ứng viên, đăng ký cử tri
2. **Casting** - Cử tri bỏ phiếu (phiếu được mã hóa)
3. **Anonymization** - Xáo trộn phiếu để bảo vệ quyền riêng tư
4. **Decryption** - Giải mã và đếm phiếu
5. **Auditing** - Xem kết quả và kiểm tra tính minh bạch

## ✨ Tính năng

✅ Bỏ phiếu mã hóa end-to-end  
✅ Xáo trộn phiếu bảo mật (shuffle)  
✅ Minh bạch, có thể kiểm tra (verifiable)  
✅ Không thể bỏ phiếu 2 lần  
✅ Chỉ cử tri đã đăng ký mới được vote  
✅ Giao diện thân thiện, dễ sử dụng  
✅ Không cần backend API  
✅ Hoàn toàn phi tập trung  

## 🐛 Xử lý lỗi thường gặp

### Lỗi: "MetaMask không kết nối được"
- Kiểm tra MetaMask đã cài đặt chưa
- Kiểm tra network đã chuyển sang "Hardhat Local"
- Refresh trang và thử lại

### Lỗi: "Transaction failed"
- Kiểm tra account có đủ ETH không (phí gas)
- Kiểm tra account có quyền thực hiện hành động không (Admin/Voter)
- Kiểm tra Hardhat Node vẫn đang chạy

### Lỗi: "Không thấy số dư ETH"
- Kiểm tra RPC URL: `http://127.0.0.1:8545`
- Kiểm tra Chain ID: `31337`
- Reset account trong MetaMask: Settings → Advanced → Reset Account

### Lỗi: "Contract not found"
- Kiểm tra địa chỉ contract đã nhập đúng chưa
- Kiểm tra contract đã deploy thành công chưa
- Kiểm tra network đúng (Hardhat Local)

## 📚 Chi tiết

Xem [`QUICK_START.md`](QUICK_START.md) để biết hướng dẫn chi tiết hơn.

## 🔗 Tài nguyên

- [Hardhat Documentation](https://hardhat.org/docs)
- [MetaMask Documentation](https://docs.metamask.io/)
- [Ethers.js Documentation](https://docs.ethers.org/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 📄 License

MIT
