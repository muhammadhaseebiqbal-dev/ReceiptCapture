import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';

export const runtime = 'nodejs';

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;
const BACKEND_API_URL = process.env.BACKEND_API_URL || 'http://localhost:4000';

function getStripeClient() {
  if (!STRIPE_SECRET_KEY) {
    return null;
  }

  return new Stripe(STRIPE_SECRET_KEY);
}

function mapStripeStatusToAppStatus(status: string | undefined) {
  switch (status) {
    case 'active':
      return 'active';
    case 'trialing':
      return 'trial';
    case 'past_due':
      return 'suspended';
    case 'canceled':
    case 'incomplete_expired':
    case 'unpaid':
      return 'inactive';
    default:
      return 'inactive';
  }
}

async function syncSubscriptionToBackend(payload: Record<string, unknown>) {
  const syncSecret = process.env.STRIPE_WEBHOOK_SYNC_SECRET;
  if (!syncSecret) {
    throw new Error('STRIPE_WEBHOOK_SYNC_SECRET is not configured');
  }

  const response = await fetch(`${BACKEND_API_URL}/api/stripe/subscription-sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-internal-stripe-secret': syncSecret,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Backend sync failed (${response.status}): ${text}`);
  }
}

export async function POST(request: NextRequest) {
  try {
    const stripe = getStripeClient();
    if (!stripe) {
      return NextResponse.json(
        { error: 'Stripe is not configured' },
        { status: 503 }
      );
    }

    if (!STRIPE_WEBHOOK_SECRET) {
      console.warn('STRIPE_WEBHOOK_SECRET not configured');
      return NextResponse.json(
        { error: 'Webhook not configured' },
        { status: 503 }
      );
    }

    const body = await request.text();
    const signature = request.headers.get('stripe-signature');

    if (!signature) {
      return NextResponse.json(
        { error: 'Missing stripe-signature header' },
        { status: 400 }
      );
    }

    const event = stripe.webhooks.constructEvent(body, signature, STRIPE_WEBHOOK_SECRET);

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;

      if (session.subscription) {
        const subscription = await stripe.subscriptions.retrieve(String(session.subscription));
        const companyId = String(session.metadata?.companyId || subscription.metadata?.companyId || session.client_reference_id || '');
        const planId = String(session.metadata?.planId || subscription.metadata?.planId || '');

        if (companyId && planId) {
          await syncSubscriptionToBackend({
            companyId,
            planId,
            planName: session.metadata?.planName || subscription.metadata?.planName || 'Subscription Plan',
            status: mapStripeStatusToAppStatus(subscription.status),
            startDate: new Date(subscription.current_period_start * 1000).toISOString(),
            endDate: new Date(subscription.current_period_end * 1000).toISOString(),
            billingCycle: session.metadata?.billingCycle || subscription.metadata?.billingCycle || 'monthly',
            stripeSubscriptionId: subscription.id,
            stripeCustomerId: typeof session.customer === 'string' ? session.customer : session.customer?.id || null,
            eventId: event.id,
          });
        }
      }
    }

    if (event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.deleted') {
      const subscription = event.data.object as Stripe.Subscription;
      const companyId = String(subscription.metadata?.companyId || '');
      const planId = String(subscription.metadata?.planId || '');

      if (companyId && planId) {
        await syncSubscriptionToBackend({
          companyId,
          planId,
          planName: subscription.metadata?.planName || 'Subscription Plan',
          status: mapStripeStatusToAppStatus(subscription.status),
          startDate: new Date(subscription.current_period_start * 1000).toISOString(),
          endDate: new Date(subscription.current_period_end * 1000).toISOString(),
          billingCycle: subscription.metadata?.billingCycle || 'monthly',
          stripeSubscriptionId: subscription.id,
          stripeCustomerId: typeof subscription.customer === 'string' ? subscription.customer : subscription.customer?.id || null,
          eventId: event.id,
        });
      }
    }

    return NextResponse.json({ received: true });

  } catch (error: any) {
    console.error('Webhook error:', error);
    return NextResponse.json(
      { error: 'Webhook processing failed', details: error.message },
      { status: 500 }
    );
  }
}
