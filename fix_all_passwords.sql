-- Fix All Password Hashes for Representatives and Members
-- Run this in Supabase SQL Editor

-- ============================================
-- DISABLE TRIGGER TEMPORARILY
-- ============================================
-- Disable the primary representative trigger to avoid conflicts during password updates
ALTER TABLE representatives DISABLE TRIGGER ensure_one_primary_rep_trigger;

-- ============================================
-- UPDATE MASTER ADMIN PASSWORD
-- ============================================
-- Email: admin@receiptcapture.com
-- Password: admin123
UPDATE representatives
SET password_hash = '$2b$12$AhwJqwsoHWAta/Z/YzwCpOY3mMEzFdwLwqI8bWruWfwh0cVY9beie'
WHERE email = 'admin@receiptcapture.com';

-- ============================================
-- UPDATE ALL REPRESENTATIVE PASSWORDS
-- ============================================
-- All representatives use password: password123
-- Hash: $2b$12$F.YVLmWDigr9aX5zyJg8UuM5z.IUFA4bAC7zagoar37MvUL6Zkk6q

UPDATE representatives
SET password_hash = '$2b$12$F.YVLmWDigr9aX5zyJg8UuM5z.IUFA4bAC7zagoar37MvUL6Zkk6q'
WHERE email IN (
    'rep@techcorp.com',
    'sarah@techcorp.com',
    'rep@marketinginc.com',
    'rep@startup.io'
);

-- ============================================
-- RE-ENABLE TRIGGER
-- ============================================
-- Re-enable the trigger after updates are complete
ALTER TABLE representatives ENABLE TRIGGER ensure_one_primary_rep_trigger;

-- ============================================
-- UPDATE ALL MEMBER PASSWORDS
-- ============================================
-- All members use password: member123
-- Hash: $2b$12$hfrAe4HN6Iaj32STF0edwOOBtT1fRpGLC60DIsaP6sG0Tm1ksD4x2

UPDATE members
SET password_hash = '$2b$12$hfrAe4HN6Iaj32STF0edwOOBtT1fRpGLC60DIsaP6sG0Tm1ksD4x2'
WHERE email IN (
    'employee@techcorp.com',
    'bob@techcorp.com',
    'lisa@techcorp.com',
    'tom@marketinginc.com'
);

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify all representatives have updated passwords
SELECT 
    email,
    role,
    is_active,
    LEFT(password_hash, 30) || '...' as password_hash_preview,
    CASE 
        WHEN email = 'admin@receiptcapture.com' THEN '✅ Password: admin123'
        ELSE '✅ Password: password123'
    END as password
FROM representatives 
ORDER BY 
    CASE 
        WHEN role = 'master_admin' THEN 1
        WHEN role = 'primary_representative' THEN 2
        ELSE 3
    END,
    email;

-- Verify all members have updated passwords
SELECT 
    email,
    role,
    is_active,
    LEFT(password_hash, 30) || '...' as password_hash_preview,
    '✅ Password: member123' as password
FROM members 
ORDER BY email;

-- Summary
SELECT '========================================' as info;
SELECT 'PASSWORD UPDATE COMPLETE!' as info;
SELECT '========================================' as info;

SELECT 
    'MASTER ADMIN' as user_type,
    'admin@receiptcapture.com' as email,
    'admin123' as password,
    'Full platform access' as notes
UNION ALL
SELECT 
    'Representatives',
    'rep@techcorp.com, sarah@techcorp.com, rep@marketinginc.com, rep@startup.io',
    'password123',
    'Company portal access'
UNION ALL
SELECT 
    'Members',
    'employee@techcorp.com, bob@techcorp.com, lisa@techcorp.com, tom@marketinginc.com',
    'member123',
    'Mobile app users';

SELECT '========================================' as info;
SELECT 'All passwords have been updated!' as info;
SELECT 'You can now login with the credentials above' as info;
SELECT '========================================' as info;
