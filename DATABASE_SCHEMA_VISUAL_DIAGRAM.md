# 📐 Database Schema Visual Diagram

## 🎨 Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RECEIPT CAPTURE SYSTEM                          │
│                         Database Schema V2.0                            │
└─────────────────────────────────────────────────────────────────────────┘


┌──────────────────────────┐
│  subscription_plans      │
├──────────────────────────┤
│ • id (PK)                │
│   name                   │
│   description            │
│   price                  │
│   billing_cycle          │
│   max_users              │
│   max_receipts_per_month │
│   features (JSONB)       │
│   is_active              │
└────────────┬─────────────┘
             │
             │ (many companies use one plan)
             │
             ↓
┌──────────────────────────┐         ┌──────────────────────────┐
│  registered_companies    │────────→│  transaction_history     │
├──────────────────────────┤         ├──────────────────────────┤
│ • id (PK)                │         │ • id (PK)                │
│   name                   │         │   company_id (FK) ───────┘
│   domain                 │         │   transaction_type       │
│   industry               │         │   plan_id (FK)           │
│   company_size           │         │   plan_name              │
│   address                │         │   plan_price             │
│   phone                  │         │   billing_cycle          │
│   website                │         │   amount                 │
│ → current_plan_id (FK)   │         │   currency               │
│   subscription_status    │         │   subscription_start_date│
│   subscription_start_date│         │   subscription_end_date  │
│   subscription_end_date  │         │   payment_status         │
│   stripe_customer_id     │         │   payment_method         │
│   is_active              │         │   stripe_payment_intent  │
└────────────┬─────────────┘         │   transaction_date       │
             │                       └──────────────────────────┘
             │
             │ (one company has many reps)
             │
             ↓
┌──────────────────────────┐
│  representatives         │
├──────────────────────────┤
│ • id (PK)                │
│   company_id (FK) ───────┘
│   email (UNIQUE)         │
│   password_hash          │
│   first_name             │
│   last_name              │
│   phone                  │
│   job_title              │
│ ⭐ verified_email        │◄────────┐
│   email_verified         │         │
│   verified_at            │         │
│   role                   │         │ (ALL receipts sent here)
│   permissions (JSONB)    │         │
│   is_active              │         │
│   is_primary             │         │
│   last_login_at          │         │
│   two_factor_enabled     │         │
└────────────┬─────────────┘         │
             │                       │
             │ (reps create members) │
             │                       │
             ↓                       │
┌──────────────────────────┐         │
│  members                 │         │
├──────────────────────────┤         │
│ • id (PK)                │         │
│ ⭐ company_id (FK) ───────┘         │
│   email (UNIQUE)         │         │
│   password_hash          │         │
│   first_name             │         │
│   last_name              │         │
│   phone                  │         │
│   employee_id            │         │
│   department             │         │
│   role                   │         │
│   permissions (JSONB)    │         │
│   is_active              │         │
│   created_by_rep_id (FK) │         │
│   approved_by_rep_id     │         │
│   device_info (JSONB)    │         │
│   total_receipts_uploaded│         │
└────────────┬─────────────┘         │
             │                       │
             │ (members upload)      │
             │                       │
             ↓                       │
┌──────────────────────────┐         │
│  receipts                │         │
├──────────────────────────┤         │
│ • id (PK)                │         │
│   member_id (FK) ─────────┘        │
│   company_id (FK)        │         │
│   image_path             │         │
│   thumbnail_path         │         │
│   merchant_name          │         │
│   merchant_address       │         │
│   amount                 │         │
│   tax_amount             │         │
│   receipt_date           │         │
│   category               │         │
│   notes                  │         │
│   ocr_data (JSONB)       │         │
│   status                 │         │
│ ⭐ email_sent_to ─────────────────┘
│   email_sent_at          │
│   email_status           │
│   requires_approval      │
│   approved_by (FK)       │
└──────────────────────────┘


┌──────────────────────────┐         ┌──────────────────────────┐
│  usage_statistics        │         │  email_verification_     │
├──────────────────────────┤         │  tokens                  │
│ • id (PK)                │         ├──────────────────────────┤
│   company_id (FK)        │         │ • id (PK)                │
│   year                   │         │   representative_id (FK) │
│   month                  │         │   email                  │
│   receipts_uploaded      │         │   token (UNIQUE)         │
│   receipts_processed     │         │   expires_at             │
│   receipts_sent          │         │   used_at                │
│   active_members         │         └──────────────────────────┘
│   storage_used_mb        │
│   api_calls              │
└──────────────────────────┘
```

---

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SUBSCRIPTION FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

1. Company Registers
   ↓
   registered_companies (created)
   ↓
2. Company Selects Plan
   ↓
   transaction_history (record: "purchase")
   ↓
   registered_companies.current_plan_id (updated)
   registered_companies.subscription_status = "active"
   ↓
3. Primary Representative Created
   ↓
   representatives (created with is_primary=true)
   representatives.verified_email = "receipts@company.com"
   ↓
4. Representatives Add Members
   ↓
   members (created with company_id)
   ↓
5. Members Upload Receipts
   ↓
   receipts (created with member_id, company_id)
   ↓
6. Receipts Emailed
   ↓
   receipts.email_sent_to = representatives.verified_email
   ↓
   Email sent to: receipts@company.com


┌─────────────────────────────────────────────────────────────────────────┐
│                          UPGRADE FLOW                                   │
└─────────────────────────────────────────────────────────────────────────┘

1. Company Wants to Upgrade
   ↓
2. New Transaction Created
   ↓
   transaction_history (record: "upgrade")
   - Stores NEW plan details
   - Stores NEW price
   - New subscription dates
   ↓
3. Company Record Updated
   ↓
   registered_companies.current_plan_id (updated to new plan)
   registered_companies.subscription_end_date (extended)
   ↓
4. History Preserved
   ↓
   All previous transactions remain in transaction_history
   (purchase, renewals, upgrades visible)
```

---

## 🏢 Company Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          TECHCORP DEMO                                  │
│                     (registered_companies)                              │
│                                                                          │
│  • Name: TechCorp Demo                                                  │
│  • Plan: Professional ($59.99/month)                                    │
│  • Status: Active                                                       │
│  • Max Users: 20                                                        │
│  • Max Receipts: 500/month                                              │
└─────────────────────────────────────────────────────────────────────────┘
             │
             │
     ┌───────┴────────┬──────────────────┐
     │                │                  │
     ↓                ↓                  ↓
┌─────────┐    ┌─────────┐    ┌──────────────────┐
│  Primary│    │Secondary│    │  Master Admin    │
│   Rep   │    │   Rep   │    │  (Platform)      │
└─────────┘    └─────────┘    └──────────────────┘
     │                              │
John Doe                    Portal Admin
rep@techcorp.com            admin@receiptcapture.com
✉️ receipts@techcorp.com    (no company_id)
(verified_email)
     │
     │ Creates Members
     │
     ↓
┌──────────────────────────────┐
│         MEMBERS              │
│      (Employees)             │
├──────────────────────────────┤
│ • Jane Smith                 │
│   employee@techcorp.com      │
│   EMP001 - Sales Dept        │
│   15 receipts uploaded       │
│                              │
│ • Bob Johnson                │
│   bob@techcorp.com           │
│   EMP002 - Marketing         │
│   23 receipts uploaded       │
└──────────────────────────────┘
     │
     │ Upload Receipts
     │
     ↓
┌──────────────────────────────┐
│         RECEIPTS             │
├──────────────────────────────┤
│ Receipt #1                   │
│ - Uploaded by: Jane          │
│ - Merchant: Office Depot     │
│ - Amount: $45.99             │
│ - ✉️ Sent to:                │
│   receipts@techcorp.com      │
│                              │
│ Receipt #2                   │
│ - Uploaded by: Bob           │
│ - Merchant: Starbucks        │
│ - Amount: $12.50             │
│ - ✉️ Sent to:                │
│   receipts@techcorp.com      │
└──────────────────────────────┘
```

---

## 📊 Transaction History Example

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     TECHCORP - TRANSACTION HISTORY                      │
└─────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Transaction #1 - PURCHASE                                              │
├────────────────────────────────────────────────────────────────────────┤
│ Date: 2025-01-01                                                       │
│ Type: Purchase                                                         │
│ Plan: Professional                                                     │
│ Price: $59.99/month                                                    │
│ Amount: $59.99                                                         │
│ Period: 2025-01-01 to 2025-02-01                                      │
│ Status: Succeeded ✅                                                   │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Transaction #2 - RENEWAL                                               │
├────────────────────────────────────────────────────────────────────────┤
│ Date: 2025-02-01                                                       │
│ Type: Renewal                                                          │
│ Plan: Professional                                                     │
│ Price: $59.99/month                                                    │
│ Amount: $59.99                                                         │
│ Period: 2025-02-01 to 2025-03-01                                      │
│ Status: Succeeded ✅                                                   │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Transaction #3 - UPGRADE                                               │
├────────────────────────────────────────────────────────────────────────┤
│ Date: 2025-03-01                                                       │
│ Type: Upgrade                                                          │
│ Plan: Enterprise                                                       │
│ Price: $149.99/month                                                   │
│ Amount: $149.99                                                        │
│ Period: 2025-03-01 to 2025-04-01                                      │
│ Status: Succeeded ✅                                                   │
│ Note: Upgraded from Professional                                      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Relationships Summary

| Parent Table | Child Table | Relationship | Key Field |
|--------------|-------------|--------------|-----------|
| subscription_plans | registered_companies | One-to-Many | current_plan_id |
| subscription_plans | transaction_history | One-to-Many | plan_id |
| registered_companies | transaction_history | One-to-Many | company_id |
| registered_companies | representatives | One-to-Many | company_id |
| registered_companies | members | One-to-Many | company_id |
| registered_companies | receipts | One-to-Many | company_id |
| registered_companies | usage_statistics | One-to-Many | company_id |
| representatives | members | One-to-Many | created_by_rep_id |
| representatives | receipts | One-to-Many | approved_by |
| representatives | email_verification_tokens | One-to-Many | representative_id |
| members | receipts | One-to-Many | member_id |

---

## 🎯 Critical Business Rules

### 1. **One Company → One Primary Representative**
```sql
-- Enforced by trigger: ensure_one_primary_rep()
-- When a representative is set to is_primary=true
-- All other reps for that company are set to is_primary=false
```

### 2. **All Receipts → Verified Email**
```sql
-- When receipt is processed:
receipts.email_sent_to = representatives.verified_email
WHERE representatives.company_id = receipts.company_id
  AND representatives.is_primary = true
```

### 3. **Transaction History is Immutable**
```sql
-- No updates allowed on transaction_history
-- Only INSERT operations
-- Complete audit trail preserved
```

### 4. **Member Count Auto-Increment**
```sql
-- Trigger: increment_member_receipt_count()
-- When member uploads receipt:
UPDATE members 
SET total_receipts_uploaded = total_receipts_uploaded + 1
WHERE id = NEW.member_id;
```

### 5. **Company Hierarchy**
```
Company
  ├── Representatives (manage portal, billing, settings)
  │     └── One Primary Rep (receives ALL receipts)
  └── Members (use mobile app, upload receipts)
```

---

## 📱 User Access Matrix

| User Type | Table Access | Can Do |
|-----------|--------------|--------|
| **Master Admin** | All tables | Everything |
| **Primary Representative** | Own company data | Manage subscription, add/remove users, view all receipts, manage billing |
| **Representative** | Own company data | View receipts, manage members (limited permissions) |
| **Member** | Own receipts only | Upload receipts, view own receipts |
| **Public** | subscription_plans (read only) | View pricing page |

---

## 🔐 Security Implementation

### Row Level Security (RLS) Policies

```sql
-- Representatives can only see their own company
CREATE POLICY "Representatives see own company" ON registered_companies
FOR SELECT USING (
    id IN (
        SELECT company_id FROM representatives 
        WHERE id = auth.uid()
    )
);

-- Members can only see their own receipts
CREATE POLICY "Members see own receipts" ON receipts
FOR SELECT USING (
    member_id = auth.uid()
);

-- Master admin sees everything
CREATE POLICY "Master admin full access" ON registered_companies
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM representatives 
        WHERE id = auth.uid() AND role = 'master_admin'
    )
);
```

---

**Schema Version**: 2.0  
**Diagram Last Updated**: October 19, 2025  
**Total Tables**: 8  
**Total Relationships**: 11
