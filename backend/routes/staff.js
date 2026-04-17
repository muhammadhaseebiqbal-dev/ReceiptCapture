import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';

export const staffRouter = Router();

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).toLowerCase());
}

staffRouter.get('/', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const companyId = req.auth.role === 'master_admin' ? req.query.companyId || null : req.auth.companyId;

    let result;
    if (companyId) {
      result = await db.query(
        `select id, email, name, role, company_id, is_active, created_by, created_at
         from users
         where role in ('manager', 'employee') and company_id = $1
         order by created_at desc`,
        [companyId]
      );
    } else {
      result = await db.query(
        `select id, email, name, role, company_id, is_active, created_by, created_at
         from users
         where role in ('manager', 'employee')
         order by created_at desc`
      );
    }

    return res.json({
      staff: result.rows.map((user) => ({
        id: user.id,
        email: user.email,
        name: user.name,
        companyId: user.company_id,
        role: user.role,
        isActive: user.is_active,
        createdBy: user.created_by,
        createdAt: user.created_at,
      })),
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

staffRouter.post('/', requireAuth(['company_representative']), async (req, res) => {
  try {
    const { email, name, role, password } = req.body || {};

    if (!email || !name || !role || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    if (!['manager', 'employee'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const existing = await db.query('select id from users where email = $1', [String(email).toLowerCase()]);
    if (existing.rows[0]) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const result = await db.query(
      `insert into users (email, password_hash, name, role, company_id, is_active, created_by)
       values ($1, $2, $3, $4, $5, true, $6)
       returning id, email, name, role, company_id, is_active, created_by, created_at`,
      [String(email).toLowerCase(), passwordHash, name, role, req.auth.companyId, req.auth.userId]
    );

    const user = result.rows[0];
    return res.status(201).json({
      staff: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
        isActive: user.is_active,
        createdBy: user.created_by,
        createdAt: user.created_at,
      },
      message: 'Staff user created successfully',
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

staffRouter.delete('/:id', requireAuth(['company_representative', 'master_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `select id, company_id, role
       from users
       where id = $1 and role in ('manager', 'employee')`,
      [id]
    );

    const staff = result.rows[0];
    if (!staff) {
      return res.status(404).json({ error: 'Staff user not found' });
    }

    if (req.auth.role !== 'master_admin' && staff.company_id !== req.auth.companyId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    await db.query('delete from users where id = $1', [id]);
    return res.json({ message: 'Staff user deleted successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});