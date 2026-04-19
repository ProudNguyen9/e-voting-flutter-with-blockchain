const bcrypt = require('bcrypt');
const sql = require('mssql');
require('dotenv').config();

// Parse connection string
function parseConnectionString(connStr) {
    const config = {
        options: {
            encrypt: false,
            trustServerCertificate: true
        }
    };

    const parts = connStr.split(';');
    parts.forEach(part => {
        const [key, value] = part.split('=').map(s => s.trim());
        if (!key || !value) return;

        const lowerKey = key.toLowerCase();
        if (lowerKey === 'server' || lowerKey === 'data source') {
            if (value.includes('\\')) {
                const [serverName, instanceName] = value.split('\\');
                config.server = serverName === '.' || serverName.toLowerCase() === '(local)' ? 'localhost' : serverName;
                config.options.instanceName = instanceName;
            } else {
                config.server = value === '.' || value.toLowerCase() === '(local)' ? 'localhost' : value;
            }
        } else if (lowerKey === 'database' || lowerKey === 'initial catalog') {
            config.database = value;
        } else if (lowerKey === 'user id' || lowerKey === 'uid') {
            config.user = value;
        } else if (lowerKey === 'password' || lowerKey === 'pwd') {
            config.password = value;
        }
    });

    return config;
}

const config = process.env.DB_CONNECTION_STRING
    ? parseConnectionString(process.env.DB_CONNECTION_STRING)
    : {
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        server: process.env.DB_SERVER,
        database: process.env.DB_NAME,
        options: {
            encrypt: false,
            trustServerCertificate: true
        }
    };

async function createAdmin() {
    try {
        console.log('Đang kết nối đến SQL Server...');
        const pool = await sql.connect(config);

        // Hash password
        const password = 'admin123';
        const hashedPassword = await bcrypt.hash(password, 10);

        console.log('Đang xóa admin cũ (nếu có)...');
        await pool.request()
            .input('username', sql.NVarChar, 'admin')
            .query('DELETE FROM admins WHERE username = @username');

        console.log('Đang tạo admin mới...');
        await pool.request()
            .input('username', sql.NVarChar, 'admin')
            .input('password', sql.NVarChar, hashedPassword)
            .input('email', sql.NVarChar, 'admin@evoting.com')
            .query(`
                INSERT INTO admins (username, password, email)
                VALUES (@username, @password, @email)
            `);

        console.log('\n✅ Tạo admin thành công!');
        console.log('📝 Thông tin đăng nhập:');
        console.log('   Username: admin');
        console.log('   Password: admin123');
        console.log('   Email: admin@evoting.com');

        await pool.close();
        process.exit(0);
    } catch (err) {
        console.error('❌ Lỗi:', err.message);
        process.exit(1);
    }
}

createAdmin();
