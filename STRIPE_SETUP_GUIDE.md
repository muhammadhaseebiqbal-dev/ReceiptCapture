# Stripe Integration & Subscription Management Setup

## ✅ What's Been Created

### Frontend Files

1. **Public Pricing Page** (`website/src/app/pricing/page.tsx`)
   - Displays all active subscription plans from backend
   - Dynamic plan cards with features and pricing
   - CTA buttons for starting free trial
   - Download app buttons (Android & iOS) with Flutter app links
   - FAQ section with pricing information

2. **Stripe Endpoints** (Placeholder)
   - `POST /api/stripe/create-checkout` - Will create Stripe checkout sessions
   - `POST /api/stripe/webhook` - Will handle payment webhooks

3. **Subscription Status Checking**
   - `website/src/lib/subscription-status.ts` - Utility functions for subscription checks
   - `website/src/components/subscription-gate.tsx` - Gate component to block access if inactive
   - `website/src/app/api/company/subscription-status/route.ts` - Endpoint to check status

4. **Middleware**
   - `website/src/middleware.ts` - Protects `/dashboard` and `/admin` routes with token check

### Backend Files

1. **Subscription Status Route** (`backend/routes/subscription-status.js`)
   - `GET /api/company/subscription-status` - Returns company subscription status
   - Checks subscription expiration
   - Returns isActive flag for gating

## 📋 Next Steps to Complete

### 1. Register Subscription Status Route in Backend

Update `backend/routes/index.js`:

```javascript
import { subscriptionStatusRouter } from './subscription-status.js';

// Add to apiRouter:
apiRouter.use('/company/subscription-status', subscriptionStatusRouter);
```

### 2. Install Stripe Package

```bash
npm install stripe
```

### 3. Configure Stripe Environment Variables

Add to `.env.local` in website folder:

``` bash
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxx
STRIPE_SECRET_KEY=sk_test_xxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxx
```

### 4. Implement Stripe Checkout Creation

Update `website/src/app/api/stripe/create-checkout/route.ts`:

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: NextRequest) {
  // ... existing code ...
  
  // Fetch plan from backend
  const planResponse = await fetch(
    `http://localhost:4000/api/subscription-plans`,
    { headers: { 'Authorization': `Bearer ${token}` } }
  );
  const plans = await planResponse.json();
  const plan = plans.find((p: any) => p.id === planId);
  
  // Create checkout session
  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: plan.name,
            description: plan.description,
          },
          unit_amount: Math.round(plan.price * 100),
          recurring: {
            interval: plan.billing_cycle === 'monthly' ? 'month' : 'year',
            interval_count: 1,
          },
        },
        quantity: 1,
      },
    ],
    mode: 'subscription',
    success_url: 'http://localhost:3000/dashboard?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: 'http://localhost:3000/pricing',
    customer_email: user.email,
    metadata: {
      company_id: user.company_id,
      plan_id: planId,
    },
  });
  
  return NextResponse.json({ sessionId: session.id });
}
```

### 5. Implement Stripe Webhook Handler

Update `website/src/app/api/stripe/webhook/route.ts`:

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // Handle payment success
  if (event.type === 'customer.subscription.created' || 
      event.type === 'customer.subscription.updated') {
    const subscription = event.data.object as Stripe.Subscription;
    
    // Call backend to update subscription status
    await fetch('http://localhost:4000/api/company/subscription', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        stripeSubscriptionId: subscription.id,
        status: subscription.status,
        endDate: new Date(subscription.current_period_end * 1000),
      }),
    });
  }

  return NextResponse.json({ received: true });
}
```

### 6. Add Subscription Gate to Dashboard

Update `website/src/app/dashboard/subscription/page.tsx`:

```typescript
'use client';

import { SubscriptionGate } from '@/components/subscription-gate';

export default function SubscriptionPage() {
  return (
    <SubscriptionGate requireActive={true}>
      {/* Existing subscription page content */}
    </SubscriptionGate>
  );
}
```

### 7. Update Backend to Handle Stripe Webhook

Create `backend/routes/stripe.js`:

```javascript
import { Router } from 'express';
import { db } from '../db/client.js';

export const stripeRouter = Router();

stripeRouter.post('/webhook', async (req, res) => {
  try {
    const { stripeSubscriptionId, status, endDate, metadata } = req.body;
    
    // Update company subscription in database
    await db.query(
      `update companies 
       set subscription_status = $1, 
           subscription_end_date = $2,
           stripe_subscription_id = $3
       where id = $4`,
      [status, endDate, stripeSubscriptionId, metadata.company_id]
    );
    
    return res.json({ success: true });
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: 'Webhook failed' });
  }
});
```

### 8. Navigation Updates

Update `website/src/app/page.tsx` to include link to pricing:

```typescript
<Button variant="ghost" onClick={() => router.push('/pricing')}>
  View Pricing
</Button>
```

## 🔗 Environment Configuration

### Development Setup

1. **Get Stripe Test Keys**: <https://dashboard.stripe.com/test/apikeys>
2. **Set Webhook Endpoint**: <https://dashboard.stripe.com/test/webhooks>
   - Endpoint: `http://your-domain/api/stripe/webhook`
   - Events: `customer.subscription.created`, `customer.subscription.updated`

3. **Update .env.local** in website folder with test keys

## 🧪 Testing Checklist

- [ ] Pricing page loads with real plans
- [ ] Download buttons link to correct app stores
- [ ] Start free trial redirects to registration
- [ ] Checkout session creation works (once Stripe configured)
- [ ] Webhook signature verification works
- [ ] Subscription status gate blocks inactive users
- [ ] Dashboard shows subscription status
- [ ] Admin page manages plans in real DB

## 📝 Database Considerations

The companies table needs these columns (verify they exist):

- `subscription_plan_id` - FK to subscription_plans
- `subscription_status` - enum('active', 'inactive', 'trial', 'expired')
- `subscription_start_date` - timestamp
- `subscription_end_date` - timestamp
- `stripe_subscription_id` - varchar (optional, for Stripe integration)

## 🚀 Flutter Integration

Flutter app will:

1. Open pricing page in webview or browser
2. User taps "Register as Rep" button
3. Redirected to registration form (pre-filled if returning user)
4. After registration, user can see dashboard/portal

The Flutter links are already configured in:

- `FLUTTER_APP_LINK` - Android Play Store
- `FLUTTER_IOS_LINK` - iOS App Store

Update these URLs once apps are published.

## 🔒 Security Notes

- All Stripe endpoints require authentication
- Webhook signature verification is mandatory
- Subscription status must be verified server-side before granting access
- Master admin role required for plan management
