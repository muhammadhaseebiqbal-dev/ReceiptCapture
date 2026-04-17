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

subscriptionPlansRouter.put('/:id', async (req, res) => {
  try {
    const authPayload = getAuthPayload(req);
    if (authPayload?.role !== 'master_admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const { id } = req.params;
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

    // Build update object with only provided fields
    const updateFields = [];
    const updateValues = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updateFields.push(`name = $${paramIndex}`);
      updateValues.push(name);
      paramIndex++;
    }
    if (description !== undefined) {
      updateFields.push(`description = $${paramIndex}`);
      updateValues.push(description || null);
      paramIndex++;
    }
    if (price !== undefined) {
      updateFields.push(`price = $${paramIndex}`);
      updateValues.push(Number(price));
      paramIndex++;
    }
    if (billing_cycle !== undefined) {
      updateFields.push(`billing_cycle = $${paramIndex}`);
      updateValues.push(billing_cycle);
      paramIndex++;
    }
    if (max_users !== undefined) {
      updateFields.push(`max_users = $${paramIndex}`);
      updateValues.push(Number(max_users));
      paramIndex++;
    }
    if (max_receipts_per_month !== undefined) {
      updateFields.push(`max_receipts_per_month = $${paramIndex}`);
      updateValues.push(max_receipts_per_month ? Number(max_receipts_per_month) : null);
      paramIndex++;
    }
    if (features !== undefined) {
      updateFields.push(`features = $${paramIndex}`);
      updateValues.push(features || []);
      paramIndex++;
    }
    if (is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex}`);
      updateValues.push(Boolean(is_active));
      paramIndex++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateValues.push(id);
    const updateQuery = `update subscription_plans set ${updateFields.join(', ')} where id = $${paramIndex} returning id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active`;

    const result = await db.query(updateQuery, updateValues);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan not found' });
    }

    const plan = result.rows[0];
    return res.json({
      success: true,
      message: 'Plan updated successfully',
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
    return res.status(500).json({ error: 'Failed to update subscription plan' });
  }
});

subscriptionPlansRouter.delete('/:id', async (req, res) => {
  try {
    const authPayload = getAuthPayload(req);
    if (authPayload?.role !== 'master_admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const { id } = req.params;

    // Check if plan is in use by any companies
    const checkResult = await db.query(
      'select id from companies where subscription_plan_id = $1 limit 1',
      [id]
    );

    if (checkResult.rows.length > 0) {
      return res.status(400).json({
        error: 'Cannot delete plan that is in use by companies. Deactivate it instead.'
      });
    }

    // Delete the plan
    const result = await db.query(
      'delete from subscription_plans where id = $1 returning id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan not found' });
    }

    return res.json({
      success: true,
      message: 'Plan deleted successfully'
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to delete subscription plan' });
  }
});