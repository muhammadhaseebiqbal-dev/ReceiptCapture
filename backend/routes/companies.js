import { Router } from 'express';
import { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';

export const companiesRouter = Router();

function normalizeCompanyRow(company) {
  return {
    ...company,
    subscription_plan: company.subscription_plan
      ? {
          id: company.subscription_plan.id,
          name: company.subscription_plan.name,
          price: Number(company.subscription_plan.price),
          billing_cycle: company.subscription_plan.billing_cycle,
          max_users: company.subscription_plan.max_users,
          max_receipts_per_month: company.subscription_plan.max_receipts_per_month,
        }
      : null,
  };
}

companiesRouter.get('/', requireAuth(['master_admin']), async (_req, res) => {
  try {
    const { rows: companies } = await db.query(
      `select c.*, sp.id as plan_id, sp.name as plan_name, sp.price, sp.billing_cycle, sp.max_users, sp.max_receipts_per_month
       from companies c
       left join subscription_plans sp on sp.id = c.subscription_plan_id
       order by c.created_at desc`
    );

    const companiesWithCounts = await Promise.all(
      companies.map(async (company) => {
        const [{ rows: userRows }, { rows: receiptRows }] = await Promise.all([
          db.query(`select count(*)::int as count from users where company_id = $1`, [company.id]),
          db.query(`select count(*)::int as count from receipts where company_id = $1`, [company.id]),
        ]);

        return {
          ...company,
          subscription_plan: company.plan_id
            ? {
                id: company.plan_id,
                name: company.plan_name,
                price: Number(company.price),
                billing_cycle: company.billing_cycle,
                max_users: company.max_users,
                max_receipts_per_month: company.max_receipts_per_month,
              }
            : null,
          user_count: userRows[0]?.count || 0,
          receipt_count: receiptRows[0]?.count || 0,
        };
      })
    );

    return res.json(companiesWithCounts.map(normalizeCompanyRow));
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companiesRouter.post('/', requireAuth(['master_admin']), async (req, res) => {
  try {
    const {
      name,
      domain,
      destination_email,
      subscription_plan_id,
      subscription_status,
      subscription_start_date,
      subscription_end_date,
    } = req.body || {};

    if (!name || !subscription_plan_id) {
      return res.status(400).json({ error: 'Name and subscription plan are required' });
    }

    const { rows } = await db.query(
      `insert into companies
       (name, domain, destination_email, subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date)
       values ($1, $2, $3, $4, $5, $6, $7)
       returning *`,
      [
        name,
        domain || null,
        destination_email || null,
        subscription_plan_id,
        subscription_status || 'trial',
        subscription_start_date || new Date().toISOString(),
        subscription_end_date || null,
      ]
    );

    return res.status(201).json(rows[0]);
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companiesRouter.get('/:id', requireAuth(['master_admin']), async (req, res) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `select c.*, sp.id as plan_id, sp.name as plan_name, sp.price, sp.billing_cycle, sp.max_users, sp.max_receipts_per_month
       from companies c
       left join subscription_plans sp on sp.id = c.subscription_plan_id
       where c.id = $1
       limit 1`,
      [id]
    );

    const company = rows[0];
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const [{ rows: userRows }, { rows: receiptRows }] = await Promise.all([
      db.query(`select count(*)::int as count from users where company_id = $1`, [id]),
      db.query(`select count(*)::int as count from receipts where company_id = $1`, [id]),
    ]);

    return res.json({
      ...company,
      subscription_plan: company.plan_id
        ? {
            id: company.plan_id,
            name: company.plan_name,
            price: Number(company.price),
            billing_cycle: company.billing_cycle,
            max_users: company.max_users,
            max_receipts_per_month: company.max_receipts_per_month,
          }
        : null,
      user_count: userRows[0]?.count || 0,
      receipt_count: receiptRows[0]?.count || 0,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companiesRouter.put('/:id', requireAuth(['master_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      destination_email,
      subscription_plan_id,
      subscription_status,
      subscription_start_date,
      subscription_end_date,
    } = req.body || {};

    const updates = [];
    const values = [];

    if (name !== undefined) {
      values.push(name);
      updates.push(`name = $${values.length}`);
    }

    if (destination_email !== undefined) {
      values.push(destination_email);
      updates.push(`destination_email = $${values.length}`);
    }

    if (subscription_plan_id !== undefined) {
      values.push(subscription_plan_id);
      updates.push(`subscription_plan_id = $${values.length}`);
    }

    if (subscription_status !== undefined) {
      values.push(subscription_status);
      updates.push(`subscription_status = $${values.length}`);
    }

    if (subscription_start_date !== undefined) {
      values.push(subscription_start_date);
      updates.push(`subscription_start_date = $${values.length}`);
    }

    if (subscription_end_date !== undefined) {
      values.push(subscription_end_date);
      updates.push(`subscription_end_date = $${values.length}`);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(id);
    const { rows } = await db.query(
      `update companies set ${updates.join(', ')}, updated_at = now() where id = $${values.length} returning *`,
      values
    );

    const company = rows[0];
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    return res.json(company);
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

companiesRouter.delete('/:id', requireAuth(['master_admin']), async (req, res) => {
  try {
    const { id } = req.params;

    const { rows: userRows } = await db.query(`select count(*)::int as count from users where company_id = $1`, [id]);
    const userCount = userRows[0]?.count || 0;
    if (userCount > 0) {
      return res.status(400).json({ error: `Cannot delete company with ${userCount} users. Please remove users first.` });
    }

    await db.query(`delete from companies where id = $1`, [id]);
    return res.json({ message: 'Company deleted successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});