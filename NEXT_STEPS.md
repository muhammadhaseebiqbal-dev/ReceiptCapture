# Next Steps - Schema v2.0 Migration

## Immediate Actions Required

### Step 1: Run SQL Script in Supabase ⚠️ **CRITICAL - DO THIS FIRST**
1. Open your Supabase dashboard: https://app.supabase.com
2. Navigate to your project: `hwakflhzugtffywvfqbi`
3. Go to **SQL Editor**
4. Copy the entire contents of `database_schema_v2_updated.sql`
5. Paste into SQL Editor
6. Click **Run**
7. Wait for completion (should show "Success" with record counts)

**Expected Output:**
```
8 tables created
3 subscription plans inserted
3 companies created (TechCorp, Marketing Inc, Startup LLC)
5 representatives created
4 members created
7 transactions created
4 receipts created
```

### Step 2: Verify Schema Creation
Run these verification queries in Supabase SQL Editor:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'subscription_plans', 
    'registered_companies', 
    'transaction_history',
    'representatives', 
    'members', 
    'receipts', 
    'usage_statistics',
    'email_verification_tokens'
  );

-- Check demo data counts
SELECT 
  'Companies' as table_name, COUNT(*) as records FROM registered_companies
UNION ALL
SELECT 'Representatives', COUNT(*) FROM representatives
UNION ALL
SELECT 'Members', COUNT(*) FROM members
UNION ALL
SELECT 'Transactions', COUNT(*) FROM transaction_history
UNION ALL
SELECT 'Receipts', COUNT(*) FROM receipts;
```

### Step 3: Test Demo Credentials
Try logging in with these accounts:

**Master Admin:**
- Email: `admin@receiptcapture.com`
- Password: `admin123`
- Expected: Full access to admin portal

**Company Representative (TechCorp):**
- Email: `rep@techcorp.com`
- Password: `password123`
- Expected: Company management access

**Mobile App User (TechCorp):**
- Email: `employee@techcorp.com`
- Password: `member123`
- Expected: Mobile app access (if implemented)

### Step 4: Update Login Logic
The login API needs to query the `representatives` table instead of `portal_users`.

**File to Update:** `website/src/app/api/auth/login/route.ts`

Current (likely):
```typescript
const { data: user } = await supabase
  .from('portal_users')
  .select('*')
  .eq('email', email)
  .single();
```

Should be:
```typescript
const { data: user } = await supabase
  .from('representatives')
  .select('*')
  .eq('email', email)
  .single();
```

### Step 5: Test API Endpoints
Use these curl commands (or Postman) to test:

```bash
# Get subscription plans (no auth required)
curl http://localhost:3000/api/subscription-plans

# Login as admin
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@receiptcapture.com","password":"admin123"}'

# Save the token from response, then:

# Get admin stats
curl http://localhost:3000/api/admin/stats \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Get companies
curl http://localhost:3000/api/companies \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 6: Fix TypeScript Type Errors
The code has some TypeScript compile errors due to type mismatches with Supabase's auto-generated types.

**Option A - Quick Fix:** Add type assertions
**Option B - Proper Fix:** Regenerate Supabase types

To regenerate types:
```bash
cd website
npx supabase gen types typescript --project-id hwakflhzugtffywvfqbi > src/types/database.types.ts
```

## Development Tasks (In Order of Priority)

### 🔴 High Priority

#### 1. Fix Login Authentication
- [ ] Update login API to use `representatives` table
- [ ] Test login with demo credentials
- [ ] Verify JWT token generation
- [ ] Test protected routes

#### 2. Test Existing Features
- [ ] Test admin dashboard loads
- [ ] Test companies management page
- [ ] Test subscription plans management
- [ ] Verify statistics display correctly

#### 3. Add Representatives Management
- [ ] Create `/admin/representatives/page.tsx`
- [ ] Create API route `/api/representatives/route.ts`
- [ ] Display reps grouped by company
- [ ] Add/Edit/Delete functionality
- [ ] **Critical**: Manage `verified_email` field (where receipts go)
- [ ] Set primary representative per company

#### 4. Add Members Management
- [ ] Create `/admin/members/page.tsx`
- [ ] Create API route `/api/members/route.ts`
- [ ] Display members grouped by company
- [ ] Add/Edit/Delete functionality
- [ ] Show department and employee ID
- [ ] Track receipt upload counts

### 🟡 Medium Priority

#### 5. Transaction History View
- [ ] Create `/admin/transactions/page.tsx`
- [ ] Create API route `/api/transactions/route.ts`
- [ ] Display all subscription transactions
- [ ] Filter by company, date, type, status
- [ ] Show payment details and subscription periods

#### 6. Enhanced Company Profile
- [ ] Update company details to show new fields
- [ ] Display industry, size, address, phone, website
- [ ] Show list of representatives
- [ ] Show list of members
- [ ] Show transaction history
- [ ] Show usage statistics

#### 7. Email Verification Flow
- [ ] Create email verification endpoint
- [ ] Send verification emails to representatives
- [ ] Verify email confirmation
- [ ] Update `verified_email` and `email_verified` fields
- [ ] Show verification status in UI

### 🟢 Low Priority

#### 8. Receipt Approval Workflow
- [ ] Create approval interface for representatives
- [ ] Show pending receipts requiring approval
- [ ] Approve/Reject functionality
- [ ] Email notifications

#### 9. Permissions Management
- [ ] UI for editing representative permissions
- [ ] Role-based access control
- [ ] Custom permission sets

#### 10. Advanced Features
- [ ] Usage analytics dashboard
- [ ] Subscription upgrade/downgrade flow
- [ ] Stripe payment integration
- [ ] Invoice generation
- [ ] Email receipt forwarding setup

## Common Issues & Solutions

### Issue: "relation 'companies' does not exist"
**Solution:** You're querying the old table name. Update to `registered_companies`.

### Issue: "column 'destination_email' does not exist"
**Solution:** This field was removed. Use the representative's `verified_email` instead.

### Issue: TypeScript errors about 'never' type
**Solution:** Supabase's type generation is out of sync. Either:
1. Add type assertions: `as any`
2. Regenerate types: `npx supabase gen types typescript...`

### Issue: Login fails with correct credentials
**Solution:** Check if:
1. SQL script ran successfully
2. Demo data was inserted
3. Login API queries `representatives` table
4. Password hashing matches (bcrypt with $2b$)

### Issue: Empty company lists
**Solution:** 
1. Verify demo data was inserted: `SELECT COUNT(*) FROM registered_companies;`
2. Check API is querying correct table
3. Verify authentication token is valid

## Files Modified in This Update

### API Routes
- ✅ `website/src/app/api/companies/route.ts` - Updated to use new schema
- ✅ `website/src/app/api/admin/stats/route.ts` - Updated statistics calculation
- ⏳ `website/src/app/api/auth/login/route.ts` - **NEEDS UPDATE** to use representatives table

### UI Components
- ✅ `website/src/app/admin/companies/page.tsx` - Updated company management UI
- ✅ `website/src/app/admin/page.tsx` - Admin dashboard (minimal changes)

### Database
- ✅ `database_schema_v2_updated.sql` - Complete new schema with demo data
- ✅ `DATABASE_SCHEMA_DOCUMENTATION.md` - Full documentation
- ✅ `DATABASE_SCHEMA_VISUAL_DIAGRAM.md` - Visual diagrams
- ✅ `DEMO_DATA_COMPLETE_FLOW.md` - Demo data guide

### Documentation
- ✅ `WEB_PORTAL_SCHEMA_MIGRATION.md` - Migration guide
- ✅ `NEXT_STEPS.md` - This file

## Testing Checklist

### After Running SQL Script
- [ ] All 8 tables created
- [ ] 3 subscription plans exist
- [ ] 3 companies created
- [ ] 5 representatives created
- [ ] 4 members created
- [ ] 7 transactions recorded
- [ ] 4 receipts uploaded

### After Updating Login
- [ ] Can login as master admin
- [ ] Can login as company representative
- [ ] JWT token generated correctly
- [ ] User role retrieved properly

### After UI Updates
- [ ] Admin dashboard shows correct stats
- [ ] Companies list displays properly
- [ ] Can create new company with new fields
- [ ] Can edit existing company
- [ ] User counts show reps + members
- [ ] Receipts count displays

## Quick Commands Reference

```bash
# Start dev server
cd website
npm run dev

# Test API endpoints
curl http://localhost:3000/api/subscription-plans
curl http://localhost:3000/api/admin/stats -H "Authorization: Bearer TOKEN"

# Generate Supabase types
npx supabase gen types typescript --project-id hwakflhzugtffywvfqbi > src/types/database.types.ts

# Check for TypeScript errors
npm run build
```

## Need Help?

1. **Schema Questions**: Check `DATABASE_SCHEMA_DOCUMENTATION.md`
2. **Data Flow**: Review `DATABASE_SCHEMA_VISUAL_DIAGRAM.md`
3. **Demo Data**: See `DEMO_DATA_COMPLETE_FLOW.md`
4. **Migration Details**: Read `WEB_PORTAL_SCHEMA_MIGRATION.md`

## Summary

**Status:** Schema v2.0 designed and code partially updated
**Next Critical Step:** Run `database_schema_v2_updated.sql` in Supabase
**Estimated Time to Full Migration:** 2-4 hours of development work

The new schema is more robust with proper separation of concerns:
- Companies are organizations
- Representatives manage companies via web portal
- Members upload receipts via mobile app
- Transaction history provides complete audit trail
- Receipt forwarding uses representative's verified email
