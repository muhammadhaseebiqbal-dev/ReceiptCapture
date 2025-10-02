# Receipt Capture - Simplified Web Portal Database Schema

## Core Tables

```sql
-- Subscription Plans
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Companies (Organizations)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Portal Users (Company Representatives)
CREATE TABLE portal_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- App Users (Staff Members - from mobile app)
CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Receipts (Enhanced from mobile app)
CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Subscription Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    stripe_payment_intent_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) NOT NULL, -- 'pending', 'succeeded', 'failed'
    billing_period_start DATE,
    billing_period_end DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage Tracking
CREATE TABLE usage_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    receipts_processed INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, month, year)
);
```

## Indexes for Performance

```sql
-- Performance indexes
CREATE INDEX idx_companies_subscription_status ON companies(subscription_status);
CREATE INDEX idx_app_users_company_id ON app_users(company_id);
CREATE INDEX idx_receipts_company_id ON receipts(company_id);
CREATE INDEX idx_receipts_user_id ON receipts(user_id);
CREATE INDEX idx_receipts_status ON receipts(status);
CREATE INDEX idx_receipts_created_at ON receipts(created_at);
CREATE INDEX idx_payments_company_id ON payments(company_id);
CREATE INDEX idx_usage_stats_company_month ON usage_stats(company_id, year, month);
```

## Sample Data

```sql
-- Master Admin User
INSERT INTO portal_users (email, password_hash, name, role, is_active, email_verified)
VALUES ('admin@receiptcapture.com', '$2b$12$hashed_password', 'Portal Master Admin', 'master_admin', true, true);

-- Sample Subscription Plans
INSERT INTO subscription_plans (name, description, price, billing_cycle, max_users, max_receipts_per_month, features)
VALUES 
('Starter', 'Perfect for small teams', 29.99, 'monthly', 5, 100, '{"support": "email", "storage": "1GB"}'),
('Professional', 'Growing businesses', 59.99, 'monthly', 20, 500, '{"support": "priority", "storage": "10GB", "analytics": true}'),
('Enterprise', 'Large organizations', 149.99, 'monthly', 100, 2000, '{"support": "phone", "storage": "unlimited", "analytics": true, "api_access": true}');
```
