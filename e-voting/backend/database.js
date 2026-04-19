const sql = require('mssql');
require('dotenv').config();

function normalizeServerName(server) {
    if (!server) return 'localhost';

    const s = server.trim();

    if (s === '.' || s.toLowerCase() === '(local)') {
        return 'localhost';
    }

    return s;
}

// Parse connection string kiểu .NET Core
function parseConnectionString(connStr) {
    const config = {
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        pool: {
            max: 10,
            min: 0,
            idleTimeoutMillis: 30000
        }
    };

    const parts = connStr.split(';');

    parts.forEach(part => {
        const [rawKey, ...rawValueParts] = part.split('=');
        const key = rawKey?.trim();
        const value = rawValueParts.join('=').trim();

        if (!key || !value) return;

        const lowerKey = key.toLowerCase();

        if (lowerKey === 'server' || lowerKey === 'data source') {
            const serverValue = normalizeServerName(value);

            // Trường hợp localhost\SQLEXPRESS
            if (serverValue.includes('\\')) {
                const [serverName, instanceName] = serverValue.split('\\');
                config.server = normalizeServerName(serverName);
                config.options.instanceName = instanceName;
            }
            // Trường hợp localhost,1433
            else if (serverValue.includes(',')) {
                const [serverName, port] = serverValue.split(',');
                config.server = normalizeServerName(serverName);
                const parsedPort = parseInt(port, 10);
                if (!isNaN(parsedPort)) {
                    config.port = parsedPort;
                }
            }
            // Trường hợp chỉ có localhost
            else {
                config.server = serverValue;
            }
        } else if (lowerKey === 'database' || lowerKey === 'initial catalog') {
            config.database = value;
        } else if (lowerKey === 'user id' || lowerKey === 'uid') {
            config.user = value;
        } else if (lowerKey === 'password' || lowerKey === 'pwd') {
            config.password = value;
        } else if (lowerKey === 'trustservercertificate') {
            config.options.trustServerCertificate = value.toLowerCase() === 'true';
        } else if (lowerKey === 'encrypt') {
            config.options.encrypt = value.toLowerCase() === 'true';
        }
    });

    if (!config.server) {
        config.server = 'localhost';
    }

    return config;
}

// Tạo config từ env thường
function buildConfigFromEnv() {
    const server = normalizeServerName(process.env.DB_SERVER || 'localhost');

    const config = {
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        server,
        database: process.env.DB_NAME,
        options: {
            encrypt: false,
            trustServerCertificate: true
        },
        pool: {
            max: 10,
            min: 0,
            idleTimeoutMillis: 30000
        }
    };

    // Nếu có DB_INSTANCE thì ưu tiên instance, không cần port
    if (process.env.DB_INSTANCE) {
        config.options.instanceName = process.env.DB_INSTANCE;
    }
    // Nếu không có instance mà có port thì mới gán port
    else if (process.env.DB_PORT) {
        const parsedPort = parseInt(process.env.DB_PORT, 10);
        if (!isNaN(parsedPort)) {
            config.port = parsedPort;
        }
    }

    return config;
}

const config = process.env.DB_CONNECTION_STRING
    ? parseConnectionString(process.env.DB_CONNECTION_STRING)
    : buildConfigFromEnv();

let pool = null;

async function getPool() {
    try {
        if (!pool) {
            pool = await sql.connect(config);
            console.log('✅ Connected to SQL Server');
        }
        return pool;
    } catch (err) {
        pool = null;
        console.error('❌ SQL connection error:', err);
        throw err;
    }
}

async function query(queryString, params = {}) {
    try {
        const pool = await getPool();
        const request = pool.request();

        for (const [key, value] of Object.entries(params)) {
            request.input(key, value);
        }

        const result = await request.query(queryString);
        return result;
    } catch (err) {
        console.error('Database query error:', err);
        throw err;
    }
}

async function closePool() {
    if (pool) {
        await pool.close();
        pool = null;
    }
}

module.exports = {
    sql,
    getPool,
    query,
    closePool
};