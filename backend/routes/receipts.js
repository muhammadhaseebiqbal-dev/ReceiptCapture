import { Router } from 'express';
import Busboy from 'busboy';
import { randomUUID } from 'crypto';
import sql, { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';
import { saveBufferAsReceiptImage, saveBase64AsReceiptImage } from '../lib/file-storage.js';

export const receiptsRouter = Router();

function parseJson(value, fallback = null) {
  if (value == null || value === '') return fallback;
  if (typeof value === 'object') return value;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function parseNumber(value) {
  if (value == null || value === '') return null;
  const parsed = Number(String(value).replace(/[^\d.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : null;
}

function getAllowedReceiptRoles() {
  return ['company_representative', 'manager', 'employee', 'master_admin'];
}

function parseDateValue(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
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

receiptsRouter.get('/', requireAuth(getAllowedReceiptRoles()), async (req, res) => {
  try {
    const role = req.auth.role;
    const companyId = role === 'master_admin' ? req.query.companyId || req.auth.companyId : req.auth.companyId;

    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const status = String(req.query.status || '').trim();
    const search = String(req.query.search || '').trim().toLowerCase();
    const startDate = parseDateValue(req.query.startDate);
    const endDate = parseDateValue(req.query.endDate);
    const minAmount = req.query.minAmount === undefined ? null : Number(req.query.minAmount);
    const maxAmount = req.query.maxAmount === undefined ? null : Number(req.query.maxAmount);
    const page = Math.max(Number(req.query.page || 1), 1);
    const limit = Math.max(Number(req.query.limit || 10), 1);

    const result = await db.query(
      `select
         r.id,
         r.user_id,
         r.company_id,
         r.image_path,
         r.merchant_name,
         r.amount,
         r.receipt_date,
         r.category,
         r.notes,
         r.status,
         r.email_sent_at,
         r.created_at,
         u.name as user_name,
         u.email as user_email
       from receipts r
       left join users u on u.id = r.user_id
       where r.company_id = $1
       order by r.created_at desc`,
      [companyId]
    );

    const allReceipts = result.rows || [];

    const filtered = allReceipts.filter((item) => {
      if (status && status !== 'all' && item.status !== status) {
        return false;
      }

      const eventDate = parseDateValue(item.receipt_date || item.created_at);
      if (startDate && eventDate && eventDate < startDate) {
        return false;
      }

      if (endDate && eventDate && eventDate > endDate) {
        return false;
      }

      const amount = item.amount === null || item.amount === undefined ? null : Number(item.amount);
      if (minAmount !== null && Number.isFinite(minAmount) && (amount === null || amount < minAmount)) {
        return false;
      }

      if (maxAmount !== null && Number.isFinite(maxAmount) && (amount === null || amount > maxAmount)) {
        return false;
      }

      if (search) {
        const haystack = `${item.merchant_name || ''} ${item.notes || ''} ${item.category || ''}`.toLowerCase();
        if (!haystack.includes(search)) {
          return false;
        }
      }

      return true;
    });

    const total = filtered.length;
    const totalPages = Math.max(Math.ceil(total / limit), 1);
    const start = (page - 1) * limit;
    const pageRows = filtered.slice(start, start + limit);

    return res.json({
      receipts: pageRows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        companyId: row.company_id,
        imagePath: row.image_path,
        merchantName: row.merchant_name,
        amount: row.amount === null || row.amount === undefined ? null : Number(row.amount),
        receiptDate: row.receipt_date,
        category: row.category,
        notes: row.notes,
        status: row.status,
        emailSentAt: row.email_sent_at,
        createdAt: row.created_at,
        userName: row.user_name || 'Unknown User',
        userEmail: row.user_email || '',
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
      stats: {
        total: allReceipts.length,
        pending: allReceipts.filter((r) => r.status === 'pending').length,
        processed: allReceipts.filter((r) => r.status === 'processed').length,
        sent: allReceipts.filter((r) => r.status === 'sent').length,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to fetch receipts' });
  }
});

receiptsRouter.post('/upload', requireAuth(getAllowedReceiptRoles()), async (req, res) => {
  const contentType = req.headers['content-type'] || '';
  if (!contentType.includes('multipart/form-data')) {
    return res.status(400).json({ error: 'Multipart form-data is required' });
  }

  try {
    const fields = {};
    let fileBuffer = null;
    let fileMimeType = 'application/octet-stream';
    let fileName = 'receipt';

    const parseResult = await new Promise((resolve, reject) => {
      const busboy = Busboy({ headers: req.headers });

      busboy.on('field', (name, value) => {
        fields[name] = value;
      });

      busboy.on('file', (_name, file, info) => {
        const chunks = [];
        fileMimeType = info.mimeType || fileMimeType;
        fileName = info.filename || fileName;
        file.on('data', (chunk) => chunks.push(chunk));
        file.on('end', () => {
          fileBuffer = Buffer.concat(chunks);
        });
      });

      busboy.on('error', reject);
      busboy.on('finish', resolve);
      req.pipe(busboy);
    });

    await parseResult;

    const companyId = req.auth.role === 'master_admin' ? fields.companyId || req.auth.companyId : req.auth.companyId;
    if (!companyId) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const company = await getCompanyById(companyId);
    if (!company) {
      return res.status(404).json({ error: 'Company not found' });
    }

    if (!fileBuffer && !fields.imageBase64) {
      return res.status(400).json({ error: 'Receipt image is required' });
    }

    const uploadedImage = fileBuffer
      ? await saveBufferAsReceiptImage(fileBuffer, fileMimeType, fileName)
      : await saveBase64AsReceiptImage(fields.imageBase64, fields.mimeType, fields.fileName);

    const now = new Date().toISOString();
    const receiptId = fields.receiptId || fields.id || randomUUID();
    const userId = fields.userId || req.auth.userId;
    const receiptDate = fields.receiptDate || fields.date || null;

    const receiptPayload = {
      id: receiptId,
      userId,
      companyId,
      imagePath: uploadedImage.publicPath,
      merchantName: fields.merchantName || null,
      amount: parseNumber(fields.amount),
      receiptDate,
      category: fields.category || null,
      notes: fields.notes || null,
      status: fields.status || 'pending',
      emailSentAt: null,
      createdAt: fields.createdAt || now,
      updatedAt: fields.updatedAt || now,
    };

    const syncPayload = parseJson(fields.syncPayload, null) || receiptPayload;

    const result = await sql.begin(async (tx) => {
      const receiptRow = await insertReceiptRecord(tx, receiptPayload);
      const queueRow = await createSyncQueueEntry(tx, {
        id: fields.queueId || randomUUID(),
        receiptId: receiptRow.id,
        userId,
        companyId,
        payload: syncPayload,
        status: 'pending',
        retryCount: Number(fields.retryCount || 0),
        lastError: null,
        createdAt: now,
        updatedAt: now,
      });

      return { receiptRow, queueRow };
    });

    return res.status(201).json({
      receipt: result.receiptRow,
      syncQueue: result.queueRow,
      emailForwarding: 'skipped',
      message: 'Receipt uploaded successfully',
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to upload receipt' });
  }
});