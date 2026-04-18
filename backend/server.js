import dotenv from 'dotenv';
import express from 'express';
import { apiRouter } from './routes/index.js';

dotenv.config();

const app = express();

// Parse CORS origins from environment or use defaults for local dev
const defaultOrigins = [
  'http://localhost:5500',
  'http://127.0.0.1:5500',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
];

const frontendUrl = process.env.FRONTEND_URL?.trim();
const corsOriginsEnv = process.env.ALLOWED_ORIGINS;
const envOrigins = corsOriginsEnv
  ? corsOriginsEnv.split(',').map((origin) => origin.trim()).filter(Boolean)
  : [];

if (frontendUrl) {
  envOrigins.push(frontendUrl);
}

const allowedOrigins = new Set(envOrigins.length > 0 ? envOrigins : defaultOrigins);

app.use((req, res, next) => {
  const origin = req.headers.origin;

  if (origin && allowedOrigins.has(origin)) {
    res.header('Access-Control-Allow-Origin', origin);
    res.header('Vary', 'Origin');
  }

  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }

  return next();
});

app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ service: 'receipt-capture-backend', status: 'ok' });
});

app.use('/api', apiRouter);

const port = Number(process.env.PORT || 4000);
app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
