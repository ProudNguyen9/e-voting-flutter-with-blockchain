const { getPool, sql } = require('./database');

async function updateExistingUsers() {
    try {
        console.log('Đang kết nối đến SQL Server...');
        const pool = await getPool();

        console.log('Đang cập nhật tất cả user cũ...');
        const result = await pool.request()
            .query('UPDATE users SET is_approved = 1 WHERE is_approved = 0');

        console.log(`\n✅ Đã cập nhật ${result.rowsAffected[0]} user thành is_approved = 1`);

        // Hiển thị danh sách user
        const users = await pool.request()
            .query('SELECT id, email, full_name, is_approved, created_at FROM users ORDER BY created_at DESC');

        console.log('\n📋 Danh sách user hiện tại:');
        console.table(users.recordset);

        process.exit(0);
    } catch (error) {
        console.error('❌ Lỗi:', error);
        process.exit(1);
    }
}

updateExistingUsers();
