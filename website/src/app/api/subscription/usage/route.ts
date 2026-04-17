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

    const [{ data: company }, { data: staffUsers, error: staffError }, { data: receipts, error: receiptsError }] = await Promise.all([
      supabaseAdmin
        .from('companies')
        .select('subscription_status, subscription_end_date, subscription_plan_id')
        .eq('id', user.company_id)
        .maybeSingle(),
      supabaseAdmin
        .from('users')
        .select('id, is_active')
        .eq('company_id', user.company_id)
        .in('role', ['manager', 'employee']),
      supabaseAdmin
        .from('receipts')
        .select('id, amount, created_at')
        .eq('company_id', user.company_id),
    ]);

    if (staffError || receiptsError || !company) {
      return NextResponse.json({ error: 'Failed to load usage analytics' }, { status: 500 });
    }

    const { data: currentPlan } = company.subscription_plan_id
      ? await supabaseAdmin
          .from('subscription_plans')
          .select('*')
          .eq('id', company.subscription_plan_id)
          .maybeSingle()
      : { data: null as any };

    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();

    const receiptsThisMonth = (receipts || []).filter((receipt) => {
      const receiptDate = new Date(receipt.created_at);
      return receiptDate.getMonth() === currentMonth && receiptDate.getFullYear() === currentYear;
    });

    const monthlyUsage = [] as Array<{ month: string; receipts: number; amount: number }>;
    for (let i = 5; i >= 0; i--) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);
      const month = date.getMonth();
      const year = date.getFullYear();

      const monthReceipts = (receipts || []).filter((receipt) => {
        const receiptDate = new Date(receipt.created_at);
        return receiptDate.getMonth() === month && receiptDate.getFullYear() === year;
      });

      monthlyUsage.push({
        month: date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
        receipts: monthReceipts.length,
        amount: monthReceipts.reduce((sum, r) => sum + Number(r.amount || 0), 0),
      });
    }

    const limits = {
      maxUsers: currentPlan?.max_users || 5,
      maxReceipts: currentPlan?.max_receipts_per_month || 100,
      maxStorage: 1000,
    };

    const activeStaffCount = (staffUsers || []).filter((u) => u.is_active).length;

    const usage = {
      staffCount: (staffUsers || []).length,
      activeStaffCount,
      receiptsThisMonth: receiptsThisMonth.length,
      totalReceipts: (receipts || []).length,
      storageUsed: (receipts || []).length * 0.5,
      limits,
      monthlyUsage,
      usagePercentage: {
        users: Math.round((((staffUsers || []).length || 0) / limits.maxUsers) * 100),
        receipts: Math.round((receiptsThisMonth.length / limits.maxReceipts) * 100),
        storage: Math.round((((receipts || []).length * 0.5) / limits.maxStorage) * 100),
      },
    };

    return NextResponse.json({
      usage,
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
    console.error('Usage analytics error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
