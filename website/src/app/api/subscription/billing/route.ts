import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const [{ data: company, error: companyError }, { data: billingHistory, error: billingError }] = await Promise.all([
      supabaseAdmin
        .from('companies')
        .select('subscription_status, subscription_end_date, subscription_plan_id')
        .eq('id', user.company_id)
        .maybeSingle(),
      supabaseAdmin
        .from('billing_history')
        .select('*')
        .eq('company_id', user.company_id)
        .order('billing_date', { ascending: false }),
    ]);

    if (companyError || !company) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    if (billingError) {
      return NextResponse.json({ error: 'Failed to fetch billing history' }, { status: 500 });
    }

    const { data: currentPlan } = company.subscription_plan_id
      ? await supabaseAdmin
          .from('subscription_plans')
          .select('*')
          .eq('id', company.subscription_plan_id)
          .maybeSingle()
      : { data: null as any };

    return NextResponse.json({
      billingHistory: (billingHistory || []).map((b) => ({
        id: b.id,
        companyId: b.company_id,
        planId: b.plan_id,
        planName: b.plan_name,
        amount: b.amount,
        billingCycle: b.billing_cycle,
        status: b.status,
        billingDate: b.billing_date,
        nextBillingDate: b.next_billing_date,
        description: b.description,
        createdAt: b.created_at,
      })),
      currentPlan: currentPlan
        ? {
            id: currentPlan.id,
            name: currentPlan.name,
            description: currentPlan.description,
            price: currentPlan.price,
            billingCycle: currentPlan.billing_cycle,
            maxUsers: currentPlan.max_users,
            maxReceiptsPerMonth: currentPlan.max_receipts_per_month,
            features: currentPlan.features || [],
            isActive: currentPlan.is_active,
          }
        : null,
      company: {
        subscriptionStatus: company.subscription_status,
        subscriptionEndDate: company.subscription_end_date,
      },
    });
  } catch (error) {
    console.error('Billing history error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
