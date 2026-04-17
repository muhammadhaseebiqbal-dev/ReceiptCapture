-- Update Master Admin Password
-- Run this in Supabase SQL Editor

-- Update the password hash for admin@receiptcapture.com
-- New hash for password: admin123
UPDATE representatives
SET password_hash = '$2b$12$AhwJqwsoHWAta/Z/YzwCpOY3mMEzFdwLwqI8bWruWfwh0cVY9beie'
WHERE email = 'admin@receiptcapture.com';

-- Verify the update
SELECT 
    email,
    LEFT(password_hash, 30) || '...' as password_hash_preview,
    role,
    is_active,
    '✅ Password updated for admin123' as status
FROM representatives 
WHERE email = 'admin@receiptcapture.com';
