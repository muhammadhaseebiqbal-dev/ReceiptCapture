import { Router } from 'express';
import { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';

export const adminRouter = Router();

adminRouter.get('/stats', requireAuth(['master_admin']), async (_req, res) => {
  try {
    const [totalCompaniesResult, activeCompaniesResult, trialCompaniesResult, totalUsersResult, representativesResult, membersResult, activePlansResult, totalReceiptsResult, revenueResult] = await Promise.all([
      db.query(`select count(*)::int as count from companies`),
      db.query(`select count(*)::int as count from companies where subscription_status = 'active'`),
      db.query(`select count(*)::int as count from companies where subscription_status = 'trial'`),
      db.query(`select count(*)::int as count from users`),
      db.query(`select count(*)::int as count from users where role = 'company_representative'`),
      db.query(`select count(*)::int as count from users where role in ('manager', 'employee')`),
      db.query(`select count(*)::int as count from subscription_plans where is_active = true`),
      db.query(`select count(*)::int as count from receipts`),
      db.query(
        `select c.id, sp.price, sp.billing_cycle
         from companies c
         left join subscription_plans sp on sp.id = c.subscription_plan_id
         where c.subscription_status = 'active'`
      ),
    ]);

    const monthlyRevenue = revenueResult.rows.reduce((sum, row) => {
      if (!row.price) {
        return sum;
      }

      const price = Number(row.price);
      const cycle = row.billing_cycle;
      return sum + (cycle === 'annual' ? price / 12 : price);
    }, 0);

    return res.json({
      totalCompanies: totalCompaniesResult.rows[0]?.count || 0,
      activeCompanies: activeCompaniesResult.rows[0]?.count || 0,
      trialCompanies: trialCompaniesResult.rows[0]?.count || 0,
      totalUsers: totalUsersResult.rows[0]?.count || 0,
      totalRepresentatives: representativesResult.rows[0]?.count || 0,
      totalMembers: membersResult.rows[0]?.count || 0,
      monthlyRevenue,
      activePlans: activePlansResult.rows[0]?.count || 0,
      totalReceipts: totalReceiptsResult.rows[0]?.count || 0,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});