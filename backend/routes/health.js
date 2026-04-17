import { Router } from 'express';
import { db } from '../db/client.js';

export const healthRouter = Router();

healthRouter.get('/', async (_req, res) => {
  try {
    await db.query('select 1');
    return res.json({ ok: true, service: 'receipt-capture-backend' });
  } catch (error) {
    return res.status(500).json({ ok: false, error: 'Database unavailable' });
  }
});
