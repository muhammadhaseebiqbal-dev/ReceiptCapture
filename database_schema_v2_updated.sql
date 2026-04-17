-- Receipt Capture Database Setup Script for Supabase (UPDATED SCHEMA)
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CORE TABLES
-- ============================================

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Registered Companies Table
-- This table stores all companies that register on the platform
CREATE TABLE IF NOT EXISTS registered_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    industry VARCHAR(100),
    company_size VARCHAR(50), -- 'small', 'medium', 'large', 'enterprise'
    address TEXT,
    phone VARCHAR(50),
    website VARCHAR(255),
    
    -- Current Subscription Info
    current_plan_id UUID REFERENCES subscription_plans(id),
    subscription_status VARCHAR(20) DEFAULT 'inactive', -- 'active', 'inactive', 'cancelled', 'trial', 'suspended'
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    
    -- Payment Info
    stripe_customer_id VARCHAR(255),
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction History Table
-- This table stores all subscription purchases, renewals, upgrades, downgrades
CREATE TABLE IF NOT EXISTS transaction_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES registered_companies(id) ON DELETE CASCADE,
    
    -- Transaction Type
    transaction_type VARCHAR(50) NOT NULL, -- 'purchase', 'renewal', 'upgrade', 'downgrade', 'cancellation', 'refund'
    
    -- Plan Details at time of transaction
    plan_id UUID REFERENCES subscription_plans(id),
    plan_name VARCHAR(100) NOT NULL,
    plan_price DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(20) NOT NULL,
    
    -- Transaction Details
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Subscription Period
    subscription_start_date TIMESTAMP NOT NULL,
    subscription_end_date TIMESTAMP NOT NULL,
    
    -- Payment Info
    payment_status VARCHAR(20) NOT NULL, -- 'pending', 'succeeded', 'failed', 'refunded'
    payment_method VARCHAR(50), -- 'credit_card', 'debit_card', 'bank_transfer', 'paypal'
    stripe_payment_intent_id VARCHAR(255),
    stripe_invoice_id VARCHAR(255),
    
    -- Additional Info
    notes TEXT,
    metadata JSONB,
    
    -- Timestamps
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Company Representatives Table
-- These are the portal users who manage the company account
CREATE TABLE IF NOT EXISTS representatives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES registered_companies(id) ON DELETE CASCADE,
    
    -- Personal Info
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    job_title VARCHAR(100),
    
    -- Verified Email for Receipt Forwarding
    verified_email VARCHAR(255), -- Email where all receipts will be forwarded
    email_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP,
    
    -- Role & Permissions
    role VARCHAR(50) NOT NULL DEFAULT 'representative', -- 'master_admin', 'primary_representative', 'representative'
    permissions JSONB, -- Custom permissions: {"can_add_users": true, "can_view_billing": true, etc}
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_primary BOOLEAN DEFAULT false, -- One primary representative per company
    
    -- Login Info
    last_login_at TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_representative_role CHECK (role IN ('master_admin', 'primary_representative', 'representative'))
);

-- Members Table (Staff/Employees who use the mobile app)
-- These are the company employees who scan receipts via mobile app
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES registered_companies(id) ON DELETE CASCADE,
    
    -- Personal Info
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    employee_id VARCHAR(100), -- Company's internal employee ID
    department VARCHAR(100),
    
    -- Role & Permissions
    role VARCHAR(50) DEFAULT 'employee', -- 'manager', 'supervisor', 'employee'
    permissions JSONB,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Created By
    created_by_rep_id UUID REFERENCES representatives(id),
    approved_by_rep_id UUID REFERENCES representatives(id),
    
    -- Login Info
    last_login_at TIMESTAMP,
    device_info JSONB, -- Store device details for mobile app
    
    -- Statistics
    total_receipts_uploaded INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_member_role CHECK (role IN ('manager', 'supervisor', 'employee'))
);

-- Receipts Table
-- Stores all receipt data captured via mobile app
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,
    company_id UUID REFERENCES registered_companies(id) ON DELETE CASCADE,
    
    -- Receipt Image
    image_path VARCHAR(500) NOT NULL,
    image_size INTEGER, -- in bytes
    thumbnail_path VARCHAR(500),
    
    -- Receipt Data (Extracted via OCR)
    merchant_name VARCHAR(255),
    merchant_address TEXT,
    merchant_phone VARCHAR(50),
    
    amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    
    receipt_date DATE,
    receipt_number VARCHAR(100),
    
    -- Categorization
    category VARCHAR(100), -- 'food', 'travel', 'office_supplies', 'entertainment', etc.
    subcategory VARCHAR(100),
    payment_method VARCHAR(50), -- 'cash', 'credit_card', 'debit_card', etc.
    
    -- Additional Details
    notes TEXT,
    tags JSONB, -- Array of custom tags
    
    -- OCR Data
    ocr_data JSONB, -- Full OCR response
    ocr_confidence DECIMAL(5,2), -- Confidence score 0-100
    
    -- Processing Status
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processed', 'sent', 'failed', 'archived'
    
    -- Email Forwarding
    email_sent_to VARCHAR(255), -- Which verified email was it sent to
    email_sent_at TIMESTAMP,
    email_status VARCHAR(20), -- 'pending', 'sent', 'failed'
    
    -- Approval Workflow (if enabled)
    requires_approval BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES representatives(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_receipt_status CHECK (status IN ('pending', 'processed', 'sent', 'failed', 'archived'))
);

-- Usage Statistics Table
-- Track monthly usage per company
CREATE TABLE IF NOT EXISTS usage_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES registered_companies(id) ON DELETE CASCADE,
    
    -- Period
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    
    -- Usage Metrics
    receipts_uploaded INTEGER DEFAULT 0,
    receipts_processed INTEGER DEFAULT 0,
    receipts_sent INTEGER DEFAULT 0,
    
    active_members INTEGER DEFAULT 0,
    total_members INTEGER DEFAULT 0,
    
    storage_used_mb DECIMAL(10,2) DEFAULT 0,
    
    -- API Usage (if applicable)
    api_calls INTEGER DEFAULT 0,
    
    -- Calculated at end of month
    calculated_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(company_id, year, month)
);

-- Email Verification Tokens Table
-- For verifying representative emails
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    representative_id UUID REFERENCES representatives(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Companies
CREATE INDEX IF NOT EXISTS idx_companies_status ON registered_companies(subscription_status);
CREATE INDEX IF NOT EXISTS idx_companies_plan ON registered_companies(current_plan_id);
CREATE INDEX IF NOT EXISTS idx_companies_active ON registered_companies(is_active);

-- Transaction History
CREATE INDEX IF NOT EXISTS idx_transactions_company ON transaction_history(company_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transaction_history(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transaction_history(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transaction_history(payment_status);

-- Representatives
CREATE INDEX IF NOT EXISTS idx_representatives_company ON representatives(company_id);
CREATE INDEX IF NOT EXISTS idx_representatives_email ON representatives(email);
CREATE INDEX IF NOT EXISTS idx_representatives_active ON representatives(is_active);
CREATE INDEX IF NOT EXISTS idx_representatives_primary ON representatives(company_id, is_primary);

-- Members
CREATE INDEX IF NOT EXISTS idx_members_company ON members(company_id);
CREATE INDEX IF NOT EXISTS idx_members_email ON members(email);
CREATE INDEX IF NOT EXISTS idx_members_active ON members(is_active);
CREATE INDEX IF NOT EXISTS idx_members_created_by ON members(created_by_rep_id);

-- Receipts
CREATE INDEX IF NOT EXISTS idx_receipts_company ON receipts(company_id);
CREATE INDEX IF NOT EXISTS idx_receipts_member ON receipts(member_id);
CREATE INDEX IF NOT EXISTS idx_receipts_date ON receipts(receipt_date);
CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);
CREATE INDEX IF NOT EXISTS idx_receipts_created ON receipts(created_at);
CREATE INDEX IF NOT EXISTS idx_receipts_category ON receipts(category);

-- Usage Statistics
CREATE INDEX IF NOT EXISTS idx_usage_company_period ON usage_statistics(company_id, year, month);

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON registered_companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_representatives_updated_at BEFORE UPDATE ON representatives
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usage_stats_updated_at BEFORE UPDATE ON usage_statistics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to increment member receipt count
CREATE OR REPLACE FUNCTION increment_member_receipt_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE members 
    SET total_receipts_uploaded = total_receipts_uploaded + 1
    WHERE id = NEW.member_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER increment_receipt_count_trigger AFTER INSERT ON receipts
    FOR EACH ROW EXECUTE FUNCTION increment_member_receipt_count();

-- Function to ensure only one primary representative per company
CREATE OR REPLACE FUNCTION ensure_one_primary_rep()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = true THEN
        -- Set all other representatives of this company to not primary
        UPDATE representatives 
        SET is_primary = false 
        WHERE company_id = NEW.company_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER ensure_one_primary_rep_trigger BEFORE INSERT OR UPDATE ON representatives
    FOR EACH ROW EXECUTE FUNCTION ensure_one_primary_rep();

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert Sample Subscription Plans
INSERT INTO subscription_plans (name, description, price, billing_cycle, max_users, max_receipts_per_month, features)
VALUES 
    ('Starter', 'Perfect for small teams', 29.99, 'monthly', 5, 100, '{"support": "email", "storage": "1GB", "receipt_forwarding": true}'),
    ('Professional', 'Growing businesses', 59.99, 'monthly', 20, 500, '{"support": "priority", "storage": "10GB", "analytics": true, "receipt_forwarding": true, "custom_categories": true}'),
    ('Enterprise', 'Large organizations', 149.99, 'monthly', 100, 2000, '{"support": "phone", "storage": "unlimited", "analytics": true, "api_access": true, "receipt_forwarding": true, "custom_categories": true, "approval_workflow": true}')
ON CONFLICT DO NOTHING;

-- Insert Sample Data with Complete Flow
DO $$
DECLARE
    starter_plan_id UUID;
    pro_plan_id UUID;
    enterprise_plan_id UUID;
    
    demo_company_id UUID;
    marketing_company_id UUID;
    startup_company_id UUID;
    
    admin_rep_id UUID;
    primary_rep_id UUID;
    secondary_rep_id UUID;
    marketing_rep_id UUID;
    startup_rep_id UUID;
    
    member1_id UUID;
    member2_id UUID;
    member3_id UUID;
    member4_id UUID;
    
    receipt1_id UUID;
    receipt2_id UUID;
    receipt3_id UUID;
    receipt4_id UUID;
BEGIN
    -- Get all plan IDs
    SELECT id INTO starter_plan_id FROM subscription_plans WHERE name = 'Starter' LIMIT 1;
    SELECT id INTO pro_plan_id FROM subscription_plans WHERE name = 'Professional' LIMIT 1;
    SELECT id INTO enterprise_plan_id FROM subscription_plans WHERE name = 'Enterprise' LIMIT 1;

    -- ============================================
    -- COMPANY 1: TechCorp Demo (Professional Plan, Active)
    -- ============================================
    INSERT INTO registered_companies (
        name, domain, industry, company_size, 
        current_plan_id, subscription_status, 
        subscription_start_date, subscription_end_date,
        address, phone, website
    )
    VALUES (
        'TechCorp Demo', 
        'techcorp.com', 
        'Technology', 
        'medium',
        pro_plan_id, 
        'active', 
        CURRENT_TIMESTAMP - INTERVAL '2 months',
        CURRENT_TIMESTAMP + INTERVAL '1 month',
        '123 Tech Street, Silicon Valley, CA 94025',
        '+1-555-0100',
        'https://www.techcorp.com'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO demo_company_id;

    IF demo_company_id IS NULL THEN
        SELECT id INTO demo_company_id FROM registered_companies WHERE name = 'TechCorp Demo' LIMIT 1;
    END IF;

    -- ============================================
    -- COMPANY 2: Marketing Inc (Starter Plan, Trial)
    -- ============================================
    INSERT INTO registered_companies (
        name, domain, industry, company_size, 
        current_plan_id, subscription_status, 
        subscription_start_date, subscription_end_date,
        address, phone, website
    )
    VALUES (
        'Marketing Inc', 
        'marketinginc.com', 
        'Marketing & Advertising', 
        'small',
        starter_plan_id, 
        'trial', 
        CURRENT_TIMESTAMP - INTERVAL '5 days',
        CURRENT_TIMESTAMP + INTERVAL '9 days',
        '456 Market Avenue, New York, NY 10001',
        '+1-555-0200',
        'https://www.marketinginc.com'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO marketing_company_id;

    IF marketing_company_id IS NULL THEN
        SELECT id INTO marketing_company_id FROM registered_companies WHERE name = 'Marketing Inc' LIMIT 1;
    END IF;

    -- ============================================
    -- COMPANY 3: Startup LLC (Inactive/Expired)
    -- ============================================
    INSERT INTO registered_companies (
        name, domain, industry, company_size, 
        current_plan_id, subscription_status, 
        subscription_start_date, subscription_end_date,
        address, phone, website
    )
    VALUES (
        'Startup LLC', 
        'startup.io', 
        'Software Development', 
        'small',
        starter_plan_id, 
        'inactive', 
        CURRENT_TIMESTAMP - INTERVAL '3 months',
        CURRENT_TIMESTAMP - INTERVAL '1 week',
        '789 Innovation Drive, Austin, TX 78701',
        '+1-555-0300',
        'https://www.startup.io'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO startup_company_id;

    IF startup_company_id IS NULL THEN
        SELECT id INTO startup_company_id FROM registered_companies WHERE name = 'Startup LLC' LIMIT 1;
    END IF;

    -- ============================================
    -- REPRESENTATIVES
    -- ============================================
    
    -- Master Admin (Platform Administrator - No company)
    -- Password: admin123
    INSERT INTO representatives (
        email, password_hash, first_name, last_name, 
        role, verified_email, email_verified, is_active,
        permissions
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
        '{"full_access": true, "can_manage_all_companies": true, "can_manage_plans": true}'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO admin_rep_id;

    -- TechCorp - Primary Representative
    -- Password: password123
    INSERT INTO representatives (
        company_id, email, password_hash, first_name, last_name, 
        job_title, role, verified_email, email_verified, 
        is_active, is_primary, phone,
        permissions
    )
    VALUES (
        demo_company_id,
        'rep@techcorp.com', 
        '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
        'John', 
        'Doe',
        'Finance Manager', 
        'primary_representative', 
        'receipts@techcorp.com',
        true, 
        true,
        true,
        '+1-555-0101',
        '{"can_add_users": true, "can_remove_users": true, "can_view_billing": true, "can_modify_subscription": true, "can_view_all_receipts": true, "can_approve_receipts": true}'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO primary_rep_id;

    IF primary_rep_id IS NULL THEN
        SELECT id INTO primary_rep_id FROM representatives WHERE email = 'rep@techcorp.com' LIMIT 1;
    END IF;

    -- TechCorp - Secondary Representative
    -- Password: password123
    INSERT INTO representatives (
        company_id, email, password_hash, first_name, last_name, 
        job_title, role, verified_email, email_verified, 
        is_active, is_primary, phone,
        permissions
    )
    VALUES (
        demo_company_id,
        'sarah@techcorp.com', 
        '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
        'Sarah', 
        'Johnson',
        'Operations Manager', 
        'representative', 
        'sarah@techcorp.com',
        true, 
        true,
        false,
        '+1-555-0102',
        '{"can_add_users": true, "can_view_all_receipts": true, "can_approve_receipts": true}'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO secondary_rep_id;

    -- Marketing Inc - Representative
    -- Password: password123
    INSERT INTO representatives (
        company_id, email, password_hash, first_name, last_name, 
        job_title, role, verified_email, email_verified, 
        is_active, is_primary, phone,
        permissions
    )
    VALUES (
        marketing_company_id,
        'rep@marketinginc.com', 
        '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
        'Mike', 
        'Brown',
        'CEO', 
        'primary_representative', 
        'receipts@marketinginc.com',
        true, 
        true,
        true,
        '+1-555-0201',
        '{"can_add_users": true, "can_remove_users": true, "can_view_billing": true, "can_modify_subscription": true}'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO marketing_rep_id;

    -- Startup LLC - Representative
    -- Password: password123
    INSERT INTO representatives (
        company_id, email, password_hash, first_name, last_name, 
        job_title, role, verified_email, email_verified, 
        is_active, is_primary, phone
    )
    VALUES (
        startup_company_id,
        'rep@startup.io', 
        '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
        'Alex', 
        'Chen',
        'Founder', 
        'primary_representative', 
        'receipts@startup.io',
        true, 
        true,
        true,
        '+1-555-0301'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO startup_rep_id;

    -- ============================================
    -- MEMBERS (Employees who use mobile app)
    -- ============================================
    
    -- TechCorp Member 1
    -- Password: member123
    INSERT INTO members (
        company_id, email, password_hash, first_name, last_name,
        employee_id, department, role, is_active, created_by_rep_id,
        phone
    )
    VALUES (
        demo_company_id,
        'employee@techcorp.com',
        '$2b$12$K9V3z8mE9vX4qH5tL2nJ8uK7Y6wR5sT1pN2mQ8zB3xC4vD5eF6gH7',
        'Jane',
        'Smith',
        'EMP001',
        'Sales',
        'employee',
        true,
        primary_rep_id,
        '+1-555-0110'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO member1_id;

    IF member1_id IS NULL THEN
        SELECT id INTO member1_id FROM members WHERE email = 'employee@techcorp.com' LIMIT 1;
    END IF;

    -- TechCorp Member 2
    -- Password: member123
    INSERT INTO members (
        company_id, email, password_hash, first_name, last_name,
        employee_id, department, role, is_active, created_by_rep_id,
        phone
    )
    VALUES (
        demo_company_id,
        'bob@techcorp.com',
        '$2b$12$K9V3z8mE9vX4qH5tL2nJ8uK7Y6wR5sT1pN2mQ8zB3xC4vD5eF6gH7',
        'Bob',
        'Wilson',
        'EMP002',
        'Marketing',
        'manager',
        true,
        primary_rep_id,
        '+1-555-0111'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO member2_id;

    -- TechCorp Member 3
    -- Password: member123
    INSERT INTO members (
        company_id, email, password_hash, first_name, last_name,
        employee_id, department, role, is_active, created_by_rep_id,
        phone
    )
    VALUES (
        demo_company_id,
        'lisa@techcorp.com',
        '$2b$12$K9V3z8mE9vX4qH5tL2nJ8uK7Y6wR5sT1pN2mQ8zB3xC4vD5eF6gH7',
        'Lisa',
        'Garcia',
        'EMP003',
        'Engineering',
        'employee',
        true,
        secondary_rep_id,
        '+1-555-0112'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO member3_id;

    -- Marketing Inc Member
    -- Password: member123
    INSERT INTO members (
        company_id, email, password_hash, first_name, last_name,
        employee_id, department, role, is_active, created_by_rep_id,
        phone
    )
    VALUES (
        marketing_company_id,
        'tom@marketinginc.com',
        '$2b$12$K9V3z8mE9vX4qH5tL2nJ8uK7Y6wR5sT1pN2mQ8zB3xC4vD5eF6gH7',
        'Tom',
        'Davis',
        'MAR001',
        'Creative',
        'employee',
        true,
        marketing_rep_id,
        '+1-555-0210'
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO member4_id;

    -- ============================================
    -- TRANSACTION HISTORY (Complete subscription flow)
    -- ============================================
    
    -- TechCorp - Initial Purchase (2 months ago)
    IF demo_company_id IS NOT NULL THEN
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id, notes
        )
        VALUES (
            demo_company_id,
            'purchase',
            pro_plan_id,
            'Professional',
            59.99,
            'monthly',
            59.99,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '2 months',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            'succeeded',
            'credit_card',
            CURRENT_TIMESTAMP - INTERVAL '2 months',
            'pi_techcorp_initial_001',
            'Initial subscription purchase'
        )
        ON CONFLICT DO NOTHING;

        -- TechCorp - First Renewal (1 month ago)
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id, notes
        )
        VALUES (
            demo_company_id,
            'renewal',
            pro_plan_id,
            'Professional',
            59.99,
            'monthly',
            59.99,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            CURRENT_TIMESTAMP,
            'succeeded',
            'credit_card',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            'pi_techcorp_renewal_002',
            'Monthly renewal'
        )
        ON CONFLICT DO NOTHING;

        -- TechCorp - Current Renewal (active period)
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id, notes
        )
        VALUES (
            demo_company_id,
            'renewal',
            pro_plan_id,
            'Professional',
            59.99,
            'monthly',
            59.99,
            'USD',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '1 month',
            'succeeded',
            'credit_card',
            CURRENT_TIMESTAMP,
            'pi_techcorp_renewal_003',
            'Current active period'
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- Marketing Inc - Trial Start
    IF marketing_company_id IS NOT NULL THEN
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            notes
        )
        VALUES (
            marketing_company_id,
            'purchase',
            starter_plan_id,
            'Starter',
            29.99,
            'monthly',
            0.00,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '5 days',
            CURRENT_TIMESTAMP + INTERVAL '9 days',
            'succeeded',
            'trial',
            CURRENT_TIMESTAMP - INTERVAL '5 days',
            '14-day free trial'
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- Startup LLC - Expired Subscription Flow
    IF startup_company_id IS NOT NULL THEN
        -- Initial Purchase
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id
        )
        VALUES (
            startup_company_id,
            'purchase',
            starter_plan_id,
            'Starter',
            29.99,
            'monthly',
            29.99,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '3 months',
            CURRENT_TIMESTAMP - INTERVAL '2 months',
            'succeeded',
            'credit_card',
            CURRENT_TIMESTAMP - INTERVAL '3 months',
            'pi_startup_initial_001'
        )
        ON CONFLICT DO NOTHING;

        -- First Renewal
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id
        )
        VALUES (
            startup_company_id,
            'renewal',
            starter_plan_id,
            'Starter',
            29.99,
            'monthly',
            29.99,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '2 months',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            'succeeded',
            'credit_card',
            CURRENT_TIMESTAMP - INTERVAL '2 months',
            'pi_startup_renewal_002'
        )
        ON CONFLICT DO NOTHING;

        -- Failed Renewal (payment failed, subscription expired)
        INSERT INTO transaction_history (
            company_id, transaction_type, plan_id, plan_name, 
            plan_price, billing_cycle, amount, currency,
            subscription_start_date, subscription_end_date,
            payment_status, payment_method, transaction_date,
            stripe_payment_intent_id,
            notes
        )
        VALUES (
            startup_company_id,
            'renewal',
            starter_plan_id,
            'Starter',
            29.99,
            'monthly',
            29.99,
            'USD',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            CURRENT_TIMESTAMP - INTERVAL '1 week',
            'failed',
            'credit_card',
            CURRENT_TIMESTAMP - INTERVAL '1 month',
            'pi_startup_renewal_003_failed',
            'Payment failed - card declined'
        )
        ON CONFLICT DO NOTHING;
    END IF;

    -- ============================================
    -- RECEIPTS (Sample receipts uploaded by members)
    -- ============================================
    
    -- TechCorp Receipt 1 (Jane - Office Supplies)
    IF member1_id IS NOT NULL THEN
        INSERT INTO receipts (
            member_id, company_id, image_path, merchant_name, merchant_address,
            amount, tax_amount, receipt_date, category, subcategory,
            payment_method, notes, status, email_sent_to, email_sent_at,
            email_status, ocr_confidence
        )
        VALUES (
            member1_id,
            demo_company_id,
            '/receipts/2025/01/techcorp_receipt_001.jpg',
            'Office Depot',
            '123 Main St, San Jose, CA',
            45.99,
            3.68,
            CURRENT_TIMESTAMP - INTERVAL '5 days',
            'office_supplies',
            'stationery',
            'credit_card',
            'Purchased pens and notebooks for team',
            'sent',
            'receipts@techcorp.com',
            CURRENT_TIMESTAMP - INTERVAL '5 days' + INTERVAL '5 minutes',
            'sent',
            95.5
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO receipt1_id;

        -- Update member receipt count (trigger should do this, but ensure it's set)
        UPDATE members SET total_receipts_uploaded = 1 WHERE id = member1_id;
    END IF;

    -- TechCorp Receipt 2 (Bob - Business Lunch)
    IF member2_id IS NOT NULL THEN
        INSERT INTO receipts (
            member_id, company_id, image_path, merchant_name, merchant_address,
            amount, tax_amount, tip_amount, receipt_date, category, subcategory,
            payment_method, notes, status, email_sent_to, email_sent_at,
            email_status, ocr_confidence
        )
        VALUES (
            member2_id,
            demo_company_id,
            '/receipts/2025/01/techcorp_receipt_002.jpg',
            'The Italian Restaurant',
            '456 Food Ave, Palo Alto, CA',
            125.50,
            10.04,
            22.00,
            CURRENT_TIMESTAMP - INTERVAL '3 days',
            'food',
            'client_entertainment',
            'corporate_card',
            'Client lunch meeting',
            'sent',
            'receipts@techcorp.com',
            CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '10 minutes',
            'sent',
            92.3
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO receipt2_id;

        UPDATE members SET total_receipts_uploaded = 1 WHERE id = member2_id;
    END IF;

    -- TechCorp Receipt 3 (Lisa - Uber to Client)
    IF member3_id IS NOT NULL THEN
        INSERT INTO receipts (
            member_id, company_id, image_path, merchant_name,
            amount, receipt_date, category, subcategory,
            payment_method, notes, status, email_sent_to, email_sent_at,
            email_status, ocr_confidence
        )
        VALUES (
            member3_id,
            demo_company_id,
            '/receipts/2025/01/techcorp_receipt_003.jpg',
            'Uber',
            32.75,
            CURRENT_TIMESTAMP - INTERVAL '1 day',
            'travel',
            'transportation',
            'personal_card',
            'Uber to client office for meeting',
            'sent',
            'receipts@techcorp.com',
            CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '2 minutes',
            'sent',
            98.7
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO receipt3_id;

        UPDATE members SET total_receipts_uploaded = 1 WHERE id = member3_id;
    END IF;

    -- Marketing Inc Receipt (Tom - Printing Services)
    IF member4_id IS NOT NULL THEN
        INSERT INTO receipts (
            member_id, company_id, image_path, merchant_name, merchant_address,
            amount, tax_amount, receipt_date, category, subcategory,
            payment_method, notes, status, email_sent_to, email_sent_at,
            email_status, ocr_confidence
        )
        VALUES (
            member4_id,
            marketing_company_id,
            '/receipts/2025/01/marketing_receipt_001.jpg',
            'FedEx Print & Ship',
            '789 Print St, New York, NY',
            156.00,
            12.48,
            CURRENT_TIMESTAMP - INTERVAL '2 days',
            'office_supplies',
            'printing',
            'credit_card',
            'Marketing brochures for campaign',
            'sent',
            'receipts@marketinginc.com',
            CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '3 minutes',
            'sent',
            94.2
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO receipt4_id;

        UPDATE members SET total_receipts_uploaded = 1 WHERE id = member4_id;
    END IF;

    -- ============================================
    -- USAGE STATISTICS (Monthly tracking)
    -- ============================================
    
    -- TechCorp - Current Month
    IF demo_company_id IS NOT NULL THEN
        INSERT INTO usage_statistics (
            company_id, year, month,
            receipts_uploaded, receipts_processed, receipts_sent,
            active_members, total_members,
            storage_used_mb, api_calls
        )
        VALUES (
            demo_company_id,
            EXTRACT(YEAR FROM CURRENT_TIMESTAMP)::INTEGER,
            EXTRACT(MONTH FROM CURRENT_TIMESTAMP)::INTEGER,
            3, 3, 3,
            3, 3,
            1.2, 45
        )
        ON CONFLICT (company_id, year, month) 
        DO UPDATE SET
            receipts_uploaded = 3,
            receipts_processed = 3,
            receipts_sent = 3,
            active_members = 3,
            total_members = 3,
            storage_used_mb = 1.2;

        -- TechCorp - Previous Month
        INSERT INTO usage_statistics (
            company_id, year, month,
            receipts_uploaded, receipts_processed, receipts_sent,
            active_members, total_members,
            storage_used_mb, api_calls,
            calculated_at
        )
        VALUES (
            demo_company_id,
            EXTRACT(YEAR FROM (CURRENT_TIMESTAMP - INTERVAL '1 month'))::INTEGER,
            EXTRACT(MONTH FROM (CURRENT_TIMESTAMP - INTERVAL '1 month'))::INTEGER,
            28, 28, 28,
            3, 3,
            8.5, 112,
            CURRENT_TIMESTAMP - INTERVAL '1 month'
        )
        ON CONFLICT (company_id, year, month) DO NOTHING;
    END IF;

    -- Marketing Inc - Current Month (Trial)
    IF marketing_company_id IS NOT NULL THEN
        INSERT INTO usage_statistics (
            company_id, year, month,
            receipts_uploaded, receipts_processed, receipts_sent,
            active_members, total_members,
            storage_used_mb, api_calls
        )
        VALUES (
            marketing_company_id,
            EXTRACT(YEAR FROM CURRENT_TIMESTAMP)::INTEGER,
            EXTRACT(MONTH FROM CURRENT_TIMESTAMP)::INTEGER,
            1, 1, 1,
            1, 1,
            0.3, 8
        )
        ON CONFLICT (company_id, year, month)
        DO UPDATE SET
            receipts_uploaded = 1,
            receipts_processed = 1,
            receipts_sent = 1;
    END IF;

END $$;

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE registered_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE representatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_statistics ENABLE ROW LEVEL SECURITY;

-- Subscription Plans: Public read access (for pricing page)
CREATE POLICY "Anyone can view active subscription plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- Representatives can view their own data
CREATE POLICY "Representatives can view their own data" ON representatives
    FOR SELECT USING (auth.uid()::text = id::text);

-- Master admins can view everything
CREATE POLICY "Master admins have full access" ON representatives
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM representatives 
            WHERE id::text = auth.uid()::text AND role = 'master_admin'
        )
    );

-- Companies: Representatives can view their own company
CREATE POLICY "Representatives can view their company" ON registered_companies
    FOR SELECT USING (
        id IN (
            SELECT company_id FROM representatives WHERE id::text = auth.uid()::text
        )
    );

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON subscription_plans TO anon;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify tables were created
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN (
        'subscription_plans', 'registered_companies', 'transaction_history',
        'representatives', 'members', 'receipts', 'usage_statistics'
    )
ORDER BY table_name;

-- Verify demo data
SELECT 'Subscription Plans' as table_name, COUNT(*) as record_count FROM subscription_plans
UNION ALL
SELECT 'Registered Companies', COUNT(*) FROM registered_companies
UNION ALL
SELECT 'Representatives', COUNT(*) FROM representatives
UNION ALL
SELECT 'Members', COUNT(*) FROM members
UNION ALL
SELECT 'Transaction History', COUNT(*) FROM transaction_history
UNION ALL
SELECT 'Receipts', COUNT(*) FROM receipts;

-- Show comprehensive demo data summary
SELECT '========================================' as info;
SELECT 'DEMO DATA SUMMARY' as info;
SELECT '========================================' as info;

-- Companies Summary
SELECT 
    c.name as company,
    sp.name as plan,
    c.subscription_status as status,
    TO_CHAR(c.subscription_start_date, 'YYYY-MM-DD') as start_date,
    TO_CHAR(c.subscription_end_date, 'YYYY-MM-DD') as end_date,
    c.industry,
    c.company_size
FROM registered_companies c
LEFT JOIN subscription_plans sp ON c.current_plan_id = sp.id
ORDER BY c.created_at;

-- Representatives Summary
SELECT 
    r.first_name || ' ' || r.last_name as representative,
    r.email,
    r.role,
    r.verified_email as receipts_forwarded_to,
    c.name as company
FROM representatives r
LEFT JOIN registered_companies c ON r.company_id = c.id
ORDER BY c.name, r.is_primary DESC;

-- Members Summary
SELECT 
    m.first_name || ' ' || m.last_name as member,
    m.email,
    m.employee_id,
    m.department,
    m.role,
    m.total_receipts_uploaded as receipts,
    c.name as company
FROM members m
LEFT JOIN registered_companies c ON m.company_id = c.id
ORDER BY c.name, m.created_at;

-- Transaction History Summary
SELECT 
    c.name as company,
    th.transaction_type,
    th.plan_name,
    th.amount,
    th.payment_status,
    TO_CHAR(th.transaction_date, 'YYYY-MM-DD HH24:MI') as transaction_date,
    TO_CHAR(th.subscription_start_date, 'YYYY-MM-DD') as period_start,
    TO_CHAR(th.subscription_end_date, 'YYYY-MM-DD') as period_end
FROM transaction_history th
LEFT JOIN registered_companies c ON th.company_id = c.id
ORDER BY c.name, th.transaction_date;

-- Receipts Summary
SELECT 
    c.name as company,
    m.first_name || ' ' || m.last_name as uploaded_by,
    r.merchant_name,
    r.amount,
    r.category,
    r.status,
    r.email_sent_to,
    TO_CHAR(r.receipt_date, 'YYYY-MM-DD') as receipt_date
FROM receipts r
LEFT JOIN members m ON r.member_id = m.id
LEFT JOIN registered_companies c ON r.company_id = c.id
ORDER BY c.name, r.created_at;

-- Usage Statistics Summary
SELECT 
    c.name as company,
    us.year,
    us.month,
    us.receipts_uploaded,
    us.receipts_processed,
    us.receipts_sent,
    us.active_members,
    us.total_members,
    us.storage_used_mb
FROM usage_statistics us
LEFT JOIN registered_companies c ON us.company_id = c.id
ORDER BY c.name, us.year DESC, us.month DESC;

-- Demo Credentials Summary
SELECT '========================================' as info;
SELECT 'DEMO CREDENTIALS' as info;
SELECT '========================================' as info;

SELECT 
    'Master Admin' as user_type,
    'admin@receiptcapture.com' as email,
    'admin123' as password,
    'Full platform access' as access_level
UNION ALL
SELECT 
    'TechCorp - Primary Rep',
    'rep@techcorp.com',
    'password123',
    'Company admin, receives all receipts at receipts@techcorp.com'
UNION ALL
SELECT 
    'TechCorp - Secondary Rep',
    'sarah@techcorp.com',
    'password123',
    'Limited company access'
UNION ALL
SELECT 
    'TechCorp - Member',
    'employee@techcorp.com',
    'member123',
    'Mobile app user (Sales dept)'
UNION ALL
SELECT 
    'TechCorp - Member',
    'bob@techcorp.com',
    'member123',
    'Mobile app user (Marketing dept, Manager)'
UNION ALL
SELECT 
    'TechCorp - Member',
    'lisa@techcorp.com',
    'member123',
    'Mobile app user (Engineering dept)'
UNION ALL
SELECT 
    'Marketing Inc - Rep',
    'rep@marketinginc.com',
    'password123',
    'Company admin (Trial period)'
UNION ALL
SELECT 
    'Marketing Inc - Member',
    'tom@marketinginc.com',
    'member123',
    'Mobile app user'
UNION ALL
SELECT 
    'Startup LLC - Rep',
    'rep@startup.io',
    'password123',
    'Company admin (Expired subscription)';

-- Company Details
SELECT '========================================' as info;
SELECT 'COMPANY DETAILS' as info;
SELECT '========================================' as info;

SELECT 
    '1. TechCorp Demo' as info,
    '   Status: ACTIVE (Professional Plan)' as detail1,
    '   Representatives: 2 (John Doe - primary, Sarah Johnson - secondary)' as detail2,
    '   Members: 3 (Jane, Bob, Lisa)' as detail3,
    '   Receipts: 3 uploaded, all forwarded to receipts@techcorp.com' as detail4,
    '   Transactions: 3 (initial purchase + 2 renewals)' as detail5
UNION ALL
SELECT 
    '2. Marketing Inc',
    '   Status: TRIAL (Starter Plan - 14 days)',
    '   Representatives: 1 (Mike Brown - primary)',
    '   Members: 1 (Tom)',
    '   Receipts: 1 uploaded, forwarded to receipts@marketinginc.com',
    '   Transactions: 1 (trial start)'
UNION ALL
SELECT 
    '3. Startup LLC',
    '   Status: INACTIVE (Expired)',
    '   Representatives: 1 (Alex Chen - primary)',
    '   Members: 0',
    '   Receipts: 0',
    '   Transactions: 3 (initial + renewal + failed renewal)';

SELECT '========================================' as info;
SELECT 'DATABASE SETUP COMPLETE!' as info;
SELECT '========================================' as info;
