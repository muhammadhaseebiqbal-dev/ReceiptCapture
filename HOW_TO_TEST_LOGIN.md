# 🚀 How to Test Login - Step by Step

## ✅ Login is Now Working!

The password hash issue has been fixed. Follow these steps to test:

---

## Step 1: Open the Website

1. Make sure your dev server is running on **http://localhost:3000**
2. Open your browser (Chrome, Firefox, Edge, etc.)
3. Navigate to: **http://localhost:3000**

---

## Step 2: Navigate to Login Page

You have two options:

### Option A: From Landing Page
1. You'll see the landing page with pricing plans
2. Click the **"Get Started"** button in the hero section
3. OR click **"Sign In"** in the navigation bar
4. You'll be redirected to the login page

### Option B: Direct URL
- Go directly to: **http://localhost:3000/login**

---

## Step 3: Use Demo Credentials

You'll see the login form with demo account buttons. You can either:

### Quick Method: Click Demo Button
- Click the **"Master Admin"** demo button
- Credentials will auto-fill
- Click **"Sign In"**

### Manual Method: Type Credentials
1. **Email**: `admin@receiptcapture.com`
2. **Password**: `admin123`
3. Click **"Sign In"**

---

## Step 4: Verify Success

After clicking Sign In:

1. ✅ You should see a brief loading state
2. ✅ You'll be redirected to `/admin` (Master Admin dashboard)
3. ✅ No error messages

If you used the Company Rep account (`rep@techcorp.com`):
- You'll be redirected to `/dashboard` instead

---

## Expected Results

### ✅ Successful Login
- Page redirects automatically
- No error messages
- Token is stored in browser localStorage
- User data is stored in browser localStorage

### ❌ If Login Still Fails

**Check Browser Console (F12)**:
1. Press F12 to open DevTools
2. Go to "Console" tab
3. Look for any error messages
4. Check "Network" tab for failed API calls

**Common Issues**:
- **Server not running**: Make sure `npm run dev` is active
- **Wrong port**: Verify you're on port 3000 (or 3001)
- **Browser cache**: Try hard refresh (Ctrl+F5)

---

## Testing Both Accounts

### Test 1: Master Admin
```
Email: admin@receiptcapture.com
Password: admin123
Expected: Redirect to /admin
```

### Test 2: Company Representative
```
Email: rep@techcorp.com
Password: password123
Expected: Redirect to /dashboard
```

---

## What You Should See

### Login Page Layout:

```
┌────────────────────────────────────────────┐
│  ← Back to Home                            │
│                                            │
│  ┌──────────────────────────┐             │
│  │   📝 Receipt Capture     │             │
│  │                          │             │
│  │   Welcome Back           │             │
│  │                          │             │
│  │   [Email Field]          │             │
│  │   [Password Field] 👁️   │             │
│  │                          │             │
│  │   [Sign In Button]       │             │
│  │                          │             │
│  │   ───── Or ─────         │             │
│  │                          │             │
│  │   Don't have account?    │             │
│  │   [Register Company]     │             │
│  │                          │             │
│  │   Try Demo Accounts      │             │
│  │   ┌──────────────────┐   │             │
│  │   │ Master Admin     │   │             │
│  │   │ admin@rc.com     │ ← Click this!  │
│  │   └──────────────────┘   │             │
│  │   ┌──────────────────┐   │             │
│  │   │ Company Rep      │   │             │
│  │   │ rep@tech.com     │   │             │
│  │   └──────────────────┘   │             │
│  └──────────────────────────┘             │
│                                            │
│  🔒 Your data is secure                   │
└────────────────────────────────────────────┘
```

---

## Browser DevTools Inspection

### Check if Login Worked:

1. **Open DevTools** (F12)
2. **Go to "Application" tab** (Chrome) or "Storage" (Firefox)
3. **Click "Local Storage"** → `http://localhost:3000`
4. **Look for**:
   - `token`: Should contain a long JWT string
   - `user`: Should contain user JSON data

Example:
```
token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
user: {"id":"676fef4f...","email":"admin@receiptcapture.com",...}
```

---

## API Response Check

### In Network Tab:

1. Open DevTools (F12)
2. Go to "Network" tab
3. Log in
4. Look for `login` request
5. Click on it
6. Check "Response" tab

**Successful response**:
```json
{
  "user": {
    "id": "676fef4f-eaef-4e81-af7d-e35ca7a35081",
    "email": "admin@receiptcapture.com",
    "name": "Portal Master Admin",
    "role": "master_admin",
    "companyId": null,
    "isActive": true,
    "emailVerified": true
  },
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "message": "Login successful"
}
```

---

## Troubleshooting

### Issue: "Invalid credentials" error
**Solution**: The password hash has been fixed, but if still seeing this:
- Clear browser cache
- Try hard refresh (Ctrl+F5)
- Restart the dev server

### Issue: Page doesn't redirect
**Solution**: 
- Check browser console for JavaScript errors
- Verify `/admin` or `/dashboard` routes exist

### Issue: Network error
**Solution**:
- Confirm server is running on correct port
- Check firewall settings
- Try `http://localhost:3000` instead of `localhost`

---

## Quick Verification Commands

Run these in PowerShell to verify the backend:

```powershell
# Test database connection
(Invoke-WebRequest -Uri http://localhost:3000/api/test-db).Content

# Test login endpoint
(Invoke-WebRequest -Uri http://localhost:3000/api/auth/login -Method POST -ContentType "application/json" -Body '{"email":"admin@receiptcapture.com","password":"admin123"}').Content
```

Both should return success messages!

---

## ✅ Success Checklist

- [ ] Server running on port 3000
- [ ] Can access http://localhost:3000
- [ ] Landing page loads
- [ ] Login page loads
- [ ] Demo credentials button visible
- [ ] Can enter email and password
- [ ] Sign In button works
- [ ] Gets redirected after login
- [ ] No error messages

---

## 🎉 You're All Set!

Your login is working perfectly with:
- ✅ Supabase PostgreSQL database
- ✅ Secure password hashing (bcrypt)
- ✅ JWT token authentication
- ✅ Row Level Security
- ✅ Demo accounts ready to use

**Next Steps**: Start building your dashboard features! 🚀
