import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { requireAuth } from '@/lib/api-auth';

export const runtime = 'nodejs';

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const BACKEND_API_URL = process.env.BACKEND_API_URL || 'http://localhost:4000';

function getAppBaseUrl(request: NextRequest) {
  return process.env.NEXT_PUBLIC_APP_URL || request.headers.get('origin') || request.nextUrl.origin || 'http://localhost:3000';
}

function normalizeBillingInterval(billingCycle: string | null | undefined) {
  const value = String(billingCycle || '').toLowerCase();
  if (value === 'annual' || value === 'yearly' || value === 'year') {
    return 'year' as const;
  }

  return 'month' as const;
}

function getStripeClient() {
  if (!STRIPE_SECRET_KEY) {
    return null;
  }

  return new Stripe(STRIPE_SECRET_KEY);
}

export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, [
      'primary_representative',
      'representative',
      'company_representative',
      'master_admin',
    ]);

    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context?.user;
    if (!user?.company_id) {
      return NextResponse.json(
        { error: 'Company not found for this account' },
        { status: 400 }
      );
    }

    const { planId } = await request.json();

    if (!planId) {
      return NextResponse.json(
        { error: 'Plan ID is required' },
        { status: 400 }
      );
    }

    if (!STRIPE_SECRET_KEY) {
      return NextResponse.json(
        { 
          error: 'Stripe is not configured',
          message: 'Please configure STRIPE_SECRET_KEY before creating checkout sessions.' 
        },
        { status: 503 }
      );
    }

    const stripe = getStripeClient();
    if (!stripe) {
      return NextResponse.json(
        { error: 'Stripe client could not be initialized' },
        { status: 500 }
      );
    }

    const plansResponse = await fetch(`${BACKEND_API_URL}/api/subscription-plans`, {
      headers: {
        Authorization: request.headers.get('authorization') || '',
      },
    });

    if (!plansResponse.ok) {
      return NextResponse.json(
        { error: 'Failed to load subscription plans' },
        { status: plansResponse.status }
      );
    }

    const plansPayload = await plansResponse.json();
    const plans = Array.isArray(plansPayload) ? plansPayload : plansPayload.plans || [];
    const plan = plans.find((item: any) => item.id === planId);

    if (!plan) {
      return NextResponse.json(
        { error: 'Subscription plan not found' },
        { status: 404 }
      );
    }

    const amount = Number(plan.price ?? plan.amount ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      return NextResponse.json(
        { error: 'Selected plan does not have a valid price' },
        { status: 400 }
      );
    }

    const appBaseUrl = getAppBaseUrl(request);
    const billingInterval = normalizeBillingInterval(plan.billingCycle || plan.billing_cycle);
    const planName = String(plan.name || 'Subscription Plan');
    const planDescription = plan.description ? String(plan.description) : undefined;

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      client_reference_id: String(user.company_id),
      customer_email: user.email,
      allow_promotion_codes: true,
      success_url: `${appBaseUrl}/register/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${appBaseUrl}/pricing?checkout=canceled`,
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: 'usd',
            unit_amount: Math.round(amount * 100),
            recurring: {
              interval: billingInterval,
            },
            product_data: {
              name: planName,
              description: planDescription,
            },
          },
        },
      ],
      metadata: {
        companyId: String(user.company_id),
        planId: String(plan.id),
        planName,
        billingCycle: String(plan.billingCycle || plan.billing_cycle || ''),
      },
      subscription_data: {
        metadata: {
          companyId: String(user.company_id),
          planId: String(plan.id),
          planName,
          billingCycle: String(plan.billingCycle || plan.billing_cycle || ''),
        },
      },
    });

    return NextResponse.json({
      sessionId: session.id,
      url: session.url,
    });

  } catch (error: any) {
    console.error('Error creating checkout session:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
