import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { FORCE_STRIPE_SIMULATION, STRIPE_SIMULATION_MESSAGE } from '@/lib/stripe-mode';

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

type BackendAuthUser = {
  id: string;
  email: string;
  role: string;
  companyId?: string | null;
};

async function getBackendAuthenticatedUser(request: NextRequest) {
  const authHeader = request.headers.get('authorization') || '';
  if (!authHeader) {
    return {
      user: null as BackendAuthUser | null,
      errorResponse: NextResponse.json({ error: 'Authentication required' }, { status: 401 }),
    };
  }

  const userResponse = await fetch(`${BACKEND_API_URL}/api/auth/me`, {
    headers: {
      Authorization: authHeader,
    },
  });

  if (!userResponse.ok) {
    let payload: any = null;
    try {
      payload = await userResponse.json();
    } catch {
      payload = null;
    }

    return {
      user: null as BackendAuthUser | null,
      errorResponse: NextResponse.json(
        { error: payload?.error || 'Invalid or expired token' },
        { status: userResponse.status }
      ),
    };
  }

  const userPayload = await userResponse.json();
  const user = userPayload?.user as BackendAuthUser | undefined;

  if (!user?.id || !user?.email) {
    return {
      user: null as BackendAuthUser | null,
      errorResponse: NextResponse.json({ error: 'Failed to resolve authenticated user' }, { status: 401 }),
    };
  }

  return { user, errorResponse: null as NextResponse | null };
}

export async function POST(request: NextRequest) {
  try {
    const { user, errorResponse } = await getBackendAuthenticatedUser(request);
    if (errorResponse) {
      return errorResponse;
    }

    const companyId = user?.companyId;
    if (!companyId) {
      return NextResponse.json(
        { error: 'Company not found for this account' },
        { status: 400 }
      );
    }

    const { planId, flow } = await request.json();

    if (!planId) {
      return NextResponse.json(
        { error: 'Plan ID is required' },
        { status: 400 }
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
    const checkoutFlow = flow === 'subscription' ? 'subscription' : 'register';
    const successPath = checkoutFlow === 'subscription'
      ? `/dashboard/subscription?checkout=success&planId=${encodeURIComponent(String(plan.id))}`
      : '/register/success';
    const cancelPath = checkoutFlow === 'subscription'
      ? '/dashboard/subscription?checkout=canceled'
      : '/pricing?checkout=canceled';

    if (FORCE_STRIPE_SIMULATION) {
      const simulatedUrl = checkoutFlow === 'subscription'
        ? `${appBaseUrl}/dashboard/subscription?checkout=simulated&planId=${encodeURIComponent(String(plan.id))}&plan=${encodeURIComponent(planName)}`
        : `${appBaseUrl}/register/success?stripe=simulated&plan=${encodeURIComponent(planName)}`;
      return NextResponse.json({
        simulated: true,
        message: STRIPE_SIMULATION_MESSAGE,
        sessionId: `sim_${Date.now()}`,
        url: simulatedUrl,
      });
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

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      client_reference_id: String(companyId),
      customer_email: user.email,
      allow_promotion_codes: true,
      success_url: `${appBaseUrl}${successPath}${checkoutFlow === 'subscription' ? '&session_id={CHECKOUT_SESSION_ID}' : '?session_id={CHECKOUT_SESSION_ID}'}`,
      cancel_url: `${appBaseUrl}${cancelPath}`,
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
        companyId: String(companyId),
        planId: String(plan.id),
        planName,
        billingCycle: String(plan.billingCycle || plan.billing_cycle || ''),
      },
      subscription_data: {
        metadata: {
          companyId: String(companyId),
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
