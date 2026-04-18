import { Router } from 'express';
import { db } from '../db/client.js';

export const stripeRouter = Router();

function normalizeSubscriptionStatus(status) {
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

function addInterval(baseDate, billingCycle) {
  const date = new Date(baseDate);
  if (billingCycle === 'annual' || billingCycle === 'yearly' || billingCycle === 'year') {
    date.setFullYear(date.getFullYear() + 1);
    return date;
  }

  date.setMonth(date.getMonth() + 1);
  return date;
}

function parseDateValue(value, fallback) {
  if (!value) {
    return fallback;
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? fallback : date;
}

stripeRouter.post('/subscription-sync', async (req, res) => {
  try {
    const syncSecret = process.env.STRIPE_WEBHOOK_SYNC_SECRET;
    if (!syncSecret) {
      return res.status(500).json({ error: 'Stripe sync secret is not configured' });
    }

    const providedSecret = req.headers['x-internal-stripe-secret'];
    if (providedSecret !== syncSecret) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const {
      companyId,
      planId,
      planName,
      status,
      startDate,
      endDate,
      billingCycle,
      stripeSubscriptionId,
      stripeCustomerId,
      eventId,
    } = req.body || {};

    if (!companyId || !planId) {
      return res.status(400).json({ error: 'companyId and planId are required' });
    }

    const companyResult = await db.query(
      `select id from companies where id = $1 limit 1`,
      [companyId]
    );

    if (companyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const planResult = await db.query(
      `select id, name, price, billing_cycle
       from subscription_plans
       where id = $1
       limit 1`,
      [planId]
    );

    const plan = planResult.rows[0] || null;
    const resolvedBillingCycle = billingCycle || plan?.billing_cycle || 'monthly';
    const resolvedPlanName = planName || plan?.name || 'Subscription';
    const resolvedStatus = normalizeSubscriptionStatus(status);
    const resolvedStartDate = parseDateValue(startDate, new Date());
    const resolvedEndDate = parseDateValue(endDate, addInterval(resolvedStartDate, resolvedBillingCycle));

    await db.query(
      `update companies
       set subscription_plan_id = $1,
           subscription_status = $2,
           subscription_start_date = $3,
           subscription_end_date = $4,
           updated_at = now()
       where id = $5`,
      [
        planId,
        resolvedStatus,
        resolvedStartDate.toISOString(),
        resolvedEndDate.toISOString(),
        companyId,
      ]
    );

    if (plan && resolvedStatus !== 'inactive') {
      const billingEventKey = eventId || stripeSubscriptionId || `${companyId}-${planId}-${resolvedStartDate.toISOString()}`;
      const billingDescription = `Stripe subscription sync ${billingEventKey}`;

      const existingBilling = await db.query(
        `select id from billing_history where company_id = $1 and description = $2 limit 1`,
        [companyId, billingDescription]
      );

      if (existingBilling.rows.length === 0) {
        await db.query(
          `insert into billing_history
           (company_id, plan_id, plan_name, amount, billing_cycle, status, billing_date, next_billing_date, description)
           values ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            companyId,
            planId,
            resolvedPlanName,
            Number(plan.price || 0),
            resolvedBillingCycle,
            'paid',
            resolvedStartDate.toISOString(),
            resolvedEndDate.toISOString(),
            billingDescription,
          ]
        );
      }
    }

    return res.json({
      success: true,
      companyId,
      planId,
      subscriptionStatus: resolvedStatus,
      subscriptionStartDate: resolvedStartDate.toISOString(),
      subscriptionEndDate: resolvedEndDate.toISOString(),
      stripeSubscriptionId: stripeSubscriptionId || null,
      stripeCustomerId: stripeCustomerId || null,
    });
  } catch (error) {
    console.error('Stripe sync error:', error);
    return res.status(500).json({ error: 'Failed to sync subscription' });
  }
});