# Quick Start Guide - Receipt Capture Website

## What's New

✅ **Landing Page** - Beautiful, modern landing page with:
- Hero section with clear value proposition
- Features showcase
- How it works section
- Pricing plans (3 tiers)
- Call-to-action sections
- Professional footer

✅ **Improved Login Page** - Enhanced login experience with:
- Two-column layout (form + features)
- Selected plan indicator
- Quick demo account access
- Better visual design
- Mobile responsive

## Running the Website

### 1. Navigate to the website directory
```powershell
cd d:\WORK\ReceiptCapture\website
```

### 2. Start the development server
```powershell
npm run dev
```

### 3. Open in browser
The site will be available at: **http://localhost:3000**

## Testing the Flow

### New User Journey
1. Visit `http://localhost:3000`
2. Browse the landing page
3. Scroll to pricing section (or click "View Pricing")
4. Click "Get Started" on any plan
5. You'll be redirected to login with the selected plan shown
6. Can register or use demo credentials

### Existing User Journey
1. Visit `http://localhost:3000`
2. Click "Sign In" in navigation
3. Use demo credentials or register
4. Access dashboard

### Demo Credentials
You can click the demo account buttons on the login page, or manually enter:

**Master Admin:**
- Email: `admin@receiptcapture.com`
- Password: `admin123`

**Company Representative:**
- Email: `rep@techcorp.com`
- Password: `password123`

## Page Routes

- `/` - Landing page (new)
- `/login` - Login page (improved)
- `/register` - Registration page (existing)
- `/dashboard` - Company dashboard (existing)
- `/admin` - Admin dashboard (existing)

## Features Implemented

### Landing Page Features:
- ✅ Responsive navigation with sticky header
- ✅ Eye-catching hero section with stats
- ✅ Feature cards with icons
- ✅ 3-step "How It Works" section
- ✅ Pricing cards with feature lists
- ✅ Plan selection that carries to login
- ✅ Multiple CTAs throughout
- ✅ Professional footer
- ✅ Smooth scroll to pricing section
- ✅ Light/Dark mode support
- ✅ Mobile responsive

### Login Page Features:
- ✅ Two-column layout (desktop)
- ✅ Selected plan indicator
- ✅ Password show/hide toggle
- ✅ Demo account quick access buttons
- ✅ Feature highlights panel
- ✅ Customer testimonial
- ✅ Back to home navigation
- ✅ Register company CTA
- ✅ Security badge
- ✅ Mobile responsive

## Design System

### Colors
- **Primary**: Main brand color (buttons, links)
- **Secondary**: Supporting elements
- **Muted**: Text descriptions
- **Destructive**: Errors and warnings

### Components
All components are from shadcn/ui:
- Button (multiple variants)
- Card
- Input
- Label
- Badge
- Alert

### Icons
All icons from Lucide React:
- Receipt, Mail, Users, BarChart3
- Shield, Cloud, Zap, Clock
- Check, Star, ArrowRight, etc.

## Customization

### Update Pricing Plans
Edit `website/src/app/page.tsx` and modify the `plans` array:
```typescript
const plans = [
  {
    name: 'Starter',
    price: 29.99,
    maxUsers: 5,
    maxReceipts: 100,
    features: [...],
    // ...
  },
  // Add or modify plans
];
```

### Update Features
Modify the `features` array in `page.tsx`:
```typescript
const features = [
  {
    icon: Receipt,
    title: 'Feature Name',
    description: 'Feature description'
  },
  // Add more features
];
```

### Change Colors
Update `website/src/app/globals.css` for theme customization.

## Next Steps

### To Complete the Integration:

1. **API Endpoints**
   - Ensure `/api/auth/login` is working
   - Test registration endpoint
   - Verify token storage and validation

2. **Payment Integration**
   - Integrate Stripe for subscriptions
   - Add plan upgrade/downgrade flow
   - Implement billing page

3. **Additional Pages**
   - Complete registration flow
   - Add password reset functionality
   - Create terms and privacy pages

4. **Enhancements**
   - Add FAQ section to landing page
   - Include more customer testimonials
   - Add video demo
   - Implement animations for smoother UX
   - Add loading skeletons

5. **Testing**
   - Test on different browsers
   - Verify mobile responsiveness
   - Test with screen readers
   - Performance optimization

## Troubleshooting

### Port Already in Use
```powershell
# Kill the process on port 3000
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process -Force

# Or use a different port
npm run dev -- --port 3001
```

### Build Errors
```powershell
# Clear cache and reinstall
rm -r -fo node_modules
rm -fo package-lock.json
npm install
```

### Hot Reload Not Working
```powershell
# Restart the dev server
# Press Ctrl+C to stop, then run again
npm run dev
```

## Build for Production

```powershell
# Build the application
npm run build

# Start production server
npm run start
```

## File Structure

```
website/src/
├── app/
│   ├── page.tsx           # Landing page (NEW)
│   ├── login/
│   │   └── page.tsx       # Login page (IMPROVED)
│   ├── register/
│   ├── dashboard/
│   ├── admin/
│   ├── layout.tsx         # Updated metadata
│   └── globals.css
├── components/
│   └── ui/
│       ├── button.tsx
│       ├── card.tsx
│       ├── input.tsx
│       ├── badge.tsx
│       └── ...
└── lib/
    └── utils.ts
```

## Performance Tips

1. All images should be optimized
2. Use Next.js Image component for better performance
3. Lazy load components below the fold
4. Enable caching for static assets
5. Use proper meta tags for SEO

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Questions or Issues?

Check the documentation files:
- `LANDING_PAGE_SUMMARY.md` - Detailed feature documentation
- `LANDING_PAGE_VISUAL_GUIDE.md` - Visual layout reference
- This file - Quick start and troubleshooting

---

**Happy coding! 🚀**
