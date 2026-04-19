-- =============================================
-- Script cập nhật user cũ thành tự động duyệt
-- Chạy script này trong SQL Server Management Studio
-- =============================================

USE evoting_db;
GO

-- Cập nhật tất cả user cũ thành đã duyệt
UPDATE users 
SET is_approved = 1
WHERE is_approved = 0;

PRINT '✓ Đã cập nhật tất cả user cũ thành is_approved = 1';

-- Hiển thị kết quả
SELECT 
    id,
    email,
    full_name,
    is_approved,
    created_at
FROM users
ORDER BY created_at DESC;

PRINT '';
PRINT '========================================';
PRINT 'Cập nhật hoàn tất!';
PRINT 'Tất cả user hiện tại đã được tự động duyệt.';
PRINT '========================================';
GO
