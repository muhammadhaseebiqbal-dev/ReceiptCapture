import { Router } from 'express';
import { healthRouter } from './health.js';
import { authRouter } from './auth.js';
import { staffRouter } from './staff.js';
import { subscriptionPlansRouter } from './subscription-plans.js';
import { companyRouter } from './company.js';
import { companiesRouter } from './companies.js';
import { adminRouter } from './admin.js';
import { receiptsRouter } from './receipts.js';
import { syncRouter } from './sync.js';

export const apiRouter = Router();

apiRouter.use('/health', healthRouter);
apiRouter.use('/auth', authRouter);
apiRouter.use('/staff', staffRouter);
apiRouter.use('/subscription-plans', subscriptionPlansRouter);
apiRouter.use('/company', companyRouter);
apiRouter.use('/companies', companiesRouter);
apiRouter.use('/admin', adminRouter);
apiRouter.use('/receipts', receiptsRouter);
apiRouter.use('/sync', syncRouter);
