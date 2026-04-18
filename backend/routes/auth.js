import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { db } from '../db/client.js';
import { requireAuth } from '../middleware/auth.js';

export const authRouter = Router();

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT secret is not configured');
  }
  return secret;
}

function generateToken(userId, email, role, companyId = null) {
  return jwt.sign(
    {
      userId,
      email,
      role,
      companyId,
    },
    getJwtSecret(),
    { expiresIn: '7d' }
  );
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).toLowerCase());
}

async function getUserByEmail(email, roleFilter = null) {
  const params = [String(email).toLowerCase()];
  let sql = `
    select id, email, password_hash, name, role, company_id, is_active
    from users
    where email = $1
  `;

  if (roleFilter) {
    params.push(roleFilter);
    sql += ` and role = $2`;
  }

  const result = await db.query(sql, params);
  return result.rows[0] || null;
}

authRouter.post('/register', async (req, res) => {
  try {
    const {
      companyName,
      companyDomain,
      destinationEmail,
      representativeName,
      representativeEmail,
      representativePassword,
      selectedPlanId,
    } = req.body || {};

    if (!companyName || !destinationEmail || !representativeName || !representativeEmail || !representativePassword || !selectedPlanId) {
      return res.status(400).json({ error: 'All required fields must be provided' });
    }

    if (!isValidEmail(representativeEmail) || !isValidEmail(destinationEmail)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    const existingUser = await getUserByEmail(representativeEmail);
    if (existingUser) {
      return res.status(400).json({ error: 'A user with this email already exists' });
    }

    const planResult = await db.query(
      `select id, name, billing_cycle
       from subscription_plans
       where id = $1 and is_active = true`,
      [selectedPlanId]
    );

    const subscriptionPlan = planResult.rows[0];
    if (!subscriptionPlan) {
      return res.status(400).json({ error: 'Invalid subscription plan selected' });
    }

    const passwordHash = await bcrypt.hash(representativePassword, 12);
    const now = new Date();
    const subscriptionEndDate = new Date(now);
    subscriptionEndDate.setDate(subscriptionEndDate.getDate() + 30);

    const companyResult = await db.query(
      `insert into companies (name, domain, destination_email, subscription_plan_id, subscription_status, subscription_start_date, subscription_end_date)
       values ($1, $2, $3, $4, 'trial', $5, $6)
       returning id, name, destination_email, subscription_status`,
      [
        companyName,
        companyDomain || null,
        destinationEmail.toLowerCase(),
        selectedPlanId,
        now.toISOString(),
        subscriptionEndDate.toISOString(),
      ]
    );

    const company = companyResult.rows[0];
    if (!company) {
      return res.status(500).json({ error: 'Failed to create company' });
    }

    const userResult = await db.query(
      `insert into users (email, password_hash, name, role, company_id, is_active)
       values ($1, $2, $3, 'company_representative', $4, true)
       returning id, email, name, role, company_id, is_active`,
      [
        representativeEmail.toLowerCase(),
        passwordHash,
        representativeName,
        company.id,
      ]
    );

    const user = userResult.rows[0];
    if (!user) {
      return res.status(500).json({ error: 'Failed to create representative account' });
    }

    await db.query(
      `insert into billing_history (company_id, plan_id, plan_name, amount, billing_cycle, status, billing_date, next_billing_date, description)
       values ($1, $2, $3, 0, $4, 'paid', $5, $6, $7)`,
      [
        company.id,
        selectedPlanId,
        subscriptionPlan.name,
        subscriptionPlan.billing_cycle,
        now.toISOString(),
        subscriptionEndDate.toISOString(),
        `30-day trial for ${subscriptionPlan.name} plan`,
      ]
    );

    const token = generateToken(user.id, user.email, user.role, user.company_id);

    return res.status(201).json({
      success: true,
      message: 'Company registration successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
      },
      company: {
        id: company.id,
        name: company.name,
        destinationEmail: company.destination_email,
        subscriptionStatus: company.subscription_status,
      },
      token,
      tokenPayload: {
        userId: user.id,
        email: user.email,
        role: user.role,
        companyId: user.company_id,
      },
      subscriptionPlan: {
        name: subscriptionPlan.name,
        trialEndDate: subscriptionEndDate.toISOString(),
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error during registration' });
  }
});

authRouter.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await getUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      return res.status(500).json({ error: 'JWT secret is not configured' });
    }

    const token = generateToken(user.id, user.email, user.role, user.company_id);

    return res.json({
      token,
      accountStatus: user.is_active ? 'active' : 'inactive',
      requiresVerification: !user.is_active,
      message: user.is_active ? undefined : 'Account is not verified yet. Access is limited until verification is complete.',
      tokenPayload: {
        userId: user.id,
        email: user.email,
        role: user.role,
        companyId: user.company_id,
      },
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
        isActive: user.is_active,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

authRouter.post('/staff/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    const user = await getUserByEmail(email);
    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (!['manager', 'employee'].includes(user.role)) {
      return res.status(403).json({ error: 'Unauthorized account type' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = generateToken(user.id, user.email, user.role, user.company_id);

    return res.json({
      token,
      tokenPayload: {
        userId: user.id,
        email: user.email,
        role: user.role,
        companyId: user.company_id,
      },
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
        isActive: user.is_active,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

authRouter.get('/me', requireAuth(), async (req, res) => {
  try {
    const result = await db.query(
      `select id, email, name, role, company_id, is_active
       from users
       where id = $1`,
      [req.auth.userId]
    );

    const user = result.rows[0];
    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'User not found or inactive' });
    }

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
        isActive: user.is_active,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});
