import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { db } from '../db/client.js';

export const subscriptionStatusRouter = Router();

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

// GET /api/company/subscription-status
// Returns subscription status for the authenticated company
subscriptionStatusRouter.get('/', async (req, res) => {
  try {
    const authPayload = getAuthPayload(req);
    const companyId = authPayload?.companyId || authPayload?.company_id || null;

    if (!authPayload || !companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Fetch company subscription info
    const companyResult = await db.query(
      `select 
        c.id, c.subscription_plan_id, c.subscription_status, c.subscription_start_date, c.subscription_end_date,
        sp.name as plan_name
       from companies c
       left join subscription_plans sp on c.subscription_plan_id = sp.id
       where c.id = $1`,
      [companyId]
    );

    if (companyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const company = companyResult.rows[0];
    
    // Determine subscription status
    let status = company.subscription_status || 'inactive';
    
    // Check if subscription has expired
    if (company.subscription_end_date) {
      const endDate = new Date(company.subscription_end_date);
      if (new Date() > endDate) {
        status = 'expired';
      }
    }

    return res.json({
      status,
      planId: company.subscription_plan_id,
      planName: company.plan_name || 'No Plan',
      startDate: company.subscription_start_date,
      endDate: company.subscription_end_date,
      isActive: status === 'active' || status === 'trial'
    });

  } catch (error) {
    console.error('Error fetching subscription status:', error);
    return res.status(500).json({ error: 'Failed to fetch subscription status' });
  }
});
