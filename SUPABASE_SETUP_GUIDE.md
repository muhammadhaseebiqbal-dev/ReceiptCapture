# Supabase Integration Setup Guide

## Overview
This guide will help you set up Supabase PostgreSQL database for the Receipt Capture web portal.

## Prerequisites
- Supabase account (free tier available)
- Node.js and npm installed
- Access to your Supabase project

## 🚀 Quick Setup

### Step 1: Environment Variables (Already Done ✅)

Your `.env.local` file has been created with:
```env
NEXT_PUBLIC_SUPABASE_URL=https://hwakflhzugtffywvfqbi.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
JWT_SECRET=receipt-capture-secret-change-in-production-2025
```

### Step 2: Install Dependencies (Already Done ✅)

The following packages have been installed:
- `@supabase/supabase-js` - Supabase client
- `bcryptjs` - Password hashing
- `jsonwebtoken` - JWT token generation
- `@types/bcryptjs` - TypeScript types
- `@types/jsonwebtoken` - TypeScript types

### Step 3: Set Up Database Tables

1. **Go to your Supabase Dashboard**
   - URL: https://app.supabase.com/project/hwakflhzugtffywvfqbi

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Setup Script**
   - Open the file: `database_setup_supabase.sql`
   - Copy the entire content
   - Paste it into the SQL Editor
   - Click "Run" button

This script will:
- ✅ Create all necessary tables
- ✅ Set up indexes for performance
- ✅ Add demo data (subscription plans, demo users)
- ✅ Configure Row Level Security (RLS)
- ✅ Create triggers for auto-updating timestamps

### Step 4: Get Service Role Key (Important!)

1. Go to your Supabase project settings
2. Navigate to **Settings** → **API**
3. Copy the **service_role** key (keep this secret!)
4. Add it to your `.env.local`:

```env
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

⚠️ **Warning**: Never commit the service role key to version control!

## 📊 Database Structure

### Tables Created:
1. **subscription_plans** - Pricing plans (Starter, Professional, Enterprise)
2. **companies** - Organization accounts
3. **portal_users** - Web portal users (admins and company reps)
4. **app_users** - Mobile app users (employees)
5. **receipts** - Receipt data
6. **payments** - Payment history
7. **usage_stats** - Usage tracking

### Demo Users Created:

**Master Admin:**
- Email: `admin@receiptcapture.com`
- Password: `admin123`
- Role: `master_admin`

**Company Representative:**
- Email: `rep@techcorp.com`
- Password: `password123`
- Role: `company_representative`
- Company: TechCorp Demo

## 🔐 Security Features

### Row Level Security (RLS)
- ✅ Enabled on all tables
- ✅ Users can only access their company data
- ✅ Master admins can access all data
- ✅ Public can view subscription plans

### Password Security
- ✅ Passwords hashed with bcrypt (12 rounds)
- ✅ Never stored in plain text
- ✅ JWT tokens for authentication

### API Security
- ✅ Environment variables for sensitive data
- ✅ Token-based authentication
- ✅ Input validation
- ✅ SQL injection protection (via Supabase)

## 🔧 Files Created/Updated

### New Files:
1. **`.env.local`** - Environment variables (do not commit!)
2. **`.env.example`** - Example environment template
3. **`src/lib/supabase.ts`** - Supabase client configuration
4. **`src/lib/supabase-server.ts`** - Server-side Supabase client
5. **`database_setup_supabase.sql`** - Database setup script

### Updated Files:
1. **`src/lib/auth.ts`** - Updated to use bcrypt and JWT
2. **`src/app/api/auth/login/route.ts`** - Updated to use Supabase

## ✅ Testing the Integration

### 1. Start the Development Server
```powershell
cd d:\WORK\ReceiptCapture\website
npm run dev
```

### 2. Test Login
1. Go to http://localhost:3000
2. Click "Get Started" or "Sign In"
3. Use demo credentials:
   - Email: `admin@receiptcapture.com`
   - Password: `admin123`

### 3. Verify Database Connection
Check the browser console and terminal for any errors. If login is successful, the integration is working!

## 🐛 Troubleshooting

### Issue: "Missing Supabase environment variables"
**Solution**: Make sure `.env.local` exists and restart the dev server

### Issue: Login fails with "Invalid credentials"
**Solutions**:
1. Verify the SQL script ran successfully
2. Check that demo users were created in Supabase
3. Go to Supabase → Table Editor → portal_users to verify

### Issue: TypeScript errors
**Solution**: Run `npm install` again to ensure all types are installed

### Issue: RLS Policy errors
**Solution**: Temporarily disable RLS for testing:
```sql
ALTER TABLE portal_users DISABLE ROW LEVEL SECURITY;
```

### Issue: Connection timeout
**Solution**: 
1. Check your internet connection
2. Verify Supabase project URL is correct
3. Ensure Supabase project is active (not paused)

## 📈 Next Steps

### 1. Complete Registration Flow
Update `src/app/api/auth/register/route.ts` to use Supabase

### 2. Add More API Endpoints
- GET /api/companies
- GET /api/receipts
- POST /api/receipts
- GET /api/users
- POST /api/users

### 3. Set Up Storage
Configure Supabase Storage for receipt images:
```typescript
import { supabase } from '@/lib/supabase';

// Upload receipt image
const { data, error } = await supabase.storage
  .from('receipts')
  .upload(`${userId}/${filename}`, file);
```

### 4. Add Real-time Features
Use Supabase real-time subscriptions:
```typescript
supabase
  .channel('receipts')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'receipts' },
    (payload) => console.log('New receipt:', payload)
  )
  .subscribe();
```

### 5. Set Up Email Notifications
Configure Supabase Auth for email verification and password reset

## 🔒 Production Checklist

Before deploying to production:

- [ ] Change JWT_SECRET to a strong random string
- [ ] Add SUPABASE_SERVICE_ROLE_KEY to environment
- [ ] Enable and test all RLS policies
- [ ] Set up SSL/TLS for database connections
- [ ] Configure Supabase authentication settings
- [ ] Set up backup strategy
- [ ] Enable Supabase monitoring and alerts
- [ ] Update CORS settings if needed
- [ ] Test all API endpoints thoroughly
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Configure rate limiting
- [ ] Review and harden security policies

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Next.js with Supabase](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)

## 🆘 Support

If you encounter issues:
1. Check Supabase Dashboard → Logs
2. Review browser console for errors
3. Check terminal output for server errors
4. Verify environment variables are loaded
5. Ensure database tables were created correctly

## 📝 Database Schema Reference

See `database_schema.md` for the complete database schema documentation.

---

**Status**: Supabase integration is set up! 🎉

Next: Run the SQL script in Supabase to create tables and demo data.
