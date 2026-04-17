import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const { planId } = await request.json();
    if (!planId) {
      return NextResponse.json({ error: 'Plan ID is required' }, { status: 400 });
    }

    const { data: newPlan, error: planError } = await supabaseAdmin
      .from('subscription_plans')
      .select('*')
      .eq('id', planId)
      .eq('is_active', true)
      .maybeSingle();

    if (planError || !newPlan) {
      return NextResponse.json({ error: 'Invalid subscription plan' }, { status: 400 });
    }

    const subscriptionEndDate = new Date();
    if (newPlan.billing_cycle === 'monthly') {
      subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);
    } else {
      subscriptionEndDate.setFullYear(subscriptionEndDate.getFullYear() + 1);
    }

    const { data: updatedCompany, error: updateError } = await supabaseAdmin
      .from('companies')
      .update({
        subscription_plan_id: planId,
        subscription_status: 'active',
        subscription_end_date: subscriptionEndDate.toISOString(),
      })
      .eq('id', user.company_id)
      .select('*')
      .single();

    if (updateError || !updatedCompany) {
      return NextResponse.json({ error: 'Failed to update subscription' }, { status: 500 });
    }

    const billingEntry = {
      company_id: user.company_id,
      plan_id: planId,
      plan_name: newPlan.name,
      amount: newPlan.price,
      billing_cycle: newPlan.billing_cycle,
      status: 'paid',
      billing_date: new Date().toISOString(),
      next_billing_date: subscriptionEndDate.toISOString(),
      description: `Subscription to ${newPlan.name} plan`,
    };

    await supabaseAdmin.from('billing_history').insert(billingEntry);

    return NextResponse.json({
      success: true,
      message: `Successfully upgraded to ${newPlan.name} plan`,
      company: {
        id: updatedCompany.id,
        subscriptionPlanId: updatedCompany.subscription_plan_id,
        subscriptionStatus: updatedCompany.subscription_status,
        subscriptionEndDate: updatedCompany.subscription_end_date,
      },
      plan: {
        id: newPlan.id,
        name: newPlan.name,
        description: newPlan.description,
        price: newPlan.price,
        billingCycle: newPlan.billing_cycle,
        maxUsers: newPlan.max_users,
        maxReceiptsPerMonth: newPlan.max_receipts_per_month,
        features: newPlan.features || [],
        isActive: newPlan.is_active,
      },
      billingEntry,
    });
  } catch (error) {
    console.error('Subscription change error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
