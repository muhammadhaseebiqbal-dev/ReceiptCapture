import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { db } from '../db/client.js';

export const subscriptionPlansRouter = Router();

function getAuthPayload(req) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) {
    return null;
  }

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    return null;
  }

  try {
    return jwt.verify(token, secret);
  } catch {
    return null;
  }
}

subscriptionPlansRouter.get('/', async (req, res) => {
  try {
    const authPayload = getAuthPayload(req);
    const isAdmin = authPayload?.role === 'master_admin';

    const whereClause = isAdmin ? '' : 'where is_active = true';
    const result = await db.query(
      `select id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active
       from subscription_plans
       ${whereClause}
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

subscriptionPlansRouter.post('/', async (req, res) => {
  try {
    const authPayload = getAuthPayload(req);
    if (authPayload?.role !== 'master_admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const {
      name,
      description,
      price,
      billing_cycle,
      max_users,
      max_receipts_per_month,
      features,
      is_active,
    } = req.body || {};

    if (!name || price === undefined || !billing_cycle || max_users === undefined) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await db.query(
      `insert into subscription_plans
       (name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active)
       values ($1, $2, $3, $4, $5, $6, $7, $8)
       returning id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active`,
      [
        name,
        description || null,
        Number(price),
        billing_cycle,
        Number(max_users),
        max_receipts_per_month === undefined || max_receipts_per_month === null
          ? null
          : Number(max_receipts_per_month),
        features || {},
        is_active === undefined ? true : Boolean(is_active),
      ]
    );

    const plan = result.rows[0];
    return res.status(201).json({
      success: true,
      message: 'Plan created successfully',
      plan: {
        id: plan.id,
        name: plan.name,
        description: plan.description,
        price: Number(plan.price),
        billingCycle: plan.billing_cycle,
        maxUsers: plan.max_users,
        maxReceiptsPerMonth: plan.max_receipts_per_month,
        features: plan.features || [],
        isActive: plan.is_active,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to create subscription plan' });
  }
});