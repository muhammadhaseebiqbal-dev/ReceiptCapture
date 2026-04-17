# 📊 Database Schema Documentation - Updated Design

## Overview
This document describes the updated database schema for the Receipt Capture application with separate tables for transaction history, registered companies, representatives, and members.

---

## 🗂️ Table Structure

### 1. **subscription_plans**
Defines available subscription tiers and their features.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(100) | Plan name (e.g., "Starter", "Professional") |
| description | TEXT | Plan description |
| price | DECIMAL(10,2) | Monthly/Annual price |
| billing_cycle | VARCHAR(20) | "monthly" or "annual" |
| max_users | INTEGER | Maximum users allowed |
| max_receipts_per_month | INTEGER | Receipt upload limit (NULL = unlimited) |
| features | JSONB | JSON object with plan features |
| is_active | BOOLEAN | Whether plan is available for purchase |
| created_at | TIMESTAMP | When plan was created |
| updated_at | TIMESTAMP | Last modification time |

**Sample Data:**
```json
{
  "name": "Professional",
  "price": 59.99,
  "billing_cycle": "monthly",
  "max_users": 20,
  "max_receipts_per_month": 500,
  "features": {
    "support": "priority",
    "storage": "10GB",
    "analytics": true,
    "receipt_forwarding": true,
    "custom_categories": true
  }
}
```

---

### 2. **registered_companies**
Stores all companies that register on the platform.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(255) | Company name |
| domain | VARCHAR(255) | Company domain (e.g., "techcorp.com") |
| industry | VARCHAR(100) | Industry type |
| company_size | VARCHAR(50) | "small", "medium", "large", "enterprise" |
| address | TEXT | Physical address |
| phone | VARCHAR(50) | Contact phone |
| website | VARCHAR(255) | Company website |
| **current_plan_id** | UUID | FK to subscription_plans |
| **subscription_status** | VARCHAR(20) | "active", "inactive", "trial", "suspended", "cancelled" |
| **subscription_start_date** | TIMESTAMP | When current subscription started |
| **subscription_end_date** | TIMESTAMP | When current subscription expires |
| stripe_customer_id | VARCHAR(255) | Stripe customer reference |
| is_active | BOOLEAN | Company account status |
| created_at | TIMESTAMP | Registration date |
| updated_at | TIMESTAMP | Last modification |

**Key Points:**
- Stores current subscription status
- Links to subscription_plans for current plan
- Tracks subscription period dates
- Separate from transaction history

---

### 3. **transaction_history** ⭐ NEW
Stores complete history of all subscription transactions.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| company_id | UUID | FK to registered_companies |
| **transaction_type** | VARCHAR(50) | "purchase", "renewal", "upgrade", "downgrade", "cancellation", "refund" |
| **plan_id** | UUID | FK to subscription_plans |
| **plan_name** | VARCHAR(100) | Plan name at time of purchase |
| **plan_price** | DECIMAL(10,2) | Plan price at time of purchase |
| **billing_cycle** | VARCHAR(20) | "monthly" or "annual" |
| **amount** | DECIMAL(10,2) | Transaction amount |
| currency | VARCHAR(3) | "USD", "EUR", etc. |
| **subscription_start_date** | TIMESTAMP | Start of subscription period |
| **subscription_end_date** | TIMESTAMP | End of subscription period |
| **payment_status** | VARCHAR(20) | "pending", "succeeded", "failed", "refunded" |
| payment_method | VARCHAR(50) | "credit_card", "debit_card", "bank_transfer", "paypal" |
| stripe_payment_intent_id | VARCHAR(255) | Stripe payment reference |
| stripe_invoice_id | VARCHAR(255) | Stripe invoice reference |
| notes | TEXT | Additional notes |
| metadata | JSONB | Extra transaction data |
| **transaction_date** | TIMESTAMP | When transaction occurred |
| created_at | TIMESTAMP | Record creation time |

**Purpose:**
- Complete audit trail of all subscriptions
- Track upgrades, downgrades, renewals
- Store plan details at time of purchase (historical data)
- Payment reconciliation
- Revenue reporting

**Example Transactions:**
```sql
-- Initial Purchase
INSERT INTO transaction_history (
  company_id, transaction_type, plan_name, plan_price,
  amount, subscription_start_date, subscription_end_date,
  payment_status
) VALUES (
  'company-uuid', 'purchase', 'Professional', 59.99,
  59.99, '2025-01-01', '2025-02-01', 'succeeded'
);

-- Upgrade
INSERT INTO transaction_history (
  company_id, transaction_type, plan_name, plan_price,
  amount, subscription_start_date, subscription_end_date,
  payment_status
) VALUES (
  'company-uuid', 'upgrade', 'Enterprise', 149.99,
  149.99, '2025-02-01', '2025-03-01', 'succeeded'
);
```

---

### 4. **representatives** ⭐ UPDATED
Portal users who manage company accounts (formerly portal_users).

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| company_id | UUID | FK to registered_companies (NULL for master_admin) |
| email | VARCHAR(255) | Login email (unique) |
| password_hash | VARCHAR(255) | Bcrypt hashed password |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| phone | VARCHAR(50) | Contact phone |
| job_title | VARCHAR(100) | Position in company |
| **verified_email** | VARCHAR(255) | ⭐ Email where ALL receipts are forwarded |
| **email_verified** | BOOLEAN | Whether verified_email is confirmed |
| verified_at | TIMESTAMP | When email was verified |
| **role** | VARCHAR(50) | "master_admin", "primary_representative", "representative" |
| permissions | JSONB | Custom permissions object |
| is_active | BOOLEAN | Account status |
| **is_primary** | BOOLEAN | One primary rep per company |
| last_login_at | TIMESTAMP | Last login time |
| login_count | INTEGER | Total login count |
| two_factor_enabled | BOOLEAN | 2FA status |
| two_factor_secret | VARCHAR(255) | 2FA secret key |
| created_at | TIMESTAMP | Account creation |
| updated_at | TIMESTAMP | Last modification |

**Key Features:**
- `verified_email`: The email address where ALL receipts for this company are sent
- `is_primary`: Only one primary representative per company (enforced by trigger)
- `role`: Determines access level
  - `master_admin`: Platform administrator (no company_id)
  - `primary_representative`: Main company contact (can manage billing)
  - `representative`: Secondary company contact

**Permissions Example:**
```json
{
  "can_add_users": true,
  "can_remove_users": true,
  "can_view_billing": true,
  "can_modify_subscription": false,
  "can_view_all_receipts": true,
  "can_approve_receipts": true
}
```

---

### 5. **members** ⭐ UPDATED
Company employees who use the mobile app (formerly app_users).

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| **company_id** | UUID | ⭐ FK to registered_companies (identifies which company) |
| email | VARCHAR(255) | Login email (unique) |
| password_hash | VARCHAR(255) | Bcrypt hashed password |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| phone | VARCHAR(50) | Contact phone |
| employee_id | VARCHAR(100) | Company's internal employee ID |
| department | VARCHAR(100) | Department/Team |
| role | VARCHAR(50) | "manager", "supervisor", "employee" |
| permissions | JSONB | Custom permissions |
| is_active | BOOLEAN | Account status |
| **created_by_rep_id** | UUID | FK to representatives (who created this member) |
| approved_by_rep_id | UUID | FK to representatives (who approved) |
| last_login_at | TIMESTAMP | Last login time |
| device_info | JSONB | Mobile device details |
| **total_receipts_uploaded** | INTEGER | Total receipts count (auto-incremented) |
| created_at | TIMESTAMP | Account creation |
| updated_at | TIMESTAMP | Last modification |

**Purpose:**
- Each member belongs to ONE company (via `company_id`)
- Members scan and upload receipts via mobile app
- Representatives manage members
- Members cannot access web portal
- All receipts from members go to company's `verified_email`

**Example:**
```sql
-- Member John Smith belongs to TechCorp
INSERT INTO members (
  company_id, email, first_name, last_name,
  employee_id, department, role, created_by_rep_id
) VALUES (
  'techcorp-uuid', 'john@techcorp.com', 'John', 'Smith',
  'EMP001', 'Sales', 'employee', 'rep-uuid'
);
```

---

### 6. **receipts**
Stores all receipt data captured via mobile app.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| **member_id** | UUID | FK to members (who uploaded) |
| **company_id** | UUID | FK to registered_companies (which company) |
| image_path | VARCHAR(500) | S3/storage path to image |
| image_size | INTEGER | File size in bytes |
| thumbnail_path | VARCHAR(500) | Thumbnail image path |
| merchant_name | VARCHAR(255) | Vendor name (OCR) |
| merchant_address | TEXT | Vendor address (OCR) |
| merchant_phone | VARCHAR(50) | Vendor phone (OCR) |
| amount | DECIMAL(10,2) | Total amount |
| tax_amount | DECIMAL(10,2) | Tax amount |
| tip_amount | DECIMAL(10,2) | Tip amount |
| receipt_date | DATE | Transaction date |
| receipt_number | VARCHAR(100) | Receipt/invoice number |
| category | VARCHAR(100) | "food", "travel", "office_supplies", etc. |
| subcategory | VARCHAR(100) | More specific category |
| payment_method | VARCHAR(50) | How it was paid |
| notes | TEXT | Member notes |
| tags | JSONB | Custom tags array |
| ocr_data | JSONB | Full OCR response |
| ocr_confidence | DECIMAL(5,2) | OCR confidence 0-100 |
| status | VARCHAR(20) | "pending", "processed", "sent", "failed", "archived" |
| **email_sent_to** | VARCHAR(255) | ⭐ Which verified_email was it sent to |
| **email_sent_at** | TIMESTAMP | When email was sent |
| email_status | VARCHAR(20) | "pending", "sent", "failed" |
| requires_approval | BOOLEAN | If approval workflow enabled |
| approved_by | UUID | FK to representatives |
| approved_at | TIMESTAMP | When approved |
| rejection_reason | TEXT | Why rejected |
| created_at | TIMESTAMP | Upload time |
| updated_at | TIMESTAMP | Last modification |

**Receipt Processing Flow:**
1. Member uploads receipt via mobile app
2. OCR extracts data → stored in `ocr_data`
3. Status: `pending`
4. If approval required → waits for representative approval
5. Once approved/auto-processed → Status: `processed`
6. Email sent to `company.representative.verified_email`
7. Status: `sent`, `email_sent_at` timestamp recorded

---

### 7. **usage_statistics**
Monthly usage tracking per company.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| company_id | UUID | FK to registered_companies |
| year | INTEGER | Year (e.g., 2025) |
| month | INTEGER | Month (1-12) |
| receipts_uploaded | INTEGER | Total receipts uploaded |
| receipts_processed | INTEGER | Successfully processed |
| receipts_sent | INTEGER | Successfully emailed |
| active_members | INTEGER | Members who logged in |
| total_members | INTEGER | Total members |
| storage_used_mb | DECIMAL(10,2) | Storage consumed |
| api_calls | INTEGER | API usage (if applicable) |
| calculated_at | TIMESTAMP | When stats were calculated |
| created_at | TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | Last update |

**Purpose:**
- Track monthly usage against plan limits
- Identify over-limit companies
- Generate usage reports
- Plan upgrade recommendations

---

### 8. **email_verification_tokens**
Tokens for verifying representative emails.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| representative_id | UUID | FK to representatives |
| email | VARCHAR(255) | Email to verify |
| token | VARCHAR(255) | Verification token (unique) |
| expires_at | TIMESTAMP | Token expiration |
| used_at | TIMESTAMP | When token was used |
| created_at | TIMESTAMP | Token generation time |

---

## 🔗 Relationships

```
subscription_plans
    ↓ (many companies use one plan)
registered_companies
    ↓ (one company has many representatives)
representatives ──→ verified_email (where receipts go)
    ↓ (representatives create members)
members
    ↓ (members upload receipts)
receipts ──→ email_sent_to (copy of verified_email)

registered_companies
    ↓ (one company has many transactions)
transaction_history (complete purchase history)
```

---

## 🎯 Key Business Logic

### Receipt Flow
1. **Member** scans receipt via mobile app
2. Receipt is linked to:
   - `member_id` (who scanned it)
   - `company_id` (which company the member belongs to)
3. Receipt is processed (OCR, categorization)
4. Receipt is emailed to the company's **representative's verified_email**
5. All receipts for Company X → go to → Representative's verified_email

### Subscription Management
1. Company registers → creates entry in `registered_companies`
2. Company purchases plan → creates entry in `transaction_history`
3. `registered_companies.current_plan_id` updated
4. `registered_companies.subscription_start_date` and `end_date` updated
5. When company upgrades/downgrades → new entry in `transaction_history`
6. Full history preserved in `transaction_history` table

### Company Hierarchy
```
Company (TechCorp)
  ├── Primary Representative (John Doe)
  │     └── verified_email: receipts@techcorp.com ← ALL receipts go here
  ├── Representative (Jane Smith)
  │     └── verified_email: jane@techcorp.com
  └── Members (Employees)
        ├── Employee 1 (mobile app user)
        ├── Employee 2 (mobile app user)
        └── Employee 3 (mobile app user)
```

---

## 🔒 Security Features

### Row Level Security (RLS)
- **Subscription Plans**: Public read for active plans
- **Companies**: Representatives see only their company
- **Representatives**: Can view own data only
- **Members**: Company reps can manage their company's members
- **Receipts**: Representatives see receipts from their company only
- **Transaction History**: Representatives see their company's transactions
- **Master Admins**: Full access to everything

### Triggers
1. **Auto-update `updated_at`**: All tables with `updated_at` column
2. **Increment receipt count**: When member uploads receipt → `members.total_receipts_uploaded++`
3. **Ensure one primary**: Only one `is_primary=true` representative per company

---

## 📊 Sample Queries

### Get Company with Current Subscription
```sql
SELECT 
  c.name as company_name,
  sp.name as plan_name,
  sp.price,
  c.subscription_status,
  c.subscription_end_date,
  r.verified_email as receipts_email
FROM registered_companies c
JOIN subscription_plans sp ON c.current_plan_id = sp.id
JOIN representatives r ON r.company_id = c.id AND r.is_primary = true
WHERE c.id = 'company-uuid';
```

### Get Transaction History for Company
```sql
SELECT 
  transaction_type,
  plan_name,
  amount,
  subscription_start_date,
  subscription_end_date,
  payment_status,
  transaction_date
FROM transaction_history
WHERE company_id = 'company-uuid'
ORDER BY transaction_date DESC;
```

### Get All Members for Company
```sql
SELECT 
  m.first_name || ' ' || m.last_name as name,
  m.email,
  m.employee_id,
  m.department,
  m.total_receipts_uploaded,
  r.first_name || ' ' || r.last_name as created_by
FROM members m
JOIN representatives r ON m.created_by_rep_id = r.id
WHERE m.company_id = 'company-uuid'
ORDER BY m.created_at DESC;
```

### Get Monthly Receipt Count by Company
```sql
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as receipt_count
FROM receipts
WHERE company_id = 'company-uuid'
  AND created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months')
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;
```

---

## 🚀 Migration Notes

### From Old Schema to New Schema
1. Rename `companies` → `registered_companies`
2. Rename `portal_users` → `representatives`
3. Rename `app_users` → `members`
4. Add `verified_email` column to `representatives`
5. Create new `transaction_history` table
6. Rename `payments` → integrate into `transaction_history`
7. Rename `usage_stats` → `usage_statistics`

---

## 📦 Demo Data Included

- ✅ 3 Subscription Plans (Starter, Professional, Enterprise)
- ✅ 1 Demo Company (TechCorp Demo)
- ✅ 1 Master Admin (admin@receiptcapture.com / admin123)
- ✅ 1 Primary Representative (rep@techcorp.com / password123)
- ✅ 1 Sample Member (employee@techcorp.com / member123)
- ✅ 1 Transaction History Entry (Professional plan purchase)

---

## 🎯 Next Steps

1. Run `database_schema_v2_updated.sql` in Supabase SQL Editor
2. Verify all tables created successfully
3. Update API routes to use new table names
4. Update TypeScript types to match new schema
5. Test with demo data

---

**Schema Version**: 2.0
**Last Updated**: October 19, 2025
**Database**: PostgreSQL (Supabase)
