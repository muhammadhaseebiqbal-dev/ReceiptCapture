import { Router } from 'express';
import { randomUUID } from 'crypto';
import sql, { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';
import { saveBase64AsReceiptImage } from '../lib/file-storage.js';

export const syncRouter = Router();

function parseNumber(value) {
  if (value == null || value === '') return null;
  const parsed = Number(String(value).replace(/[^\d.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : null;
}

async function getCompanyById(companyId) {
  const result = await db.query(
    `select id, name, destination_email, subscription_plan_id, subscription_status
     from companies
     where id = $1`,
    [companyId]
  );
  return result.rows[0] || null;
}

async function getCompanyReceiptQuota(companyId) {
  const result = await db.query(
    `select
       c.subscription_status,
       sp.name as plan_name,
       sp.max_receipts_per_month,
       (
         select count(*)::int
         from receipts r
         where r.company_id = c.id
           and r.created_at >= date_trunc('month', now())
       ) as receipts_this_month
     from companies c
     left join subscription_plans sp on sp.id = c.subscription_plan_id
     where c.id = $1
     limit 1`,
    [companyId]
  );

  const row = result.rows[0] || null;
  if (!row) return null;

  return {
    subscriptionStatus: row.subscription_status,
    planName: row.plan_name,
    maxReceiptsPerMonth: row.max_receipts_per_month == null ? null : Number(row.max_receipts_per_month),
    receiptsThisMonth: Number(row.receipts_this_month || 0),
  };
}

function isQuotaExceeded(quota) {
  if (!quota) return false;
  if (!quota.maxReceiptsPerMonth || quota.maxReceiptsPerMonth <= 0) return false;
  return quota.receiptsThisMonth >= quota.maxReceiptsPerMonth;
}

async function insertReceiptRecord(tx, payload) {
  const result = await tx`
    insert into receipts (
      id,
      user_id,
      company_id,
      image_path,
      merchant_name,
      amount,
      receipt_date,
      category,
      notes,
      status,
      email_sent_at,
      created_at,
      updated_at
    ) values (
      ${payload.id},
      ${payload.userId},
      ${payload.companyId},
      ${payload.imagePath},
      ${payload.merchantName},
      ${payload.amount},
      ${payload.receiptDate},
      ${payload.category},
      ${payload.notes},
      ${payload.status},
      ${payload.emailSentAt},
      ${payload.createdAt},
      ${payload.updatedAt}
    )
    returning *
  `;

  return result[0];
}

async function createSyncQueueEntry(tx, payload) {
  const result = await tx`
    insert into sync_queue (
      id,
      receipt_id,
      user_id,
      company_id,
      payload,
      status,
      retry_count,
      last_error,
      created_at,
      updated_at
    ) values (
      ${payload.id},
      ${payload.receiptId},
      ${payload.userId},
      ${payload.companyId},
      ${payload.payload},
      ${payload.status},
      ${payload.retryCount},
      ${payload.lastError},
      ${payload.createdAt},
      ${payload.updatedAt}
    )
    returning *
  `;

  return result[0];
}

syncRouter.post('/queue', requireAuth(['company_representative', 'manager', 'employee', 'master_admin']), async (req, res) => {
  try {
    const body = req.body || {};
    const items = Array.isArray(body.items) ? body.items : Array.isArray(body.receipts) ? body.receipts : [];

    if (!items.length) {
      return res.status(400).json({ error: 'No sync items provided' });
    }

    const invalidItemIndex = items.findIndex((item) => !item.imagePath && !item.imageBase64);
    if (invalidItemIndex !== -1) {
      return res.status(400).json({
        error: 'Each sync item must include imagePath or imageBase64',
        itemIndex: invalidItemIndex,
      });
    }

    const companyId = req.auth.role === 'master_admin' ? body.companyId || req.auth.companyId : req.auth.companyId;
    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const company = await getCompanyById(companyId);
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const quota = await getCompanyReceiptQuota(companyId);
    if (quota?.subscriptionStatus && !['active', 'trial'].includes(quota.subscriptionStatus)) {
      return res.status(403).json({ error: 'Subscription is not active' });
    }

    if (isQuotaExceeded(quota)) {
      return res.status(403).json({
        error: 'Receipt limit reached for this plan',
        planName: quota.planName || 'Current plan',
        receiptsThisMonth: quota.receiptsThisMonth,
        maxReceiptsPerMonth: quota.maxReceiptsPerMonth,
      });
    }

    const transactionResult = await sql.begin(async (tx) => {
      const results = [];

      for (const item of items) {
        const receiptId = item.receiptId || item.id || randomUUID();
        const queueId = item.queueId || randomUUID();
        const createdAt = item.createdAt || new Date().toISOString();
        const updatedAt = item.updatedAt || createdAt;

        let imagePath = item.imagePath || null;
        if (!imagePath && item.imageBase64) {
          const saved = await saveBase64AsReceiptImage(item.imageBase64, item.mimeType, item.fileName);
          imagePath = saved.publicPath;
        }

        const receiptRow = await insertReceiptRecord(tx, {
          id: receiptId,
          userId: item.userId || req.auth.userId,
          companyId,
          imagePath,
          merchantName: item.merchantName || null,
          amount: parseNumber(item.amount),
          receiptDate: item.receiptDate || item.date || null,
          category: item.category || null,
          notes: item.notes || null,
          status: item.status || 'pending',
          emailSentAt: item.emailSentAt || null,
          createdAt,
          updatedAt,
        });

        const queueRow = await createSyncQueueEntry(tx, {
          id: queueId,
          receiptId: receiptRow.id,
          userId: item.userId || req.auth.userId,
          companyId,
          payload: item,
          status: item.queueStatus || 'pending',
          retryCount: Number(item.retryCount || 0),
          lastError: item.lastError || null,
          createdAt,
          updatedAt,
        });

        results.push({ receipt: receiptRow, syncQueue: queueRow });
      }

      return results;
    });

    return res.status(201).json({
      success: true,
      processed: transactionResult.length,
      items: transactionResult,
      emailForwarding: 'skipped',
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to process sync batch' });
  }
});