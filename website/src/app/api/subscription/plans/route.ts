import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (authResult.response) {
      return authResult.response;
    }

    const { data: plans, error } = await supabaseAdmin
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('price', { ascending: true });

    if (error) {
      return NextResponse.json({ error: 'Failed to fetch subscription plans' }, { status: 500 });
    }

    return NextResponse.json({
      plans: (plans || []).map((plan) => ({
        id: plan.id,
        name: plan.name,
        description: plan.description,
        price: plan.price,
        billingCycle: plan.billing_cycle,
        maxUsers: plan.max_users,
        maxReceiptsPerMonth: plan.max_receipts_per_month,
        features: plan.features || [],
        isActive: plan.is_active,
      })),
    });
  } catch (error) {
    console.error('Get subscription plans error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
