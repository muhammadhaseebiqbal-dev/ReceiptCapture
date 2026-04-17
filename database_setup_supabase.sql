-- Receipt Capture Database Setup Script for Supabase
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Subscription Plans Table
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(20) NOT NULL, -- 'monthly', 'annual'
    max_users INTEGER NOT NULL,
    max_receipts_per_month INTEGER,
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Companies (Organizations) Table
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    destination_email VARCHAR(255) NOT NULL,
    subscription_plan_id UUID REFERENCES subscription_plans(id),
    subscription_status VARCHAR(20) DEFAULT 'inactive', -- 'active', 'inactive', 'cancelled', 'trial'
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Portal Users (Company Representatives) Table
CREATE TABLE IF NOT EXISTS portal_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- 'master_admin', 'company_representative'
    company_id UUID REFERENCES companies(id),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- App Users (Staff Members - from mobile app) Table
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    company_id UUID REFERENCES companies(id),
    role VARCHAR(50) DEFAULT 'employee', -- 'manager', 'employee'
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES portal_users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Receipts Table
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app_users(id),
    company_id UUID REFERENCES companies(id),
    image_path VARCHAR(500) NOT NULL,
    merchant_name VARCHAR(255),
    amount DECIMAL(10,2),
    receipt_date DATE,
    category VARCHAR(100),
    notes TEXT,
    ocr_data JSONB,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processed', 'sent'
    email_sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subscription Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id),
    stripe_payment_intent_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) NOT NULL, -- 'pending', 'succeeded', 'failed'
    billing_period_start DATE,
    billing_period_end DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage Tracking Table
CREATE TABLE IF NOT EXISTS usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id),
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    receipts_processed INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, month, year)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_companies_subscription_status ON companies(subscription_status);
CREATE INDEX IF NOT EXISTS idx_app_users_company_id ON app_users(company_id);
CREATE INDEX IF NOT EXISTS idx_receipts_company_id ON receipts(company_id);
CREATE INDEX IF NOT EXISTS idx_receipts_user_id ON receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);
CREATE INDEX IF NOT EXISTS idx_receipts_created_at ON receipts(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_company_id ON payments(company_id);
CREATE INDEX IF NOT EXISTS idx_usage_stats_company_month ON usage_stats(company_id, year, month);
CREATE INDEX IF NOT EXISTS idx_portal_users_email ON portal_users(email);
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portal_users_updated_at BEFORE UPDATE ON portal_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_users_updated_at BEFORE UPDATE ON app_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert Sample Subscription Plans
INSERT INTO subscription_plans (name, description, price, billing_cycle, max_users, max_receipts_per_month, features)
VALUES 
    ('Starter', 'Perfect for small teams', 29.99, 'monthly', 5, 100, '{"support": "email", "storage": "1GB"}'),
    ('Professional', 'Growing businesses', 59.99, 'monthly', 20, 500, '{"support": "priority", "storage": "10GB", "analytics": true}'),
    ('Enterprise', 'Large organizations', 149.99, 'monthly', 100, 2000, '{"support": "phone", "storage": "unlimited", "analytics": true, "api_access": true}')
ON CONFLICT DO NOTHING;

-- Get the Professional plan ID for demo company
DO $$
DECLARE
    pro_plan_id UUID;
    demo_company_id UUID;
    admin_user_id UUID;
BEGIN
    -- Get Professional plan ID
    SELECT id INTO pro_plan_id FROM subscription_plans WHERE name = 'Professional' LIMIT 1;

    -- Insert Demo Company
    INSERT INTO companies (name, domain, destination_email, subscription_plan_id, subscription_status, subscription_start_date)
    VALUES ('TechCorp Demo', 'techcorp.com', 'receipts@techcorp.com', pro_plan_id, 'active', CURRENT_TIMESTAMP)
    ON CONFLICT DO NOTHING
    RETURNING id INTO demo_company_id;

    -- If demo_company_id is NULL (already exists), fetch it
    IF demo_company_id IS NULL THEN
        SELECT id INTO demo_company_id FROM companies WHERE name = 'TechCorp Demo' LIMIT 1;
    END IF;

    -- Insert Master Admin User
    -- Password: admin123 (hashed with bcrypt)
    INSERT INTO portal_users (email, password_hash, name, role, is_active, email_verified)
    VALUES (
        'admin@receiptcapture.com', 
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5OMh/h8xH1Xbm', -- admin123
        'Portal Master Admin', 
        'master_admin', 
        true, 
        true
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO admin_user_id;

    -- Insert Company Representative
    -- Password: password123 (hashed with bcrypt)
    INSERT INTO portal_users (email, password_hash, name, role, company_id, is_active, email_verified)
    VALUES (
        'rep@techcorp.com', 
        '$2a$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', -- password123
        'John Doe', 
        'company_representative', 
        demo_company_id, 
        true, 
        true
    )
    ON CONFLICT (email) DO NOTHING;

END $$;

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE portal_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_stats ENABLE ROW LEVEL SECURITY;

-- Subscription Plans: Public read access (for pricing page)
CREATE POLICY "Anyone can view active subscription plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- Portal Users: Users can read their own data
CREATE POLICY "Users can view their own data" ON portal_users
    FOR SELECT USING (auth.uid()::text = id::text);

-- Companies: Company representatives can view their own company
CREATE POLICY "Company representatives can view their company" ON companies
    FOR SELECT USING (
        id IN (
            SELECT company_id FROM portal_users WHERE id::text = auth.uid()::text
        )
    );

-- Master admins can view all companies
CREATE POLICY "Master admins can view all companies" ON companies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM portal_users 
            WHERE id::text = auth.uid()::text AND role = 'master_admin'
        )
    );

-- App Users: Company representatives can manage users in their company
CREATE POLICY "Company reps can manage their company users" ON app_users
    FOR ALL USING (
        company_id IN (
            SELECT company_id FROM portal_users WHERE id::text = auth.uid()::text
        )
    );

-- Receipts: Users can view receipts from their company
CREATE POLICY "Users can view their company receipts" ON receipts
    FOR SELECT USING (
        company_id IN (
            SELECT company_id FROM portal_users WHERE id::text = auth.uid()::text
        )
    );

-- Payments: Company representatives can view their company payments
CREATE POLICY "Company reps can view their payments" ON payments
    FOR SELECT USING (
        company_id IN (
            SELECT company_id FROM portal_users WHERE id::text = auth.uid()::text
        )
    );

-- Usage Stats: Company representatives can view their stats
CREATE POLICY "Company reps can view their usage stats" ON usage_stats
    FOR SELECT USING (
        company_id IN (
            SELECT company_id FROM portal_users WHERE id::text = auth.uid()::text
        )
    );

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to anon users (for public pages like pricing)
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON subscription_plans TO anon;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify demo data
SELECT 'Subscription Plans' as table_name, COUNT(*) as record_count FROM subscription_plans
UNION ALL
SELECT 'Companies', COUNT(*) FROM companies
UNION ALL
SELECT 'Portal Users', COUNT(*) FROM portal_users
UNION ALL
SELECT 'App Users', COUNT(*) FROM app_users
UNION ALL
SELECT 'Receipts', COUNT(*) FROM receipts;

-- Show demo users
SELECT email, name, role, is_active, email_verified 
FROM portal_users 
ORDER BY created_at;

-- Show demo company
SELECT c.name, c.subscription_status, sp.name as plan_name, c.destination_email
FROM companies c
LEFT JOIN subscription_plans sp ON c.subscription_plan_id = sp.id;
