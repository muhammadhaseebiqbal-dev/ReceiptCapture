# Supabase Integration - Quick Reference

## 🔑 Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=https://hwakflhzugtffywvfqbi.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=your-service-key (TODO: Add this!)
JWT_SECRET=receipt-capture-secret-change-in-production-2025
```

## 📦 Installed Packages

```bash
@supabase/supabase-js   # Supabase client
bcryptjs                # Password hashing
jsonwebtoken            # JWT tokens
@types/bcryptjs         # TypeScript types
@types/jsonwebtoken     # TypeScript types
```

## 🗄️ Database Tables

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `subscription_plans` | Pricing tiers | name, price, max_users, features |
| `companies` | Organizations | name, subscription_status, destination_email |
| `portal_users` | Web users | email, password_hash, role, company_id |
| `app_users` | Mobile users | email, company_id, created_by |
| `receipts` | Receipt data | user_id, company_id, amount, status |
| `payments` | Billing | company_id, amount, status |
| `usage_stats` | Metrics | company_id, month, year, receipts_processed |

## 👤 Demo Users

| Email | Password | Role |
|-------|----------|------|
| admin@receiptcapture.com | admin123 | master_admin |
| rep@techcorp.com | password123 | company_representative |

## 🔧 Key Files

```
website/
├── .env.local                    # Environment variables (DO NOT COMMIT!)
├── .env.example                  # Template for environment variables
├── src/
│   ├── lib/
│   │   ├── supabase.ts          # Client-side Supabase client
│   │   ├── supabase-server.ts   # Server-side Supabase client (admin)
│   │   └── auth.ts              # Auth utilities (bcrypt, JWT)
│   └── app/
│       └── api/
│           └── auth/
│               └── login/
│                   └── route.ts # Login endpoint (uses Supabase)
└── database_setup_supabase.sql  # Database setup script
```

## 🚀 Usage Examples

### Client-Side (Browser)

```typescript
import { supabase } from '@/lib/supabase';

// Query data
const { data, error } = await supabase
  .from('subscription_plans')
  .select('*')
  .eq('is_active', true);

// Insert data
const { data, error } = await supabase
  .from('companies')
  .insert({ name: 'New Company', destination_email: 'email@company.com' });

// Update data
const { data, error } = await supabase
  .from('companies')
  .update({ subscription_status: 'active' })
  .eq('id', companyId);
```

### Server-Side (API Routes)

```typescript
import { supabaseAdmin } from '@/lib/supabase-server';

// Query with admin privileges (bypasses RLS)
const { data, error } = await supabaseAdmin
  .from('portal_users')
  .select('*')
  .eq('email', email)
  .maybeSingle();

// Insert with admin privileges
const { data, error } = await supabaseAdmin
  .from('companies')
  .insert({ 
    name: 'Company Name',
    destination_email: 'email@example.com'
  });
```

### Authentication

```typescript
import { hashPassword, verifyPassword, generateToken } from '@/lib/auth';

// Hash password (registration)
const hashedPassword = await hashPassword('password123');

// Verify password (login)
const isValid = await verifyPassword('password123', hashedPassword);

// Generate JWT token
const token = generateToken(userId, email, role, companyId);

// Verify JWT token
const decoded = verifyToken(token);
```

## 🔐 Row Level Security (RLS)

### Policies Applied:

1. **Subscription Plans**: Anyone can view active plans
2. **Portal Users**: Users can view their own data
3. **Companies**: Users can view their company data
4. **App Users**: Company reps can manage their company users
5. **Receipts**: Users can view their company receipts
6. **Payments**: Company reps can view their company payments
7. **Usage Stats**: Company reps can view their company stats

### Master Admin Exception:
Master admins can view and manage ALL data across all companies.

## 🔄 Auto-Updated Fields

These fields are automatically updated:
- `created_at` (on INSERT)
- `updated_at` (on UPDATE) - for companies, portal_users, app_users, receipts

## 📊 Query Examples

### Get Active Subscription Plans
```typescript
const { data: plans } = await supabase
  .from('subscription_plans')
  .select('*')
  .eq('is_active', true)
  .order('price', { ascending: true });
```

### Get Company with Plan Details
```typescript
const { data: company } = await supabase
  .from('companies')
  .select(`
    *,
    subscription_plans (
      name,
      price,
      billing_cycle,
      features
    )
  `)
  .eq('id', companyId)
  .single();
```

### Get Receipts for Company
```typescript
const { data: receipts } = await supabase
  .from('receipts')
  .select('*')
  .eq('company_id', companyId)
  .order('created_at', { ascending: false })
  .limit(50);
```

### Get User with Company Info
```typescript
const { data: user } = await supabase
  .from('portal_users')
  .select(`
    *,
    companies (
      name,
      destination_email,
      subscription_status
    )
  `)
  .eq('email', userEmail)
  .single();
```

## 🎯 Next Steps

1. ✅ Environment variables configured
2. ✅ Dependencies installed
3. ✅ Supabase client created
4. ✅ Auth utilities set up
5. ✅ Login API updated
6. ⏳ **Run SQL script in Supabase** (IMPORTANT!)
7. ⏳ Add service role key to .env.local
8. ⏳ Test login functionality
9. ⏳ Update other API endpoints
10. ⏳ Test with real data

## ⚡ Quick Commands

```powershell
# Install dependencies (already done)
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run production build
npm start
```

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Missing env variables | Restart dev server after adding .env.local |
| Login fails | Run SQL script to create demo users |
| TypeScript errors | Run `npm install` to get type definitions |
| RLS errors | Check user role and company_id match |
| Connection timeout | Verify Supabase URL and API key |

## 📞 Supabase Dashboard Links

- **Project Dashboard**: https://app.supabase.com/project/hwakflhzugtffywvfqbi
- **Table Editor**: https://app.supabase.com/project/hwakflhzugtffywvfqbi/editor
- **SQL Editor**: https://app.supabase.com/project/hwakflhzugtffywvfqbi/sql
- **API Docs**: https://app.supabase.com/project/hwakflhzugtffywvfqbi/api
- **Logs**: https://app.supabase.com/project/hwakflhzugtffywvfqbi/logs

## 🎓 Learning Resources

- [Supabase Quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [JavaScript Client Docs](https://supabase.com/docs/reference/javascript/introduction)
- [Database Functions](https://supabase.com/docs/guides/database/functions)

---

**Ready to go!** Run the SQL script in Supabase and start testing! 🚀
