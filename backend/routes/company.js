import { Router } from 'express';
import { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';

export const companyRouter = Router();

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).toLowerCase());
}

async function loadCompanyOverview(companyId) {
  const companyResult = await db.query(
    `select id, name, domain, destination_email, subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date, created_at, updated_at
     from companies
     where id = $1`,
    [companyId]
  );

  const company = companyResult.rows[0] || null;
  if (!company) return null;

  const [{ rows: planRows }, { rows: staffRows }, { rows: receiptsRows }] = await Promise.all([
    db.query(
      `select id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active
       from subscription_plans
       where id = $1`,
      [company.subscription_plan_id]
    ),
    db.query(
      `select count(*)::int as count
       from users
       where company_id = $1 and role in ('manager', 'employee')`,
      [companyId]
    ),
    db.query(
      `select count(*)::int as count
       from receipts
       where company_id = $1 and created_at >= date_trunc('month', now())`,
      [companyId]
    ),
  ]);

  const plan = planRows[0] || null;
  const staffCount = staffRows[0]?.count || 0;
  const receiptsThisMonth = receiptsRows[0]?.count || 0;

  return {
    company: {
      id: company.id,
      name: company.name,
      domain: company.domain,
      destinationEmail: company.destination_email,
      subscriptionPlanId: company.subscription_plan_id,
      subscriptionStatus: company.subscription_status,
      subscriptionStartDate: company.subscription_start_date,
      subscriptionEndDate: company.subscription_end_date,
      createdAt: company.created_at,
      updatedAt: company.updated_at,
    },
    subscriptionPlan: plan
      ? {
          id: plan.id,
          name: plan.name,
          description: plan.description,
          price: Number(plan.price),
          billingCycle: plan.billing_cycle,
          maxUsers: plan.max_users,
          maxReceiptsPerMonth: plan.max_receipts_per_month,
          features: plan.features || [],
          isActive: plan.is_active,
        }
      : null,
    usage: {
      staffCount,
      activeStaffCount: staffCount,
      receiptsThisMonth,
      maxUsers: plan?.max_users || 0,
      maxReceipts: plan?.max_receipts_per_month || 0,
    },
  };
}

companyRouter.get('/settings', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const companyId = req.auth.role === 'master_admin'
      ? req.query.companyId || req.auth.companyId
      : req.auth.companyId;

    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const overview = await loadCompanyOverview(companyId);
    if (!overview) {
      return res.status(404).json({ error: 'Company not found' });
    }

    return res.json(overview);
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companyRouter.put('/settings', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const companyId = req.auth.role === 'master_admin'
      ? req.body?.companyId || req.query.companyId || req.auth.companyId
      : req.auth.companyId;

    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const { name, destinationEmail, domain } = req.body || {};

    if (!destinationEmail || !isValidEmail(destinationEmail)) {
      return res.status(400).json({ error: 'Valid destination email is required' });
    }

    if (name !== undefined && String(name).trim().length < 2) {
      return res.status(400).json({ error: 'Company name must be at least 2 characters' });
    }

    const updateParts = [];
    const values = [];

    if (name !== undefined) {
      values.push(String(name).trim());
      updateParts.push(`name = $${values.length}`);
    }

    values.push(String(destinationEmail).toLowerCase());
    updateParts.push(`destination_email = $${values.length}`);

    if (domain !== undefined) {
      values.push(domain ? String(domain).trim() : null);
      updateParts.push(`domain = $${values.length}`);
    }

    values.push(companyId);

    const updateSql = `
      update companies
      set ${updateParts.join(', ')}, updated_at = now()
      where id = $${values.length}
      returning id, name, domain, destination_email, subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date, created_at, updated_at
    `;

    const { rows } = await db.query(updateSql, values);
    const updatedCompany = rows[0];

    if (!updatedCompany) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const overview = await loadCompanyOverview(companyId);
    return res.json({
      ...overview,
      message: 'Company settings updated successfully',
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companyRouter.get('/billing', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const companyId = req.auth.role === 'master_admin'
      ? req.query.companyId || req.auth.companyId
      : req.auth.companyId;

    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const companyResult = await db.query(
      `select id, subscription_status, subscription_end_date, subscription_plan_id
       from companies
       where id = $1
       limit 1`,
      [companyId]
    );

    const company = companyResult.rows[0];
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const [billingResult, planResult] = await Promise.all([
      db.query(
        `select id, company_id, plan_id, plan_name, amount, billing_cycle, status, billing_date, next_billing_date, description, created_at
         from billing_history
         where company_id = $1
         order by billing_date desc`,
        [companyId]
      ),
      company.subscription_plan_id
        ? db.query(
            `select id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active
             from subscription_plans
             where id = $1
             limit 1`,
            [company.subscription_plan_id]
          )
        : Promise.resolve({ rows: [] }),
    ]);

    const currentPlan = planResult.rows[0] || null;

    return res.json({
      billingHistory: billingResult.rows.map((b) => ({
        id: b.id,
        companyId: b.company_id,
        planId: b.plan_id,
        planName: b.plan_name,
        amount: Number(b.amount || 0),
        billingCycle: b.billing_cycle,
        status: b.status,
        billingDate: b.billing_date,
        nextBillingDate: b.next_billing_date,
        description: b.description,
        createdAt: b.created_at,
      })),
      currentPlan: currentPlan
        ? {
            id: currentPlan.id,
            name: currentPlan.name,
            description: currentPlan.description,
            price: Number(currentPlan.price),
            billingCycle: currentPlan.billing_cycle,
            maxUsers: currentPlan.max_users,
            maxReceiptsPerMonth: currentPlan.max_receipts_per_month,
            features: currentPlan.features || [],
            isActive: currentPlan.is_active,
          }
        : null,
      company: {
        subscriptionStatus: company.subscription_status,
        subscriptionEndDate: company.subscription_end_date,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companyRouter.post('/change-plan', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const companyId = req.auth.role === 'master_admin'
      ? req.body?.companyId || req.query.companyId || req.auth.companyId
      : req.auth.companyId;

    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const { planId } = req.body || {};
    if (!planId) {
      return res.status(400).json({ error: 'Plan ID is required' });
    }

    const planResult = await db.query(
      `select id, name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active
       from subscription_plans
       where id = $1 and is_active = true
       limit 1`,
      [planId]
    );

    const newPlan = planResult.rows[0];
    if (!newPlan) {
      return res.status(400).json({ error: 'Invalid subscription plan' });
    }

    const subscriptionEndDate = new Date();
    if (newPlan.billing_cycle === 'monthly') {
      subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);
    } else {
      subscriptionEndDate.setFullYear(subscriptionEndDate.getFullYear() + 1);
    }

    const updatedCompanyResult = await db.query(
      `update companies
       set subscription_plan_id = $1,
           subscription_status = 'active',
           subscription_end_date = $2,
           updated_at = now()
       where id = $3
       returning id, subscription_plan_id, subscription_status, subscription_end_date`,
      [planId, subscriptionEndDate.toISOString(), companyId]
    );

    const updatedCompany = updatedCompanyResult.rows[0];
    if (!updatedCompany) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const billingDate = new Date().toISOString();
    await db.query(
      `insert into billing_history
       (company_id, plan_id, plan_name, amount, billing_cycle, status, billing_date, next_billing_date, description)
       values ($1, $2, $3, $4, $5, 'paid', $6, $7, $8)`,
      [
        companyId,
        planId,
        newPlan.name,
        Number(newPlan.price || 0),
        newPlan.billing_cycle,
        billingDate,
        subscriptionEndDate.toISOString(),
        `Subscription to ${newPlan.name} plan`,
      ]
    );

    return res.json({
      success: true,
      message: `Successfully upgraded to ${newPlan.name} plan`,
      company: {
        id: updatedCompany.id,
        subscriptionPlanId: updatedCompany.subscription_plan_id,
        subscriptionStatus: updatedCompany.subscription_status,
        subscriptionEndDate: updatedCompany.subscription_end_date,
      },
      plan: {
        id: newPlan.id,
        name: newPlan.name,
        description: newPlan.description,
        price: Number(newPlan.price),
        billingCycle: newPlan.billing_cycle,
        maxUsers: newPlan.max_users,
        maxReceiptsPerMonth: newPlan.max_receipts_per_month,
        features: newPlan.features || [],
        isActive: newPlan.is_active,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});