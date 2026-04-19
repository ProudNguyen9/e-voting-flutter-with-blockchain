const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { ethers } = require('ethers');
const { sql, getPool } = require('./database');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// ============= BLOCKCHAIN CONFIGURATION =============
const provider = new ethers.JsonRpcProvider(process.env.PROVIDER_URL);
const adminWallet = new ethers.Wallet(process.env.ADMIN_PRIVATE_KEY, provider);

const CONTRACT_ABI = [
    "event VoteCast(uint256 indexed electionId, address indexed voter, bytes encryptedVote, bytes commitment)",
    "event VoterRegistered(uint256 indexed electionId, address indexed voter)",
    "function registerVoter(uint256 _electionId, address _voter) external",
    "function registerVotersBatch(uint256 _electionId, address[] calldata _voters) external",
    "function castVote(uint256 _electionId, bytes calldata _encryptedVote, bytes calldata _commitment) external",
    "function hasVoterVoted(uint256 _electionId, address _voter) external view returns (bool)"
];

const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, CONTRACT_ABI, adminWallet);

// ============= EMAIL CONFIGURATION =============
const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT),
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});

// ============= MIDDLEWARE =============
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token không được cung cấp' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Token không hợp lệ' });
        }
        req.user = user;
        next();
    });
}

function authenticateAdmin(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token không được cung cấp' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, admin) => {
        if (err || !admin.isAdmin) {
            return res.status(403).json({ error: 'Không có quyền truy cập' });
        }
        req.admin = admin;
        next();
    });
}

// ============= HELPER FUNCTIONS =============
async function sendEmail(to, subject, html) {
    try {
        await transporter.sendMail({
            from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
            to,
            subject,
            html
        });
        return true;
    } catch (error) {
        console.error('Lỗi gửi email:', error);
        return false;
    }
}

function generatePIN() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

function buildUserPayload(user) {
    return {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        walletAddress: user.wallet_address || null
    };
}

// ============= USER AUTHENTICATION APIs =============

// Đăng ký user mới
app.post('/api/auth/register', async (req, res) => {
    try {
        const { email, password, fullName } = req.body;

        if (!email || !password || !fullName) {
            return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
        }

        const pool = await getPool();

        // Kiểm tra email đã tồn tại
        const checkEmail = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT id FROM users WHERE email = @email');

        if (checkEmail.recordset.length > 0) {
            return res.status(400).json({ error: 'Email đã được đăng ký' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Thêm user mới - chưa cần ví ở bước đăng ký
        await pool.request()
            .input('email', sql.NVarChar, email)
            .input('password', sql.NVarChar, hashedPassword)
            .input('fullName', sql.NVarChar, fullName)
            .query(`
                INSERT INTO users (email, password, wallet_address, full_name, is_approved)
                VALUES (@email, @password, NULL, @fullName, 1)
            `);

        // Gửi email thông báo
        await sendEmail(
            email,
            'Đăng ký tài khoản E-Voting thành công',
            `
            <h2>Chào mừng ${fullName}!</h2>
            <p>Tài khoản của bạn đã được đăng ký và kích hoạt thành công.</p>
            <p>Bạn có thể đăng nhập và đăng ký tham gia các cuộc bầu cử.</p>
            <p><strong>Email:</strong> ${email}</p>
            <p><strong>Ví blockchain:</strong> Bạn có thể kết nối MetaMask sau khi đăng nhập.</p>
            <p><em>Lưu ý: Khi đăng ký tham gia bầu cử, bạn cần chờ admin phê duyệt.</em></p>
            `
        );

        res.json({
            message: 'Đăng ký thành công! Bạn có thể đăng nhập ngay và kết nối MetaMask sau.',
            success: true
        });

    } catch (error) {
        console.error('Lỗi đăng ký:', error);
        res.status(500).json({ error: 'Lỗi server khi đăng ký' });
    }
});

// Đăng nhập user
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Thiếu email hoặc password' });
        }

        const pool = await getPool();
        const result = await pool.request()
            .input('email', sql.NVarChar, email)
            .query('SELECT * FROM users WHERE email = @email');

        if (result.recordset.length === 0) {
            return res.status(401).json({ error: 'Email hoặc mật khẩu không đúng' });
        }

        const user = result.recordset[0];

        // Kiểm tra password
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Email hoặc mật khẩu không đúng' });
        }

        // Kiểm tra đã được phê duyệt chưa
        if (!user.is_approved) {
            return res.status(403).json({ error: 'Tài khoản chưa được admin phê duyệt' });
        }

        // Tạo JWT token
        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                walletAddress: user.wallet_address,
                isAdmin: false
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Đăng nhập thành công',
            token,
            user: buildUserPayload(user)
        });

    } catch (error) {
        console.error('Lỗi đăng nhập:', error);
        res.status(500).json({ error: 'Lỗi server khi đăng nhập' });
    }
});

app.post('/api/auth/connect-wallet', authenticateToken, async (req, res) => {
    try {
        const { walletAddress } = req.body;
        const userId = req.user.userId;

        if (!walletAddress || !ethers.isAddress(walletAddress)) {
            return res.status(400).json({ error: 'Địa chỉ ví không hợp lệ' });
        }

        const normalizedWallet = walletAddress.toLowerCase();
        const pool = await getPool();

        const checkWallet = await pool.request()
            .input('wallet', sql.NVarChar, normalizedWallet)
            .input('userId', sql.Int, userId)
            .query('SELECT id FROM users WHERE wallet_address = @wallet AND id <> @userId');

        if (checkWallet.recordset.length > 0) {
            return res.status(400).json({ error: 'Địa chỉ ví đã được đăng ký cho tài khoản khác' });
        }

        await pool.request()
            .input('userId', sql.Int, userId)
            .input('wallet', sql.NVarChar, normalizedWallet)
            .query('UPDATE users SET wallet_address = @wallet WHERE id = @userId');

        const userResult = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT * FROM users WHERE id = @userId');

        const user = userResult.recordset[0];
        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                walletAddress: user.wallet_address,
                isAdmin: false
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Kết nối MetaMask thành công',
            success: true,
            token,
            user: buildUserPayload(user)
        });
    } catch (error) {
        console.error('Lỗi kết nối ví:', error);
        res.status(500).json({ error: 'Lỗi server khi kết nối ví' });
    }
});

// ============= ADMIN AUTHENTICATION APIs =============

// Đăng nhập admin
app.post('/api/admin/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({ error: 'Thiếu username hoặc password' });
        }

        const pool = await getPool();
        const result = await pool.request()
            .input('username', sql.NVarChar, username)
            .query('SELECT * FROM admins WHERE username = @username');

        if (result.recordset.length === 0) {
            return res.status(401).json({ error: 'Username hoặc mật khẩu không đúng' });
        }

        const admin = result.recordset[0];

        // Kiểm tra password
        const validPassword = await bcrypt.compare(password, admin.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Username hoặc mật khẩu không đúng' });
        }

        // Tạo JWT token
        const token = jwt.sign(
            {
                adminId: admin.id,
                username: admin.username,
                isAdmin: true
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Đăng nhập admin thành công',
            token,
            admin: {
                id: admin.id,
                username: admin.username,
                email: admin.email
            }
        });

    } catch (error) {
        console.error('Lỗi đăng nhập admin:', error);
        res.status(500).json({ error: 'Lỗi server khi đăng nhập' });
    }
});

// Lấy danh sách đăng ký bầu cử chờ phê duyệt
app.get('/api/admin/pending-registrations', authenticateAdmin, async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .query(`
                SELECT
                    er.id,
                    er.user_id,
                    er.election_id,
                    er.registered_at,
                    u.email,
                    u.full_name,
                    u.wallet_address,
                    e.title as election_title,
                    e.start_time,
                    e.end_time
                FROM election_registrations er
                JOIN users u ON er.user_id = u.id
                JOIN elections e ON er.election_id = e.id
                WHERE er.is_approved = 0
                ORDER BY er.registered_at DESC
            `);

        res.json({ registrations: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách đăng ký:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Phê duyệt đăng ký bầu cử
app.post('/api/admin/approve-registration/:registrationId', authenticateAdmin, async (req, res) => {
    try {
        const { registrationId } = req.params;

        const pool = await getPool();

        // Lấy thông tin đăng ký
        const regResult = await pool.request()
            .input('regId', sql.Int, registrationId)
            .query(`
                SELECT
                    er.*,
                    u.email,
                    u.full_name,
                    u.wallet_address,
                    e.title as election_title,
                    e.election_id as blockchain_election_id,
                    e.start_time,
                    e.end_time
                FROM election_registrations er
                JOIN users u ON er.user_id = u.id
                JOIN elections e ON er.election_id = e.id
                WHERE er.id = @regId
            `);

        if (regResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy đăng ký' });
        }

        const registration = regResult.recordset[0];

        if (!registration.wallet_address) {
            return res.status(400).json({ error: 'Cử tri chưa kết nối MetaMask nên chưa thể duyệt lên blockchain' });
        }

        // Tạo PIN code
        const pinCode = generatePIN();

        // Đăng ký voter lên blockchain
        try {
            const tx = await contract.registerVoter(
                registration.blockchain_election_id,
                registration.wallet_address
            );
            await tx.wait();
            console.log(`Đã đăng ký voter ${registration.wallet_address} lên blockchain`);
        } catch (blockchainError) {
            console.error('Lỗi đăng ký lên blockchain:', blockchainError);
            return res.status(500).json({ error: 'Lỗi khi đăng ký lên blockchain' });
        }

        // Cập nhật trạng thái phê duyệt và lưu PIN
        await pool.request()
            .input('regId', sql.Int, registrationId)
            .input('pinCode', sql.NVarChar, pinCode)
            .query(`
                UPDATE election_registrations
                SET is_approved = 1,
                    pin_code = @pinCode,
                    registered_to_blockchain = 1,
                    approved_at = GETDATE()
                WHERE id = @regId
            `);

        // Gửi email với PIN code
        await sendEmail(
            registration.email,
            `Đã phê duyệt - Mã PIN cho cuộc bầu cử: ${registration.election_title}`,
            `
            <h2>Chúc mừng ${registration.full_name}!</h2>
            <p>Đăng ký của bạn cho cuộc bầu cử <strong>${registration.election_title}</strong> đã được phê duyệt.</p>
            <p>Mã PIN của bạn là: <strong style="font-size: 24px; color: #007bff;">${pinCode}</strong></p>
            <p>Vui lòng giữ mã PIN này để xác thực khi bỏ phiếu.</p>
            <p><strong>Thời gian bắt đầu:</strong> ${new Date(registration.start_time).toLocaleString('vi-VN')}</p>
            <p><strong>Thời gian kết thúc:</strong> ${new Date(registration.end_time).toLocaleString('vi-VN')}</p>
            <p><em>Lưu ý: Mã PIN chỉ sử dụng được một lần và có hiệu lực đến khi cuộc bầu cử kết thúc.</em></p>
            `
        );

        res.json({
            message: 'Phê duyệt đăng ký thành công',
            success: true
        });

    } catch (error) {
        console.error('Lỗi phê duyệt đăng ký:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// ============= ELECTION APIs =============

// Tạo cuộc bầu cử mới (chỉ lưu vào DB, blockchain tạo riêng)
app.post('/api/admin/elections', authenticateAdmin, async (req, res) => {
    try {
        const { electionId, title, description, startTime, endTime } = req.body;

        if (!electionId || !title || !startTime || !endTime) {
            return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
        }

        const pool = await getPool();

        await pool.request()
            .input('electionId', sql.Int, electionId)
            .input('title', sql.NVarChar, title)
            .input('description', sql.NVarChar, description || '')
            .input('startTime', sql.DateTime, new Date(startTime))
            .input('endTime', sql.DateTime, new Date(endTime))
            .query(`
                INSERT INTO elections (election_id, title, description, start_time, end_time)
                VALUES (@electionId, @title, @description, @startTime, @endTime)
            `);

        res.json({
            message: 'Tạo cuộc bầu cử thành công',
            success: true
        });

    } catch (error) {
        console.error('Lỗi tạo cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Lấy danh sách cuộc bầu cử
app.get('/api/elections', authenticateToken, async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .query('SELECT * FROM elections ORDER BY start_time DESC');

        res.json({ elections: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// ============= ELECTION REGISTRATION APIs =============

// User đăng ký tham gia cuộc bầu cử (3 ngày trước khi bắt đầu)
app.post('/api/elections/:electionId/join', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const userId = req.user.userId;
        const walletAddress = req.user.walletAddress;

        if (!walletAddress) {
            return res.status(400).json({ error: 'Bạn cần kết nối MetaMask trước khi đăng ký tham gia bầu cử' });
        }

        const pool = await getPool();

        // Lấy thông tin cuộc bầu cử
        const electionResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query('SELECT * FROM elections WHERE id = @electionId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];
        const now = new Date();
        const startTime = new Date(election.start_time);
        const threeDaysBefore = new Date(startTime.getTime() - 3 * 24 * 60 * 60 * 1000);

        // Kiểm tra thời gian đăng ký (3 ngày trước)
        if (now < threeDaysBefore) {
            return res.status(400).json({
                error: 'Chưa đến thời gian đăng ký. Bạn có thể đăng ký từ 3 ngày trước khi bầu cử bắt đầu.'
            });
        }

        if (now > startTime) {
            return res.status(400).json({
                error: 'Cuộc bầu cử đã bắt đầu, không thể đăng ký thêm.'
            });
        }

        // Kiểm tra đã đăng ký chưa
        const checkReg = await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .query('SELECT id FROM election_registrations WHERE user_id = @userId AND election_id = @electionId');

        if (checkReg.recordset.length > 0) {
            return res.status(400).json({ error: 'Bạn đã đăng ký cuộc bầu cử này rồi' });
        }

        // Lưu vào database - CHỜ ADMIN DUYỆT
        await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .query(`
                INSERT INTO election_registrations (user_id, election_id, is_approved, registered_to_blockchain)
                VALUES (@userId, @electionId, 0, 0)
            `);

        // Lấy thông tin user
        const userResult = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT email, full_name FROM users WHERE id = @userId');

        const user = userResult.recordset[0];

        // Gửi email thông báo chờ duyệt
        await sendEmail(
            user.email,
            `Đăng ký tham gia bầu cử: ${election.title}`,
            `
            <h2>Chào ${user.full_name}!</h2>
            <p>Bạn đã gửi yêu cầu đăng ký tham gia cuộc bầu cử: <strong>${election.title}</strong></p>
            <p><strong>Trạng thái:</strong> Đang chờ admin phê duyệt</p>
            <p><strong>Thời gian bắt đầu:</strong> ${startTime.toLocaleString('vi-VN')}</p>
            <p><strong>Thời gian kết thúc:</strong> ${new Date(election.end_time).toLocaleString('vi-VN')}</p>
            <p><em>Lưu ý: Sau khi được phê duyệt, bạn sẽ nhận được mã PIN qua email để bỏ phiếu.</em></p>
            `
        );

        res.json({
            message: 'Đăng ký thành công! Vui lòng đợi admin phê duyệt.',
            success: true
        });

    } catch (error) {
        console.error('Lỗi đăng ký cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Xác thực PIN code trước khi bỏ phiếu
app.post('/api/elections/:electionId/verify-pin', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const { pinCode } = req.body;
        const userId = req.user.userId;

        if (!pinCode) {
            return res.status(400).json({ error: 'Thiếu mã PIN' });
        }

        const pool = await getPool();

        // Kiểm tra PIN
        const result = await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .input('pinCode', sql.NVarChar, pinCode)
            .query(`
                SELECT * FROM election_registrations
                WHERE user_id = @userId AND election_id = @electionId AND pin_code = @pinCode
            `);

        if (result.recordset.length === 0) {
            return res.status(401).json({ error: 'Mã PIN không đúng' });
        }

        const registration = result.recordset[0];

        // Kiểm tra đã được phê duyệt chưa
        if (!registration.is_approved) {
            return res.status(403).json({ error: 'Đăng ký chưa được admin phê duyệt' });
        }

        // Kiểm tra PIN đã được sử dụng chưa
        if (registration.is_pin_used) {
            return res.status(400).json({ error: 'Mã PIN đã được sử dụng' });
        }

        // Lấy thông tin cuộc bầu cử
        const electionResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query('SELECT * FROM elections WHERE id = @electionId');

        const election = electionResult.recordset[0];
        const now = new Date();
        const startTime = new Date(election.start_time);
        const endTime = new Date(election.end_time);

        // Kiểm tra thời gian bỏ phiếu
        if (now < startTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử chưa bắt đầu' });
        }

        if (now > endTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã kết thúc' });
        }

        // Đánh dấu PIN đã sử dụng
        await pool.request()
            .input('id', sql.Int, registration.id)
            .query('UPDATE election_registrations SET is_pin_used = 1 WHERE id = @id');

        res.json({
            message: 'Xác thực PIN thành công',
            success: true,
            canVote: true
        });

    } catch (error) {
        console.error('Lỗi xác thực PIN:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// ============= GAS TRACKING APIs =============

// Lưu thông tin gas khi user bỏ phiếu (gọi sau khi castVote thành công)
app.post('/api/gas-tracking', authenticateToken, async (req, res) => {
    try {
        const { electionId, txHash } = req.body;
        const userId = req.user.userId;
        const walletAddress = req.user.walletAddress;

        if (!electionId || !txHash) {
            return res.status(400).json({ error: 'Thiếu thông tin' });
        }

        if (!walletAddress) {
            return res.status(400).json({ error: 'Bạn cần kết nối MetaMask trước khi lưu gas tracking' });
        }

        // Lấy thông tin transaction từ blockchain
        const receipt = await provider.getTransactionReceipt(txHash);
        if (!receipt) {
            return res.status(404).json({ error: 'Không tìm thấy transaction' });
        }

        const gasUsed = receipt.gasUsed;
        const tx = await provider.getTransaction(txHash);
        const gasPrice = tx.gasPrice;
        const totalCost = gasUsed * gasPrice;

        const pool = await getPool();

        // Lưu vào database
        await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .input('walletAddress', sql.NVarChar, walletAddress)
            .input('txHash', sql.NVarChar, txHash)
            .input('gasUsed', sql.Decimal(18, 8), parseFloat(ethers.formatUnits(gasUsed, 'wei')))
            .input('gasPrice', sql.Decimal(18, 8), parseFloat(ethers.formatUnits(gasPrice, 'gwei')))
            .input('totalCost', sql.Decimal(18, 8), parseFloat(ethers.formatEther(totalCost)))
            .query(`
                INSERT INTO gas_tracking (user_id, election_id, wallet_address, tx_hash, gas_used, gas_price, total_cost)
                VALUES (@userId, @electionId, @walletAddress, @txHash, @gasUsed, @gasPrice, @totalCost)
            `);

        res.json({
            message: 'Đã lưu thông tin gas',
            success: true,
            gasCost: ethers.formatEther(totalCost)
        });

    } catch (error) {
        console.error('Lỗi lưu gas tracking:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin lấy danh sách gas cần hoàn
app.get('/api/admin/gas-refunds/:electionId', authenticateAdmin, async (req, res) => {
    try {
        const { electionId } = req.params;

        const pool = await getPool();
        const result = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query(`
                SELECT gt.*, u.email, u.full_name 
                FROM gas_tracking gt
                JOIN users u ON gt.user_id = u.id
                WHERE gt.election_id = @electionId AND gt.is_refunded = 0
                ORDER BY gt.voted_at DESC
            `);

        res.json({ refunds: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách gas refund:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin hoàn phí gas
app.post('/api/admin/refund-gas/:gasTrackingId', authenticateAdmin, async (req, res) => {
    try {
        const { gasTrackingId } = req.params;

        const pool = await getPool();

        // Lấy thông tin gas tracking
        const result = await pool.request()
            .input('id', sql.Int, gasTrackingId)
            .query('SELECT * FROM gas_tracking WHERE id = @id');

        if (result.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy thông tin gas' });
        }

        const gasTracking = result.recordset[0];

        if (gasTracking.is_refunded) {
            return res.status(400).json({ error: 'Đã hoàn phí rồi' });
        }

        // Gửi ETH hoàn phí
        const tx = await adminWallet.sendTransaction({
            to: gasTracking.wallet_address,
            value: ethers.parseEther(gasTracking.total_cost.toString())
        });

        await tx.wait();

        // Cập nhật database
        await pool.request()
            .input('id', sql.Int, gasTrackingId)
            .input('refundTxHash', sql.NVarChar, tx.hash)
            .query(`
                UPDATE gas_tracking 
                SET is_refunded = 1, refund_tx_hash = @refundTxHash, refunded_at = GETDATE()
                WHERE id = @id
            `);

        res.json({
            message: 'Hoàn phí thành công',
            success: true,
            txHash: tx.hash
        });

    } catch (error) {
        console.error('Lỗi hoàn phí gas:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// ============= START SERVER =============
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
app.listen(PORT, HOST, () => {
    console.log(`🚀 Server đang chạy tại http://${HOST}:${PORT}`);
    console.log(`🌐 Truy cập trong mạng LAN bằng IP máy tính, ví dụ: http://172.20.10.4:${PORT}`);
    console.log(`📝 Contract Address: ${process.env.CONTRACT_ADDRESS}`);
    console.log(`👤 Admin Wallet: ${adminWallet.address}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🛑 Đang tắt server...');
    const { closePool } = require('./database');
    await closePool();
    process.exit(0);
});
