import { Router } from 'express';
import { db } from '../db/client.js';

export const subscriptionPlansRouter = Router();

subscriptionPlansRouter.get('/', async (_req, res) => {
  try {
    const result = await db.query(
      `select id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active
       from subscription_plans
       where is_active = true
       order by price asc`
    );

    return res.json({
      plans: result.rows.map((plan) => ({
        id: plan.id,
        name: plan.name,
        description: plan.description,
        price: Number(plan.price),
        billingCycle: plan.billing_cycle,
        maxUsers: plan.max_users,
        maxReceiptsPerMonth: plan.max_receipts_per_month,
        features: plan.features || [],
        isActive: plan.is_active,
      })),
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to fetch subscription plans' });
  }
});