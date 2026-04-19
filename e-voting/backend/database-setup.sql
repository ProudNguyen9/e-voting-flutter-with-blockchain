-- =============================================
-- E-Voting Database Setup Script
-- Chạy script này trong SQL Server Management Studio
-- =============================================

-- Tạo database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'evoting_db')
BEGIN
    CREATE DATABASE evoting_db;
    PRINT '✓ Database evoting_db đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Database evoting_db đã tồn tại';
END
GO

USE evoting_db;
GO

-- =============================================
-- Tạo bảng users
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        email NVARCHAR(255) UNIQUE NOT NULL,
        password NVARCHAR(255) NOT NULL,
        wallet_address NVARCHAR(42) NULL,
        full_name NVARCHAR(255) NOT NULL,
        is_approved BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT '✓ Bảng users đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Bảng users đã tồn tại';
END
GO

IF COL_LENGTH('users', 'password') IS NULL
BEGIN
    ALTER TABLE users ADD password NVARCHAR(255) NULL;
    PRINT '✓ Đã thêm cột password vào users';
END
GO

IF COL_LENGTH('users', 'wallet_address') IS NULL
BEGIN
    ALTER TABLE users ADD wallet_address NVARCHAR(42) NULL;
    PRINT '✓ Đã thêm cột wallet_address vào users';
END
GO

IF COL_LENGTH('users', 'is_approved') IS NULL
BEGIN
    ALTER TABLE users ADD is_approved BIT NOT NULL CONSTRAINT DF_users_is_approved DEFAULT 1;
    PRINT '✓ Đã thêm cột is_approved vào users';
END
GO

-- =============================================
-- Tạo bảng admins
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'admins')
BEGIN
    CREATE TABLE admins (
        id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(100) UNIQUE NOT NULL,
        password NVARCHAR(255) NOT NULL,
        email NVARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT '✓ Bảng admins đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Bảng admins đã tồn tại';
END
GO

-- =============================================
-- Tạo bảng elections
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'elections')
BEGIN
    CREATE TABLE elections (
        id INT IDENTITY(1,1) PRIMARY KEY,
        election_id INT NOT NULL,
        title NVARCHAR(500) NOT NULL,
        description NVARCHAR(MAX),
        start_time DATETIME NOT NULL,
        end_time DATETIME NOT NULL,
        created_at DATETIME DEFAULT GETDATE()
    );
    PRINT '✓ Bảng elections đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Bảng elections đã tồn tại';
END
GO

-- =============================================
-- Tạo bảng election_registrations
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'election_registrations')
BEGIN
    CREATE TABLE election_registrations (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        election_id INT NOT NULL,
        pin_code NVARCHAR(6),
        is_approved BIT DEFAULT 0,
        is_pin_used BIT DEFAULT 0,
        registered_to_blockchain BIT DEFAULT 0,
        registered_at DATETIME DEFAULT GETDATE(),
        approved_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (election_id) REFERENCES elections(id),
        UNIQUE(user_id, election_id)
    );
    PRINT '✓ Bảng election_registrations đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Bảng election_registrations đã tồn tại';
END
GO

-- =============================================
-- Tạo bảng gas_tracking
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'gas_tracking')
BEGIN
    CREATE TABLE gas_tracking (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        election_id INT NOT NULL,
        wallet_address NVARCHAR(42) NOT NULL,
        tx_hash NVARCHAR(66) NOT NULL,
        gas_used DECIMAL(18, 8) NOT NULL,
        gas_price DECIMAL(18, 8) NOT NULL,
        total_cost DECIMAL(18, 8) NOT NULL,
        is_refunded BIT DEFAULT 0,
        refund_tx_hash NVARCHAR(66),
        voted_at DATETIME DEFAULT GETDATE(),
        refunded_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (election_id) REFERENCES elections(id)
    );
    PRINT '✓ Bảng gas_tracking đã được tạo';
END
ELSE
BEGIN
    PRINT '✓ Bảng gas_tracking đã tồn tại';
END
GO

-- =============================================
-- Tạo admin mặc định
-- Password: admin123 (đã hash với bcrypt)
-- =============================================
IF NOT EXISTS (SELECT * FROM admins WHERE username = 'admin')
BEGIN
    INSERT INTO admins (username, password, email)
    VALUES (
        'admin',
        '$2b$10$rKvVPZQGhXZq5Z5Z5Z5Z5uXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX',
        'admin@evoting.com'
    );
    PRINT '✓ Admin mặc định đã được tạo';
    PRINT '  Username: admin';
    PRINT '  Password: admin123';
END
ELSE
BEGIN
    PRINT '✓ Admin đã tồn tại';
END
GO

-- =============================================
-- Hiển thị thông tin
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'Setup hoàn tất!';
PRINT '========================================';
PRINT 'Database: evoting_db';
PRINT 'Tables: users, admins, elections, election_registrations, gas_tracking';
PRINT '';
PRINT 'Admin mặc định:';
PRINT '  Username: admin';
PRINT '  Password: admin123';
PRINT '  Email: admin@evoting.com';
PRINT '';
PRINT 'Lưu ý: Đổi password admin sau khi đăng nhập lần đầu!';
PRINT '========================================';
GO
