-- Fix Master Admin - Run this in Supabase SQL Editor

-- First, check if master admin exists
SELECT * FROM representatives WHERE email = 'admin@receiptcapture.com';

-- If not found, insert master admin
-- Password: admin123
INSERT INTO representatives (
    email, 
    password_hash, 
    first_name, 
    last_name, 
    role, 
    verified_email, 
    email_verified, 
    is_active,
    permissions,
    company_id
)
VALUES (
    'admin@receiptcapture.com', 
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5OMh/h8xH1Xbm',
    'Portal', 
    'Master Admin', 
    'master_admin',
    'admin@receiptcapture.com', 
    true, 
    true,
    '{"full_access": true, "can_manage_all_companies": true, "can_manage_plans": true}',
    NULL  -- No company for master admin
)
ON CONFLICT (email) 
DO UPDATE SET
    password_hash = '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5OMh/h8xH1Xbm',
    role = 'master_admin',
    is_active = true
RETURNING *;

-- Verify the insert
SELECT 
    id,
    email,
    first_name,
    last_name,
    role,
    verified_email,
    is_active,
    company_id
FROM representatives 
WHERE email = 'admin@receiptcapture.com';
