-- Verification Script - Check Database State
-- Run this in Supabase SQL Editor to see what was created

-- 1. Check all tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN (
        'subscription_plans', 
        'registered_companies', 
        'transaction_history',
        'representatives', 
        'members', 
        'receipts', 
        'usage_statistics',
        'email_verification_tokens'
    )
ORDER BY table_name;

-- 2. Check record counts
SELECT 'subscription_plans' as table_name, COUNT(*) as records FROM subscription_plans
UNION ALL
SELECT 'registered_companies', COUNT(*) FROM registered_companies
UNION ALL
SELECT 'representatives', COUNT(*) FROM representatives
UNION ALL
SELECT 'members', COUNT(*) FROM members
UNION ALL
SELECT 'transaction_history', COUNT(*) FROM transaction_history
UNION ALL
SELECT 'receipts', COUNT(*) FROM receipts
UNION ALL
SELECT 'usage_statistics', COUNT(*) FROM usage_statistics;

-- 3. Check all representatives (CRITICAL - should see master admin here)
SELECT 
    id,
    email,
    first_name || ' ' || last_name as name,
    role,
    company_id,
    is_active,
    verified_email,
    email_verified
FROM representatives
ORDER BY role DESC, created_at;

-- 4. Check if master admin exists specifically
SELECT 
    'MASTER ADMIN STATUS' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM representatives WHERE email = 'admin@receiptcapture.com')
        THEN '✅ EXISTS'
        ELSE '❌ NOT FOUND'
    END as status;

-- 5. Check password hash for master admin
SELECT 
    email,
    LEFT(password_hash, 20) || '...' as password_hash_preview,
    role,
    is_active
FROM representatives 
WHERE email = 'admin@receiptcapture.com';

-- 6. Check all companies
SELECT 
    id,
    name,
    subscription_status,
    industry,
    company_size
FROM registered_companies
ORDER BY created_at;

-- 7. Check demo credentials summary
SELECT 
    'admin@receiptcapture.com' as email,
    'admin123' as password,
    'Master Admin' as role,
    CASE 
        WHEN EXISTS (SELECT 1 FROM representatives WHERE email = 'admin@receiptcapture.com' AND is_active = true)
        THEN '✅ Ready to login'
        ELSE '❌ Not found or inactive'
    END as login_status
UNION ALL
SELECT 
    'rep@techcorp.com',
    'password123',
    'Primary Representative',
    CASE 
        WHEN EXISTS (SELECT 1 FROM representatives WHERE email = 'rep@techcorp.com' AND is_active = true)
        THEN '✅ Ready to login'
        ELSE '❌ Not found or inactive'
    END
UNION ALL
SELECT 
    'employee@techcorp.com',
    'member123',
    'Member (Sales)',
    CASE 
        WHEN EXISTS (SELECT 1 FROM members WHERE email = 'employee@techcorp.com' AND is_active = true)
        THEN '✅ Ready to login'
        ELSE '❌ Not found or inactive'
    END;
