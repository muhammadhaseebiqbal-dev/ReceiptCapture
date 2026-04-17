# Web Portal Schema Migration Guide

## Overview
This document outlines the changes made to the web portal to adapt to the new database schema v2.0.

## Schema Changes Summary

### Table Renames
| Old Table Name | New Table Name | Purpose |
|----------------|----------------|---------|
| `companies` | `registered_companies` | Stores all companies that register on the platform |
| `portal_users` | `representatives` | Portal users who manage company accounts |
| `app_users` | `members` | Mobile app users (employees) who scan receipts |

### New Tables Added
- **`transaction_history`**: Stores complete subscription lifecycle (purchases, renewals, upgrades, downgrades)
- **`email_verification_tokens`**: Handles email verification for representatives

### Key Field Changes

#### registered_companies Table
**New Fields:**
- `domain` - Company domain name
- `industry` - Industry/sector
- `company_size` - small, medium, large, enterprise
- `address` - Physical address
- `phone` - Contact phone
- `website` - Company website
- `current_plan_id` - Renamed from `subscription_plan_id`

**Removed Fields:**
- `destination_email` - This functionality moved to representatives.verified_email

#### representatives Table (formerly portal_users)
**New Fields:**
- `verified_email` - **CRITICAL**: Email where ALL company receipts are forwarded
- `email_verified` - Whether the verified_email has been confirmed
- `verified_at` - When email was verified
- `job_title` - Representative's job title
- `is_primary` - One primary representative per company
- `permissions` - JSONB field for granular permissions
- `two_factor_enabled` - 2FA status
- `two_factor_secret` - 2FA secret key

#### members Table (formerly app_users)
**New Fields:**
- `company_id` - **CRITICAL**: Foreign key linking member to company
- `employee_id` - Company's internal employee ID
- `department` - Employee department
- `device_info` - JSONB for mobile device details
- `total_receipts_uploaded` - Auto-incremented counter
- `created_by_rep_id` - Which representative added this member
- `approved_by_rep_id` - Which representative approved this member

#### receipts Table
**New Fields:**
- `email_sent_to` - Tracks which verified_email received this receipt
- `email_status` - pending, sent, failed
- `requires_approval` - Boolean for approval workflow
- `approved_by` - Representative who approved
- `approved_at` - When approved
- `rejection_reason` - If rejected

## Code Changes Made

### 1. API Routes Updated

#### `/api/companies/route.ts`
**Changes:**
- Table name: `companies` → `registered_companies`
- Foreign key: `subscription_plan_id` → `current_plan_id`
- User counting now splits representatives and members
- Added support for new fields: domain, industry, company_size, address, phone, website
- Removed: destination_email field
- Returns: `representative_count`, `member_count`, `total_user_count`

**Before:**
```typescript
.from('companies')
.select(`*, subscription_plan:subscription_plans(...)`)

// Counting
.from('portal_users').select('*', { count: 'exact' })
```

**After:**
```typescript
.from('registered_companies')
.select(`*, subscription_plan:subscription_plans!current_plan_id(...)`)

// Counting
.from('representatives').select('*', { count: 'exact' })
.from('members').select('*', { count: 'exact' })
```

#### `/api/admin/stats/route.ts`
**Changes:**
- Table names updated
- User counting separates representatives and members
- Returns both individual counts and total

**New Response Fields:**
```typescript
{
  totalCompanies: number;
  activeCompanies: number;
  trialCompanies: number;
  totalUsers: number;
  totalRepresentatives: number;  // NEW
  totalMembers: number;          // NEW
  monthlyRevenue: number;
  activePlans: number;
  totalReceipts: number;
}
```

### 2. UI Components Updated

#### `/admin/companies/page.tsx`
**Interface Changes:**
```typescript
interface Company {
  // Removed
  destination_email: string;
  subscription_plan_id: string;
  user_count: number;
  
  // Added
  domain?: string;
  industry?: string;
  company_size?: string;
  address?: string;
  phone?: string;
  website?: string;
  current_plan_id: string;
  representative_count?: number;
  member_count?: number;
  total_user_count?: number;
}

interface FormData {
  // Removed
  destination_email: string;
  
  // Added
  domain: string;
  industry: string;
  company_size: string;
  address: string;
  phone: string;
  website: string;
}
```

**Form Fields Added:**
1. Domain (text input)
2. Industry (text input)
3. Company Size (select: small, medium, large, enterprise)
4. Phone (text input)
5. Address (text input)
6. Website (text input)

**Display Changes:**
- Company card now shows industry and company_size instead of destination_email
- User count split: Shows "X reps, Y members" breakdown
- Added "Cancelled" status option

#### `/admin/page.tsx`
**Changes:**
- Updated to use new statistics API response
- Can now display representative and member counts separately if needed

## Migration Checklist

### ✅ Completed
1. Updated `/api/companies` route to use `registered_companies` table
2. Updated `/api/admin/stats` route to count representatives and members separately
3. Updated company management UI to support new schema fields
4. Added form inputs for domain, industry, company_size, address, phone, website
5. Updated TypeScript interfaces to match new schema
6. Fixed user counting to aggregate representatives + members

### ⏳ Pending (Next Steps)
1. **Run SQL Script**: Execute `database_schema_v2_updated.sql` in Supabase SQL Editor
2. **Verify Demo Data**: Check that all demo data loaded correctly
3. **Test API Endpoints**: Verify all endpoints work with new schema
4. **Update Authentication**: Update login to work with representatives table
5. **Add Representatives Management**: Create UI for managing company representatives
6. **Add Members Management**: Create UI for managing company members
7. **Add Transaction History View**: Show subscription transaction history
8. **Update Receipts Flow**: Implement email forwarding to verified_email
9. **TypeScript Types**: Regenerate types from Supabase schema
10. **Test Complete Flow**: End-to-end testing of all functionality

## Important Notes

### Email Forwarding System
- **Old System**: Company had one `destination_email`
- **New System**: Each representative has a `verified_email` where receipts are forwarded
- **Primary Representative**: The primary representative's verified_email is the default
- **Benefit**: Multiple representatives can have different forwarding addresses

### User Hierarchy
```
Company (registered_companies)
├── Representatives (representatives) - Portal users, manage company
│   ├── Primary Representative (is_primary = true)
│   └── Secondary Representatives
└── Members (members) - Mobile app users, upload receipts
    ├── Managers
    ├── Supervisors
    └── Employees
```

### Transaction History
- Every subscription action creates a record
- Immutable audit trail
- Stores plan details at time of transaction
- Tracks subscription periods with start/end dates
- Records payment status and methods

## Testing After Migration

### 1. Test Company CRUD
```bash
# Create new company
POST /api/companies
{
  "name": "Test Corp",
  "domain": "testcorp.com",
  "industry": "Technology",
  "company_size": "small",
  "subscription_plan_id": "...",
  "subscription_status": "trial"
}

# Verify fields are saved
# Check representatives_count and members_count are 0
```

### 2. Test Statistics
```bash
# Get admin stats
GET /api/admin/stats

# Verify response includes:
# - totalRepresentatives
# - totalMembers
# - totalUsers (sum of both)
```

### 3. Test Demo Data
Login with demo credentials:
- **Master Admin**: admin@receiptcapture.com / admin123
- **TechCorp Rep**: rep@techcorp.com / password123
- **TechCorp Member**: employee@techcorp.com / member123

Verify:
- TechCorp has 2 representatives, 3 members
- Receipts forwarded to receipts@techcorp.com
- Transaction history shows 3 renewals
- Usage statistics populated

## Database Schema Documentation
See these files for complete schema details:
- `database_schema_v2_updated.sql` - Full SQL script
- `DATABASE_SCHEMA_DOCUMENTATION.md` - Field definitions and relationships
- `DATABASE_SCHEMA_VISUAL_DIAGRAM.md` - ERD and data flow diagrams
- `DEMO_DATA_COMPLETE_FLOW.md` - Demo data explanation

## API Response Examples

### GET /api/companies (New Format)
```json
[
  {
    "id": "uuid",
    "name": "TechCorp Demo",
    "domain": "techcorp.com",
    "industry": "Technology",
    "company_size": "medium",
    "address": "123 Tech Street, Silicon Valley, CA",
    "phone": "+1-555-0100",
    "website": "https://www.techcorp.com",
    "current_plan_id": "uuid",
    "subscription_status": "active",
    "subscription_start_date": "2025-08-01T00:00:00Z",
    "subscription_end_date": "2025-11-01T00:00:00Z",
    "subscription_plan": {
      "name": "Professional",
      "price": 59.99,
      "billing_cycle": "monthly"
    },
    "representative_count": 2,
    "member_count": 3,
    "total_user_count": 5,
    "receipt_count": 3
  }
]
```

### GET /api/admin/stats (New Format)
```json
{
  "totalCompanies": 3,
  "activeCompanies": 1,
  "trialCompanies": 1,
  "totalUsers": 9,
  "totalRepresentatives": 5,
  "totalMembers": 4,
  "monthlyRevenue": 59.99,
  "activePlans": 3,
  "totalReceipts": 4
}
```

## Breaking Changes

### For Frontend Developers
1. **Company Object**: `destination_email` removed, use representative's `verified_email`
2. **User Counting**: Single `user_count` split into `representative_count` and `member_count`
3. **Plan Reference**: `subscription_plan_id` → `current_plan_id`
4. **New Required Fields**: Industry, company_size now available (optional but recommended)

### For API Consumers
1. **Table Names**: Update all queries to use new table names
2. **Joins**: Subscription plans join on `current_plan_id` not `subscription_plan_id`
3. **User Queries**: Separate queries for representatives vs members
4. **Receipt Forwarding**: Query representative's `verified_email` not company's `destination_email`

## Rollback Plan
If issues arise:
1. Keep old schema tables (companies, portal_users, app_users) temporarily
2. Run migration in parallel
3. Switch API routes back to old table names
4. Fix data discrepancies
5. Re-run migration

## Next Development Tasks
1. **Representatives Management UI** - Add/edit/delete representatives per company
2. **Members Management UI** - Add/edit/delete members per company  
3. **Transaction History View** - Display all subscription transactions
4. **Email Verification Flow** - Implement verify email for representatives
5. **Receipt Forwarding Setup** - Configure which representative receives receipts
6. **Permissions Management** - UI for managing representative permissions
7. **Approval Workflow** - Implement receipt approval if enabled
8. **Company Profile** - Enhanced company profile page with all new fields

## Support
For questions or issues with the migration:
1. Check `DATABASE_SCHEMA_DOCUMENTATION.md` for field definitions
2. Review `DEMO_DATA_COMPLETE_FLOW.md` for data examples
3. Test with demo credentials before production use
