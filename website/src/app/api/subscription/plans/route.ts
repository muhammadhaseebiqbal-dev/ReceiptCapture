import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { authService } from '@/lib/auth';

// GET - Get all available subscription plans
export async function GET(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');

    if (!token) {
      return NextResponse.json({ error: 'No token provided' }, { status: 401 });
    }

    const decoded = authService.validateToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const user = dataStore.getUserById(decoded.userId);
    if (!user || !user.isActive) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Get all active subscription plans
    const plans = dataStore.getSubscriptionPlans().filter(plan => plan.isActive);

    return NextResponse.json({ plans });

  } catch (error) {
    console.error('Get subscription plans error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}