const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
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
    "event ElectionCreated(uint256 indexed electionId, string title, address indexed creator, uint256 startTime, uint256 endTime)",
    "event CandidateAdded(uint256 indexed electionId, uint256 indexed candidateId, string name)",
    "event VoterRegistered(uint256 indexed electionId, address indexed voter)",
    "event PhaseChanged(uint256 indexed electionId, uint8 newPhase, uint256 timestamp)",
    "event VoteCast(uint256 indexed electionId, address indexed voter, bytes32 commitment, uint256 timestamp)",
    "event BallotsShuffled(uint256 indexed electionId, uint256 ballotCount, bytes32 shuffleProof)",
    "event VoteDecrypted(uint256 indexed electionId, uint256 ballotIndex, uint256 candidateId)",
    "event ElectionCompleted(uint256 indexed electionId, uint256 totalVotes)",
    "function admin() view returns (address)",
    "function electionCounter() view returns (uint256)",
    "function ballotCounter() view returns (uint256)",
    "function elections(uint256) view returns (uint256,string,string,uint256,uint256,uint8,address,bool,uint256,uint256)",
    "function candidates(uint256,uint256) view returns (uint256,string,string,string,uint256,bool)",
    "function candidateCounters(uint256) view returns (uint256)",
    "function hasVoted(uint256,address) view returns (bool)",
    "function isRegisteredVoter(uint256,address) view returns (bool)",
    "function createElection(string memory _title, string memory _description, uint256 _startTime, uint256 _endTime) external returns (uint256)",
    "function addCandidate(uint256 _electionId, string memory _name, string memory _description, string memory _imageUrl) external",
    "function addCandidatesBatch(uint256 _electionId, string[] calldata _names, string[] calldata _descriptions, string[] calldata _imageUrls) external",
    "function registerVoter(uint256 _electionId, address _voter) external",
    "function registerVotersBatch(uint256 _electionId, address[] calldata _voters) external",
    "function startVoting(uint256 _electionId) external",
    "function castVote(uint256 _electionId, bytes calldata _encryptedVote, bytes32 _commitment) external",
    "function castVoteForVoter(uint256 _electionId, address _voter, bytes calldata _encryptedVote, bytes32 _commitment) external",
    "function endVoting(uint256 _electionId) external",
    "function shuffleBallots(uint256 _electionId, bytes32 _shuffleProof) external",
    "function decryptAndTally(uint256 _electionId, uint256[] calldata _candidateIds) external",
    "function getResults(uint256 _electionId) external view returns (string,uint8,uint256,uint256,uint256)",
    "function getCandidate(uint256 _electionId, uint256 _candidateId) external view returns (string,string,string,uint256)",
    "function getAllCandidates(uint256 _electionId) external view returns (uint256[],string[],uint256[])",
    "function hasVoterVoted(uint256 _electionId, address _voter) external view returns (bool)",
    "function getBallotCount(uint256 _electionId) external view returns (uint256)",
    "function getElectionInfo(uint256 _electionId) external view returns (string,string,uint256,uint256,uint8,uint256,uint256,uint256)",
    "function phaseToString(uint8 _phase) external pure returns (string)",
    "function getAuditTrail(uint256 _electionId) external view returns (tuple(bytes32,bytes32,bytes32,uint256)[])",
    "function verifyBallotCommitment(uint256 _electionId, uint256 _ballotIndex, bytes32 _commitment) external view returns (bool)"
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

function toUnixTimestamp(dateValue) {
    return Math.floor(new Date(dateValue).getTime() / 1000);
}

function buildEncryptedVoteHex(candidateBlockchainId) {
    const voteBytes = Buffer.from(String(candidateBlockchainId), 'utf8');
    return `0x${voteBytes.toString('hex')}`;
}

function buildCommitmentHex({ blockchainElectionId, candidateBlockchainId, voterAddress, pinCode }) {
    const raw = `${blockchainElectionId}:${candidateBlockchainId}:${voterAddress.toLowerCase()}:${pinCode}`;
    return `0x${crypto.createHash('sha256').update(raw).digest('hex')}`;
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

// Cập nhật địa chỉ ví
app.put('/api/auth/update-wallet', authenticateToken, async (req, res) => {
    try {
        const { walletAddress } = req.body;
        const userId = req.user.userId;

        if (!walletAddress || !ethers.isAddress(walletAddress)) {
            return res.status(400).json({ error: 'Địa chỉ ví không hợp lệ' });
        }

        const normalizedWallet = walletAddress.toLowerCase();
        const pool = await getPool();

        // Kiểm tra xem ví đã được sử dụng bởi user khác chưa
        const checkWallet = await pool.request()
            .input('wallet', sql.NVarChar, normalizedWallet)
            .input('userId', sql.Int, userId)
            .query('SELECT id FROM users WHERE wallet_address = @wallet AND id <> @userId');

        if (checkWallet.recordset.length > 0) {
            return res.status(400).json({ error: 'Địa chỉ ví đã được đăng ký cho tài khoản khác' });
        }

        // Cập nhật địa chỉ ví
        await pool.request()
            .input('userId', sql.Int, userId)
            .input('wallet', sql.NVarChar, normalizedWallet)
            .query('UPDATE users SET wallet_address = @wallet WHERE id = @userId');

        res.json({
            message: 'Cập nhật địa chỉ ví thành công',
            success: true
        });
    } catch (error) {
        console.error('Lỗi cập nhật ví:', error);
        res.status(500).json({ error: 'Lỗi server' });
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

// Lấy danh sách đăng ký bầu cử chờ phê duyệt (có thể lọc theo election_id)
app.get('/api/admin/pending-registrations', authenticateAdmin, async (req, res) => {
    try {
        const pool = await getPool();
        const { election_id } = req.query;

        let query = `
            SELECT
                er.id,
                er.user_id,
                er.election_id,
                er.registered_at,
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
            WHERE er.is_approved = 0
        `;

        const request = pool.request();

        // Nếu có election_id, lọc theo cuộc bầu cử cụ thể
        if (election_id) {
            query += ` AND er.election_id = @electionId`;
            request.input('electionId', sql.Int, parseInt(election_id));
        }

        query += ` ORDER BY e.election_id DESC, er.registered_at DESC`;

        const result = await request.query(query);

        res.json({ registrations: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách đăng ký:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Lấy danh sách cử tri đã phê duyệt (có thể lọc theo election_id)
app.get('/api/admin/approved-voters', authenticateAdmin, async (req, res) => {
    try {
        const pool = await getPool();
        const { election_id } = req.query;

        let query = `
            SELECT
                er.id,
                er.user_id,
                er.election_id,
                er.registered_at,
                er.approved_at,
                er.registered_to_blockchain,
                u.email,
                u.full_name,
                u.wallet_address,
                e.title as election_title,
                e.election_id as blockchain_election_id,
                e.start_time,
                e.end_time,
                e.is_onchain
            FROM election_registrations er
            JOIN users u ON er.user_id = u.id
            JOIN elections e ON er.election_id = e.id
            WHERE er.is_approved = 1
        `;

        const request = pool.request();

        // Nếu có election_id, lọc theo cuộc bầu cử cụ thể
        if (election_id) {
            query += ` AND er.election_id = @electionId`;
            request.input('electionId', sql.Int, parseInt(election_id));
        }

        query += ` ORDER BY e.election_id DESC, er.approved_at DESC`;

        const result = await request.query(query);

        res.json({ voters: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách cử tri đã phê duyệt:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Phê duyệt đăng ký bầu cử (CHỈ lưu database, CHƯA đăng ký blockchain)
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
            return res.status(400).json({ error: 'Cử tri chưa kết nối MetaMask' });
        }

        // Tạo PIN code
        const pinCode = generatePIN();

        // Cập nhật trạng thái phê duyệt và lưu PIN (CHƯA đăng ký blockchain)
        await pool.request()
            .input('regId', sql.Int, registrationId)
            .input('pinCode', sql.NVarChar, pinCode)
            .query(`
                UPDATE election_registrations
                SET is_approved = 1,
                    pin_code = @pinCode,
                    registered_to_blockchain = 0,
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
            <p><em>Cuộc bầu cử có thể được kích hoạt lên blockchain ngay khi admin sẵn sàng.</em></p>
            `
        );

        res.json({
            message: 'Phê duyệt đăng ký thành công. Cuộc bầu cử sẽ được kích hoạt lên blockchain khi đủ điều kiện.',
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
        const { title, description, startTime, endTime } = req.body;

        if (!title || !startTime || !endTime) {
            return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
        }

        const pool = await getPool();
        const nextElectionIdResult = await pool.request().query(`
            SELECT ISNULL(MAX(election_id), 0) + 1 AS nextElectionId
            FROM elections
        `);
        const nextElectionId = nextElectionIdResult.recordset[0].nextElectionId;

        await pool.request()
            .input('electionId', sql.Int, nextElectionId)
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
            success: true,
            election: {
                election_id: nextElectionId,
                title,
                description: description || '',
                start_time: startTime,
                end_time: endTime
            }
        });

    } catch (error) {
        console.error('Lỗi tạo cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin lấy ID cuộc bầu cử kế tiếp
app.get('/api/admin/elections/next-id', authenticateAdmin, async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request().query(`
            SELECT ISNULL(MAX(election_id), 0) + 1 AS nextElectionId
            FROM elections
        `);

        res.json({ nextElectionId: result.recordset[0].nextElectionId });

    } catch (error) {
        console.error('Lỗi lấy next election id:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin lấy danh sách cuộc bầu cử
app.get('/api/admin/elections', authenticateAdmin, async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .query(`
                SELECT
                    e.*,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                ORDER BY e.created_at DESC, e.start_time DESC
            `);

        res.json({ elections: result.recordset });

    } catch (error) {
        console.error('Lỗi admin lấy danh sách cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin kích hoạt cuộc bầu cử lên blockchain (CHỈ TẠO ELECTION)
app.post('/api/admin/elections/:electionDbId/activate-onchain', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const pool = await getPool();

        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query(`
                SELECT
                    e.*,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                WHERE e.id = @electionDbId
            `);

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];

        if (election.is_onchain) {
            return res.status(400).json({ error: 'Cuộc bầu cử này đã được kích hoạt on-chain' });
        }

        // Kiểm tra thời gian và điều kiện tối thiểu
        const startTime = toUnixTimestamp(election.start_time);
        const endTime = toUnixTimestamp(election.end_time);
        const currentTime = Math.floor(Date.now() / 1000);
        const candidateCount = Number(election.candidate_count || 0);
        const approvedVoterCount = Number(election.approved_voter_count || 0);
        const hasMinimumRequirements = candidateCount >= 2 && approvedVoterCount >= 3;

        if (startTime <= currentTime && !hasMinimumRequirements) {
            return res.status(400).json({
                error: 'Cuộc bầu cử đã hủy do đến giờ bắt đầu nhưng không đủ tối thiểu 2 ứng cử viên và 3 cử tri được duyệt'
            });
        }

        if (!hasMinimumRequirements) {
            return res.status(400).json({
                error: `Chưa đủ điều kiện kích hoạt on-chain (hiện có ${candidateCount}/2 ứng cử viên và ${approvedVoterCount}/3 cử tri được duyệt)`
            });
        }

        if (startTime <= currentTime) {
            return res.status(400).json({ error: 'Thời gian bắt đầu phải lớn hơn thời gian hiện tại' });
        }

        if (endTime <= startTime) {
            return res.status(400).json({ error: 'Thời gian kết thúc phải lớn hơn thời gian bắt đầu' });
        }

        let receipt;
        let blockchainElectionId;

        try {
            console.log('🚀 Đang tạo cuộc bầu cử lên blockchain...');
            console.log(`   - Tiêu đề: ${election.title}`);

            // CHỈ TẠO ELECTION
            const tx = await contract.createElection(
                election.title,
                election.description || '',
                startTime,
                endTime
            );

            console.log('⏳ Đang chờ xác nhận từ blockchain...');
            receipt = await tx.wait();
            console.log('✅ Tạo cuộc bầu cử thành công!');

            // Lấy election ID từ event ElectionCreated
            const electionCreatedEvent = receipt.logs.find(
                log => log.topics[0] === contract.interface.getEvent('ElectionCreated').topicHash
            );

            if (electionCreatedEvent) {
                const parsedEvent = contract.interface.parseLog(electionCreatedEvent);
                blockchainElectionId = parsedEvent.args[0].toString();
                console.log(`📋 Blockchain Election ID: ${blockchainElectionId}`);
            }

        } catch (blockchainError) {
            console.error('❌ Lỗi kích hoạt on-chain:', blockchainError);
            return res.status(500).json({
                error: 'Không thể kích hoạt cuộc bầu cử lên blockchain',
                details: blockchainError.message
            });
        }

        // Cập nhật trạng thái cuộc bầu cử
        await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .input('blockchainElectionId', sql.Int, blockchainElectionId || election.election_id)
            .input('txHash', sql.NVarChar, receipt?.hash || null)
            .query(`
                UPDATE elections
                SET is_onchain = 1,
                    election_id = @blockchainElectionId,
                    onchain_tx_hash = @txHash,
                    onchain_activated_at = GETDATE()
                WHERE id = @electionDbId
            `);

        res.json({
            success: true,
            message: 'Kích hoạt cuộc bầu cử on-chain thành công!',
            txHash: receipt?.hash || null,
            blockchainElectionId: blockchainElectionId || election.election_id,
            gasUsed: receipt?.gasUsed?.toString()
        });

    } catch (error) {
        console.error('❌ Lỗi kích hoạt on-chain:', error);
        res.status(500).json({ error: 'Lỗi server', details: error.message });
    }
});

// Admin đăng ký ứng cử viên lên blockchain
app.post('/api/admin/elections/:electionDbId/register-candidates-onchain', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const pool = await getPool();

        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query('SELECT * FROM elections WHERE id = @electionDbId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];

        if (!election.is_onchain) {
            return res.status(400).json({ error: 'Cuộc bầu cử chưa được kích hoạt on-chain' });
        }

        // Lấy danh sách ứng cử viên chưa đăng ký blockchain
        const candidateResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query(`
                SELECT *
                FROM election_candidates
                WHERE election_db_id = @electionDbId
                  AND (blockchain_candidate_id IS NULL OR blockchain_candidate_id = 0)
                ORDER BY id ASC
            `);

        const candidates = candidateResult.recordset;

        if (candidates.length === 0) {
            return res.status(400).json({ error: 'Không có ứng cử viên nào cần đăng ký' });
        }

        try {
            console.log(`🚀 Đang đăng ký ${candidates.length} ứng cử viên lên blockchain...`);

            let registeredCount = 0;
            for (const candidate of candidates) {
                const tx = await contract.addCandidate(
                    election.election_id,
                    candidate.candidate_name,
                    candidate.candidate_description || '',
                    candidate.image_url || ''
                );
                await tx.wait();

                // Lấy candidate ID từ contract
                const candidateId = registeredCount + 1;

                await pool.request()
                    .input('candidateId', sql.Int, candidate.id)
                    .input('blockchainCandidateId', sql.Int, candidateId)
                    .query(`
                        UPDATE election_candidates
                        SET blockchain_candidate_id = @blockchainCandidateId,
                            updated_at = GETDATE()
                        WHERE id = @candidateId
                    `);

                registeredCount++;
                console.log(`✅ Đã đăng ký: ${candidate.candidate_name}`);
            }

            console.log(`✅ Hoàn tất đăng ký ${registeredCount} ứng cử viên!`);

            res.json({
                success: true,
                message: `Đăng ký ${registeredCount} ứng cử viên lên blockchain thành công!`,
                candidatesRegistered: registeredCount
            });

        } catch (blockchainError) {
            console.error('❌ Lỗi đăng ký ứng cử viên:', blockchainError);
            return res.status(500).json({
                error: 'Không thể đăng ký ứng cử viên lên blockchain',
                details: blockchainError.message
            });
        }

    } catch (error) {
        console.error('❌ Lỗi đăng ký ứng cử viên:', error);
        res.status(500).json({ error: 'Lỗi server', details: error.message });
    }
});

// Admin đăng ký cử tri lên blockchain
app.post('/api/admin/elections/:electionDbId/register-voters-onchain', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const pool = await getPool();

        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query('SELECT * FROM elections WHERE id = @electionDbId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];

        if (!election.is_onchain) {
            return res.status(400).json({ error: 'Cuộc bầu cử chưa được kích hoạt on-chain' });
        }

        // Lấy danh sách cử tri đã phê duyệt nhưng chưa đăng ký blockchain
        const voterResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query(`
                SELECT
                    er.id,
                    er.user_id,
                    er.election_id,
                    er.registered_to_blockchain,
                    u.wallet_address
                FROM election_registrations er
                JOIN users u ON u.id = er.user_id
                WHERE er.election_id = @electionDbId
                  AND er.is_approved = 1
                  AND er.registered_to_blockchain = 0
                  AND u.wallet_address IS NOT NULL
                  AND LTRIM(RTRIM(u.wallet_address)) <> ''
                ORDER BY er.id ASC
            `);

        const approvedVoters = voterResult.recordset;

        if (approvedVoters.length === 0) {
            return res.status(400).json({ error: 'Không có cử tri nào cần đăng ký' });
        }

        try {
            console.log(`🚀 Đang đăng ký ${approvedVoters.length} cử tri lên blockchain...`);

            // Sử dụng registerVotersBatch để đăng ký hàng loạt
            const voterAddresses = approvedVoters.map(v => v.wallet_address);
            const tx = await contract.registerVotersBatch(
                election.election_id,
                voterAddresses
            );
            await tx.wait();

            // Cập nhật trạng thái đã đăng ký blockchain cho tất cả cử tri
            for (const voter of approvedVoters) {
                await pool.request()
                    .input('registrationId', sql.Int, voter.id)
                    .query(`
                        UPDATE election_registrations
                        SET registered_to_blockchain = 1
                        WHERE id = @registrationId
                    `);
            }

            console.log(`✅ Hoàn tất đăng ký ${approvedVoters.length} cử tri!`);

            res.json({
                success: true,
                message: `Đăng ký ${approvedVoters.length} cử tri lên blockchain thành công!`,
                votersRegistered: approvedVoters.length
            });

        } catch (blockchainError) {
            console.error('❌ Lỗi đăng ký cử tri:', blockchainError);
            return res.status(500).json({
                error: 'Không thể đăng ký cử tri lên blockchain',
                details: blockchainError.message
            });
        }

    } catch (error) {
        console.error('❌ Lỗi đăng ký cử tri:', error);
        res.status(500).json({ error: 'Lỗi server', details: error.message });
    }
});

// Admin lấy danh sách ứng cử viên theo cuộc bầu cử
app.get('/api/admin/elections/:electionDbId/candidates', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const pool = await getPool();

        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query('SELECT id, election_id, title, start_time, end_time, is_onchain FROM elections WHERE id = @electionDbId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const candidatesResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query(`
                SELECT *
                FROM election_candidates
                WHERE election_db_id = @electionDbId
                ORDER BY created_at ASC, id ASC
            `);

        res.json({
            election: electionResult.recordset[0],
            candidates: candidatesResult.recordset
        });

    } catch (error) {
        console.error('Lỗi lấy danh sách ứng cử viên:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin thêm ứng cử viên cho cuộc bầu cử
app.post('/api/admin/elections/:electionDbId/candidates', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const { name, description, imageUrl } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Tên ứng cử viên là bắt buộc' });
        }

        const pool = await getPool();
        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query('SELECT id, election_id, is_onchain, start_time, end_time FROM elections WHERE id = @electionDbId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];

        // Kiểm tra thời gian: không cho phép thêm nếu đã bắt đầu hoặc đã kết thúc
        const now = new Date();
        const startTime = new Date(election.start_time);
        const endTime = new Date(election.end_time);

        if (now >= startTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã bắt đầu, không thể thêm ứng cử viên' });
        }

        if (now > endTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã kết thúc, không thể thêm ứng cử viên' });
        }

        const insertResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .input('electionId', sql.Int, election.election_id)
            .input('candidateName', sql.NVarChar, name)
            .input('candidateDescription', sql.NVarChar, description || '')
            .input('imageUrl', sql.NVarChar, imageUrl || '')
            .query(`
                INSERT INTO election_candidates (
                    election_db_id,
                    election_id,
                    candidate_name,
                    candidate_description,
                    image_url
                )
                OUTPUT INSERTED.*
                VALUES (
                    @electionDbId,
                    @electionId,
                    @candidateName,
                    @candidateDescription,
                    @imageUrl
                )
            `);

        res.json({
            success: true,
            message: 'Thêm ứng cử viên thành công',
            candidate: insertResult.recordset[0]
        });

    } catch (error) {
        console.error('Lỗi thêm ứng cử viên:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin cập nhật ứng cử viên
app.put('/api/admin/candidates/:candidateId', authenticateAdmin, async (req, res) => {
    try {
        const { candidateId } = req.params;
        const { name, description, imageUrl } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Tên ứng cử viên là bắt buộc' });
        }

        const pool = await getPool();
        const candidateResult = await pool.request()
            .input('candidateId', sql.Int, candidateId)
            .query(`
                SELECT ec.*, e.is_onchain, e.start_time, e.end_time
                FROM election_candidates ec
                JOIN elections e ON e.id = ec.election_db_id
                WHERE ec.id = @candidateId
            `);

        if (candidateResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy ứng cử viên' });
        }

        const candidate = candidateResult.recordset[0];

        // Kiểm tra nếu ứng cử viên đã được đăng ký lên blockchain
        if (candidate.blockchain_candidate_id) {
            return res.status(400).json({ error: 'Ứng cử viên đã được đăng ký lên blockchain, không thể sửa' });
        }

        // Kiểm tra thời gian
        const now = new Date();
        const startTime = new Date(candidate.start_time);
        const endTime = new Date(candidate.end_time);

        if (now >= startTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã bắt đầu, không thể sửa ứng cử viên' });
        }

        if (now > endTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã kết thúc, không thể sửa ứng cử viên' });
        }

        const updateResult = await pool.request()
            .input('candidateId', sql.Int, candidateId)
            .input('candidateName', sql.NVarChar, name)
            .input('candidateDescription', sql.NVarChar, description || '')
            .input('imageUrl', sql.NVarChar, imageUrl || '')
            .query(`
                UPDATE election_candidates
                SET candidate_name = @candidateName,
                    candidate_description = @candidateDescription,
                    image_url = @imageUrl,
                    updated_at = GETDATE()
                OUTPUT INSERTED.*
                WHERE id = @candidateId
            `);

        res.json({
            success: true,
            message: 'Cập nhật ứng cử viên thành công',
            candidate: updateResult.recordset[0]
        });

    } catch (error) {
        console.error('Lỗi cập nhật ứng cử viên:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Admin xóa ứng cử viên
app.delete('/api/admin/candidates/:candidateId', authenticateAdmin, async (req, res) => {
    try {
        const { candidateId } = req.params;
        const pool = await getPool();

        const candidateResult = await pool.request()
            .input('candidateId', sql.Int, candidateId)
            .query(`
                SELECT ec.id, ec.blockchain_candidate_id, e.is_onchain, e.start_time, e.end_time
                FROM election_candidates ec
                JOIN elections e ON e.id = ec.election_db_id
                WHERE ec.id = @candidateId
            `);

        if (candidateResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy ứng cử viên' });
        }

        const candidate = candidateResult.recordset[0];

        // Kiểm tra nếu ứng cử viên đã được đăng ký lên blockchain
        if (candidate.blockchain_candidate_id) {
            return res.status(400).json({ error: 'Ứng cử viên đã được đăng ký lên blockchain, không thể xóa' });
        }

        // Kiểm tra thời gian
        const now = new Date();
        const startTime = new Date(candidate.start_time);
        const endTime = new Date(candidate.end_time);

        if (now >= startTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã bắt đầu, không thể xóa ứng cử viên' });
        }

        if (now > endTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã kết thúc, không thể xóa ứng cử viên' });
        }

        await pool.request()
            .input('candidateId', sql.Int, candidateId)
            .query('DELETE FROM election_candidates WHERE id = @candidateId');

        res.json({ success: true, message: 'Xóa ứng cử viên thành công' });

    } catch (error) {
        console.error('Lỗi xóa ứng cử viên:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Lấy danh sách cuộc bầu cử
app.get('/api/elections', authenticateToken, async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .query(`
                SELECT
                    e.*,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                ORDER BY e.start_time DESC
            `);

        res.json({ elections: result.recordset });

    } catch (error) {
        console.error('Lỗi lấy danh sách cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Lấy chi tiết cuộc bầu cử và danh sách ứng cử viên
app.get('/api/elections/:electionId/candidates', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const pool = await getPool();

        // Lấy thông tin cuộc bầu cử
        const electionResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query(`
                SELECT
                    e.*,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                WHERE e.id = @electionId
            `);

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        // Lấy danh sách ứng cử viên
        const candidatesResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query(`
                SELECT *
                FROM election_candidates
                WHERE election_db_id = @electionId
                ORDER BY created_at ASC, id ASC
            `);

        res.json({
            election: electionResult.recordset[0],
            candidates: candidatesResult.recordset
        });

    } catch (error) {
        console.error('Lỗi lấy chi tiết cuộc bầu cử:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

app.get('/api/elections/:electionId/results', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const pool = await getPool();

        const electionResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query(`
                SELECT
                    e.*,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                WHERE e.id = @electionId
            `);

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];
        const now = new Date();
        const endTime = new Date(election.end_time);

        if (now <= endTime) {
            return res.status(400).json({ error: 'Cuộc bầu cử chưa kết thúc để xem kết quả' });
        }

        const candidatesDbResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query(`
                SELECT *
                FROM election_candidates
                WHERE election_db_id = @electionId
                ORDER BY created_at ASC, id ASC
            `);

        let totalVotes = 0;
        let phase = 'OFFCHAIN';
        let candidates = candidatesDbResult.recordset.map(candidate => ({
            candidateId: candidate.id,
            blockchainCandidateId: candidate.blockchain_candidate_id || 0,
            name: candidate.candidate_name,
            description: candidate.candidate_description || '',
            imageUrl: candidate.image_url || '',
            voteCount: 0
        }));

        if (election.is_onchain && election.election_id) {
            const blockchainElectionId = Number(election.election_id);
            const [chainResults, chainCandidates] = await Promise.all([
                contract.getResults(blockchainElectionId),
                contract.getAllCandidates(blockchainElectionId)
            ]);

            totalVotes = Number(chainResults[3] || 0);
            const phaseMap = {
                0: 'Configuration',
                1: 'Casting',
                2: 'Anonymization',
                3: 'Decryption',
                4: 'Completed'
            };
            phase = phaseMap[Number(chainResults[1] || 0)] || 'UNKNOWN';

            const ids = Array.from(chainCandidates[0] || []);
            const names = Array.from(chainCandidates[1] || []);
            const votes = Array.from(chainCandidates[2] || []);

            candidates = candidatesDbResult.recordset.map(candidate => {
                const blockchainCandidateId = Number(candidate.blockchain_candidate_id || 0);
                const index = ids.findIndex(id => Number(id) === blockchainCandidateId);
                return {
                    candidateId: candidate.id,
                    blockchainCandidateId,
                    name: candidate.candidate_name || names[index] || '',
                    description: candidate.candidate_description || '',
                    imageUrl: candidate.image_url || '',
                    voteCount: index >= 0 ? Number(votes[index] || 0) : 0
                };
            });
        }

        candidates.sort((a, b) => b.voteCount - a.voteCount || a.candidateId - b.candidateId);

        const isFinalized = phase === 'Completed';

        res.json({
            electionId: election.id,
            blockchainElectionId: Number(election.election_id || 0),
            title: election.title,
            totalVotes,
            totalVoters: Number(election.approved_voter_count || 0),
            phase,
            isFinalized,
            message: isFinalized
                ? 'Kết quả đã được giải mã và chốt trên blockchain.'
                : 'Cuộc bầu cử đã có phiếu nhưng chưa hoàn tất bước giải mã/đếm phiếu trên blockchain nên số phiếu theo từng ứng cử viên chưa khả dụng.',
            candidates
        });
    } catch (error) {
        console.error('Lỗi lấy kết quả cuộc bầu cử:', error);
        res.status(500).json({ error: error.reason || error.message || 'Lỗi server khi lấy kết quả' });
    }
});

// ============= ELECTION REGISTRATION APIs =============

// User đăng ký tham gia cuộc bầu cử (3 ngày trước khi bắt đầu)
app.post('/api/elections/:electionId/join', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const userId = req.user.userId;

        const pool = await getPool();

        // Lấy wallet address từ database (không dùng từ token vì có thể đã cập nhật)
        const userResult = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT wallet_address FROM users WHERE id = @userId');

        if (userResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy thông tin người dùng' });
        }

        const walletAddress = userResult.recordset[0].wallet_address;

        if (!walletAddress) {
            return res.status(400).json({ error: 'Bạn cần kết nối MetaMask trước khi đăng ký tham gia bầu cử' });
        }

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

        // Lấy thông tin user (email, full_name)
        const userInfoResult = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT email, full_name FROM users WHERE id = @userId');

        const user = userInfoResult.recordset[0];

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

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

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

        res.json({
            message: 'Xác thực PIN thành công',
            success: true,
            canVote: true,
            election: {
                id: election.id,
                title: election.title,
                startTime: election.start_time,
                endTime: election.end_time
            }
        });

    } catch (error) {
        console.error('Lỗi xác thực PIN:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

app.post('/api/elections/:electionId/vote', authenticateToken, async (req, res) => {
    try {
        const { electionId } = req.params;
        const { blockchainElectionId, candidateBlockchainId, pinCode, voterAddress } = req.body;
        const userId = req.user.userId;

        if (!blockchainElectionId || !candidateBlockchainId || !pinCode || !voterAddress) {
            return res.status(400).json({ error: 'Thiếu dữ liệu bỏ phiếu' });
        }

        if (!ethers.isAddress(voterAddress)) {
            return res.status(400).json({ error: 'Địa chỉ ví cử tri không hợp lệ' });
        }

        const normalizedVoterAddress = voterAddress.toLowerCase();
        const pool = await getPool();

        const userResult = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT * FROM users WHERE id = @userId');

        if (userResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy thông tin người dùng' });
        }

        const user = userResult.recordset[0];
        if ((user.wallet_address || '').toLowerCase() !== normalizedVoterAddress) {
            return res.status(403).json({ error: 'Địa chỉ ví không khớp với tài khoản đăng nhập' });
        }

        const registrationResult = await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .input('pinCode', sql.NVarChar, pinCode)
            .query(`
                SELECT * FROM election_registrations
                WHERE user_id = @userId AND election_id = @electionId AND pin_code = @pinCode
            `);

        if (registrationResult.recordset.length === 0) {
            return res.status(401).json({ error: 'Mã PIN không đúng hoặc không thuộc về bạn' });
        }

        const registration = registrationResult.recordset[0];

        if (!registration.is_approved) {
            return res.status(403).json({ error: 'Đăng ký chưa được admin phê duyệt' });
        }

        if (registration.is_pin_used) {
            return res.status(400).json({ error: 'Bạn đã bỏ phiếu cuộc bầu cử này rồi' });
        }

        const electionResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .query('SELECT * FROM elections WHERE id = @electionId');

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];
        if (Number(election.election_id) !== Number(blockchainElectionId)) {
            return res.status(400).json({ error: 'Blockchain election ID không khớp' });
        }

        const now = new Date();
        if (now < new Date(election.start_time)) {
            return res.status(400).json({ error: 'Cuộc bầu cử chưa bắt đầu' });
        }

        if (now > new Date(election.end_time)) {
            return res.status(400).json({ error: 'Cuộc bầu cử đã kết thúc' });
        }

        const candidateResult = await pool.request()
            .input('electionId', sql.Int, electionId)
            .input('candidateBlockchainId', sql.Int, candidateBlockchainId)
            .query(`
                SELECT * FROM election_candidates
                WHERE election_db_id = @electionId AND blockchain_candidate_id = @candidateBlockchainId
            `);

        if (candidateResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Ứng cử viên không hợp lệ' });
        }

        const isRegisteredOnchain = await contract.isRegisteredVoter(blockchainElectionId, normalizedVoterAddress);
        if (!isRegisteredOnchain) {
            return res.status(400).json({ error: 'Cử tri chưa được đăng ký on-chain' });
        }

        const alreadyVotedOnchain = await contract.hasVoterVoted(blockchainElectionId, normalizedVoterAddress);
        if (alreadyVotedOnchain) {
            await pool.request()
                .input('registrationId', sql.Int, registration.id)
                .query(`
                    UPDATE election_registrations
                    SET is_pin_used = 1
                    WHERE id = @registrationId
                `);

            return res.status(400).json({ error: 'Bạn đã bỏ phiếu cuộc bầu cử này rồi' });
        }

        const encryptedVote = buildEncryptedVoteHex(candidateBlockchainId);
        const commitment = buildCommitmentHex({
            blockchainElectionId,
            candidateBlockchainId,
            voterAddress: normalizedVoterAddress,
            pinCode
        });

        const tx = await contract.castVoteForVoter(
            blockchainElectionId,
            normalizedVoterAddress,
            encryptedVote,
            commitment
        );
        await tx.wait();

        await pool.request()
            .input('registrationId', sql.Int, registration.id)
            .query(`
                UPDATE election_registrations
                SET is_pin_used = 1
                WHERE id = @registrationId
            `);

        res.json({
            success: true,
            message: tx.hash
        });
    } catch (error) {
        console.error('Lỗi server ký bỏ phiếu:', error);
        res.status(500).json({ error: error.reason || error.message || 'Lỗi server khi bỏ phiếu' });
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

        const tx = await provider.getTransaction(txHash);
        if (!tx) {
            return res.status(404).json({ error: 'Không tìm thấy dữ liệu giao dịch' });
        }

        const gasUsed = receipt.gasUsed;
        const gasPrice = tx.gasPrice ?? receipt.gasPrice;

        if (!gasPrice) {
            return res.status(400).json({ error: 'Không lấy được gasPrice của giao dịch' });
        }

        const totalCost = gasUsed * gasPrice;

        const pool = await getPool();

        await pool.request()
            .input('userId', sql.Int, userId)
            .input('electionId', sql.Int, electionId)
            .query(`
                UPDATE election_registrations
                SET is_pin_used = 1
                WHERE user_id = @userId AND election_id = @electionId AND is_approved = 1
            `);

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

// API lấy thông tin contract cho MetaMask
app.get('/api/contract-info', (req, res) => {
    res.json({
        contractAddress: process.env.CONTRACT_ADDRESS,
        rpcUrl: process.env.PROVIDER_URL
    });
});

// API cập nhật trạng thái on-chain sau khi transaction thành công từ MetaMask
app.post('/api/admin/elections/:electionDbId/update-onchain-status', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const { blockchainElectionId, txHash } = req.body;

        if (blockchainElectionId === null || blockchainElectionId === undefined || !txHash) {
            return res.status(400).json({ error: 'Thiếu thông tin blockchain' });
        }

        const pool = await getPool();
        const electionResult = await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .query(`
                SELECT
                    e.id,
                    ISNULL(candidate_stats.candidate_count, 0) AS candidate_count,
                    ISNULL(voter_stats.approved_voter_count, 0) AS approved_voter_count
                FROM elections e
                LEFT JOIN (
                    SELECT election_db_id, COUNT(*) AS candidate_count
                    FROM election_candidates
                    GROUP BY election_db_id
                ) candidate_stats ON candidate_stats.election_db_id = e.id
                LEFT JOIN (
                    SELECT election_id, COUNT(*) AS approved_voter_count
                    FROM election_registrations
                    WHERE is_approved = 1
                    GROUP BY election_id
                ) voter_stats ON voter_stats.election_id = e.id
                WHERE e.id = @electionDbId
            `);

        if (electionResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy cuộc bầu cử' });
        }

        const election = electionResult.recordset[0];
        const candidateCount = Number(election.candidate_count || 0);
        const approvedVoterCount = Number(election.approved_voter_count || 0);

        if (candidateCount < 2 || approvedVoterCount < 3) {
            return res.status(400).json({
                error: `Không thể cập nhật trạng thái on-chain vì chưa đủ điều kiện (hiện có ${candidateCount}/2 ứng cử viên và ${approvedVoterCount}/3 cử tri được duyệt)`
            });
        }

        await pool.request()
            .input('electionDbId', sql.Int, electionDbId)
            .input('blockchainElectionId', sql.Int, blockchainElectionId)
            .input('txHash', sql.NVarChar, txHash)
            .input('activatedAt', sql.DateTime, new Date())
            .query(`
                UPDATE elections
                SET is_onchain = 1,
                    election_id = @blockchainElectionId,
                    onchain_tx_hash = @txHash,
                    onchain_activated_at = @activatedAt
                WHERE id = @electionDbId
            `);

        res.json({
            message: 'Cập nhật trạng thái on-chain thành công',
            blockchainElectionId,
            txHash
        });

    } catch (error) {
        console.error('Lỗi cập nhật trạng thái on-chain:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============= START SERVER =============
const PORT = process.env.PORT || 3000;
// Endpoint để đánh dấu voters đã đăng ký lên blockchain
app.post('/api/admin/elections/:electionDbId/mark-voters-onchain', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const { voterIds, txHash } = req.body;

        console.log('📝 Mark voters onchain request:', { electionDbId, voterIds, txHash });

        if (!voterIds || !Array.isArray(voterIds) || voterIds.length === 0) {
            console.error('❌ Thiếu danh sách voter IDs');
            return res.status(400).json({ error: 'Thiếu danh sách voter IDs' });
        }

        const pool = await getPool();

        // Cập nhật trạng thái registered_to_blockchain cho các voters
        const placeholders = voterIds.map((_, i) => `@voterId${i}`).join(',');
        const query = `
            UPDATE election_registrations
            SET registered_to_blockchain = 1
            WHERE election_id = @electionId
            AND user_id IN (${placeholders})
        `;

        console.log('📝 SQL Query:', query);
        console.log('📝 Parameters:', { electionId: electionDbId, voterIds });

        const request = pool.request();
        request.input('electionId', sql.Int, parseInt(electionDbId));
        voterIds.forEach((id, i) => {
            request.input(`voterId${i}`, sql.Int, parseInt(id));
        });

        const result = await request.query(query);

        console.log('✅ Update result:', { rowsAffected: result.rowsAffected[0] });

        res.json({
            message: `Đã cập nhật trạng thái blockchain cho ${result.rowsAffected[0]} cử tri`,
            txHash: txHash,
            updatedCount: result.rowsAffected[0]
        });

    } catch (error) {
        console.error('❌ Lỗi cập nhật trạng thái voters:', error);
        res.status(500).json({ error: 'Lỗi server: ' + error.message });
    }
});

// Endpoint để đánh dấu candidates đã đăng ký lên blockchain
app.post('/api/admin/elections/:electionDbId/mark-candidates-onchain', authenticateAdmin, async (req, res) => {
    try {
        const { electionDbId } = req.params;
        const { candidates, txHash } = req.body;

        console.log('📝 Mark candidates onchain request:', { electionDbId, candidates, txHash });

        if (!Array.isArray(candidates) || candidates.length === 0) {
            return res.status(400).json({ error: 'Thiếu danh sách candidates' });
        }

        const invalidCandidate = candidates.find(candidate => (
            candidate?.candidateId === undefined ||
            candidate?.candidateId === null ||
            candidate?.blockchainCandidateId === undefined ||
            candidate?.blockchainCandidateId === null
        ));

        if (invalidCandidate) {
            return res.status(400).json({ error: 'Danh sách candidates không hợp lệ' });
        }

        const pool = await getPool();
        const candidateIds = candidates.map((_, i) => `@candidateId${i}`).join(',');
        const caseSql = candidates
            .map((_, i) => `WHEN id = @candidateId${i} THEN @blockchainCandidateId${i}`)
            .join(' ');

        const query = `
            UPDATE election_candidates
            SET blockchain_candidate_id = CASE ${caseSql} END,
                updated_at = GETDATE()
            WHERE election_db_id = @electionDbId
              AND id IN (${candidateIds})
        `;

        const request = pool.request();
        request.input('electionDbId', sql.Int, parseInt(electionDbId));
        candidates.forEach((candidate, i) => {
            request.input(`candidateId${i}`, sql.Int, parseInt(candidate.candidateId));
            request.input(`blockchainCandidateId${i}`, sql.Int, parseInt(candidate.blockchainCandidateId));
        });

        const result = await request.query(query);

        res.json({
            message: `Đã cập nhật blockchain candidate ID cho ${result.rowsAffected[0]} ứng cử viên`,
            txHash,
            updatedCount: result.rowsAffected[0]
        });
    } catch (error) {
        console.error('❌ Lỗi cập nhật trạng thái candidates:', error);
        res.status(500).json({ error: 'Lỗi server: ' + error.message });
    }
});

// Endpoint để cập nhật blockchain_candidate_id sau khi đăng ký lên blockchain
app.post('/api/admin/candidates/:candidateId/update-blockchain-id', authenticateAdmin, async (req, res) => {
    try {
        const { candidateId } = req.params;
        const { blockchainCandidateId, txHash } = req.body;

        console.log('📝 Update candidate blockchain ID:', { candidateId, blockchainCandidateId, txHash });

        if (blockchainCandidateId === null || blockchainCandidateId === undefined) {
            console.error('❌ Thiếu blockchain candidate ID');
            return res.status(400).json({ error: 'Thiếu blockchain candidate ID' });
        }

        const pool = await getPool();

        const query = `
            UPDATE election_candidates
            SET blockchain_candidate_id = @blockchainCandidateId
            WHERE id = @candidateId
        `;

        console.log('📝 SQL Query:', query);
        console.log('📝 Parameters:', { candidateId, blockchainCandidateId });

        const request = pool.request();
        request.input('candidateId', sql.Int, parseInt(candidateId));
        request.input('blockchainCandidateId', sql.Int, parseInt(blockchainCandidateId));

        const result = await request.query(query);

        console.log('✅ Update result:', { rowsAffected: result.rowsAffected[0] });

        res.json({
            message: `Đã cập nhật blockchain candidate ID cho ứng cử viên`,
            txHash: txHash,
            blockchainCandidateId: blockchainCandidateId,
            updatedCount: result.rowsAffected[0]
        });

    } catch (error) {
        console.error('❌ Lỗi cập nhật blockchain candidate ID:', error);
        res.status(500).json({ error: 'Lỗi server: ' + error.message });
    }
});

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
