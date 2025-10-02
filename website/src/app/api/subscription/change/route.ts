import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { verifyToken } from '@/lib/auth';

export async function POST(request: NextRequest) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const { planId } = await request.json();

    if (!planId) {
      return NextResponse.json({ error: 'Plan ID is required' }, { status: 400 });
    }

    // Get the new subscription plan
    const newPlan = dataStore.getSubscriptionPlan(planId);
    if (!newPlan) {
      return NextResponse.json({ error: 'Invalid subscription plan' }, { status: 400 });
    }

    // Get current user and company
    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const company = dataStore.getCompany(user.companyId);
    if (!company) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    // Calculate new subscription end date (30 days from now for monthly, 365 for yearly)
    const subscriptionEndDate = new Date();
    if (newPlan.billingCycle === 'monthly') {
      subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);
    } else {
      subscriptionEndDate.setFullYear(subscriptionEndDate.getFullYear() + 1);
    }

    // Update company subscription
    const updatedCompany = dataStore.updateCompany(user.companyId, {
      subscriptionPlanId: planId,
      subscriptionStatus: 'active',
      subscriptionEndDate: subscriptionEndDate.toISOString(),
      updatedAt: new Date().toISOString(),
    });

    // Create billing history entry
    const billingEntry = {
      id: `bill_${Date.now()}`,
      companyId: user.companyId,
      planId,
      planName: newPlan.name,
      amount: newPlan.price,
      billingCycle: newPlan.billingCycle,
      status: 'paid',
      billingDate: new Date().toISOString(),
      nextBillingDate: subscriptionEndDate.toISOString(),
      description: `Subscription to ${newPlan.name} plan`,
      createdAt: new Date().toISOString(),
    };

    // Add to billing history (we'll store this in data-store)
    dataStore.addBillingHistory(billingEntry);

    return NextResponse.json({
      success: true,
      message: `Successfully upgraded to ${newPlan.name} plan`,
      company: updatedCompany,
      plan: newPlan,
      billingEntry,
    });

  } catch (error) {
    console.error('Subscription change error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}