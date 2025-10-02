import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { verifyToken } from '@/lib/auth';

export async function GET(request: NextRequest) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Get current user and company
    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    // Get billing history for the company
    const billingHistory = dataStore.getBillingHistory(user.companyId);
    
    // Get current subscription details
    const company = dataStore.getCompany(user.companyId);
    const currentPlan = company?.subscriptionPlanId 
      ? dataStore.getSubscriptionPlan(company.subscriptionPlanId)
      : null;

    return NextResponse.json({
      billingHistory,
      currentPlan,
      company: {
        subscriptionStatus: company?.subscriptionStatus,
        subscriptionEndDate: company?.subscriptionEndDate,
      },
    });

  } catch (error) {
    console.error('Billing history error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}