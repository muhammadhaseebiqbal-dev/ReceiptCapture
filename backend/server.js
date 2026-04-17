import dotenv from 'dotenv';
import express from 'express';
import { apiRouter } from './routes/index.js';

dotenv.config();

const app = express();
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ service: 'receipt-capture-backend', status: 'ok' });
});

app.use('/api', apiRouter);

const port = Number(process.env.PORT || 4000);
app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
