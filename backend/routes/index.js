import { Router } from 'express';
import { healthRouter } from './health.js';
import { authRouter } from './auth.js';
import { staffRouter } from './staff.js';
import { subscriptionPlansRouter } from './subscription-plans.js';

export const apiRouter = Router();

apiRouter.use('/health', healthRouter);
apiRouter.use('/auth', authRouter);
apiRouter.use('/staff', staffRouter);
apiRouter.use('/subscription-plans', subscriptionPlansRouter);
