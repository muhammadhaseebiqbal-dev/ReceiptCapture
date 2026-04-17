import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { verifyToken } from '@/lib/auth';

export async function GET(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');

    if (!token) {
      return NextResponse.json({ error: 'Authentication required' }, { status: 401 });
    }

    const decoded = verifyToken(token);
    if (!decoded || decoded.role !== 'master_admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    // Get total companies
    const { count: totalCompanies } = await supabaseAdmin
      .from('registered_companies')
      .select('*', { count: 'exact', head: true });

    // Get active companies
    const { count: activeCompanies } = await supabaseAdmin
      .from('registered_companies')
      .select('*', { count: 'exact', head: true })
      .eq('subscription_status', 'active');

    // Get trial companies
    const { count: trialCompanies } = await supabaseAdmin
      .from('registered_companies')
      .select('*', { count: 'exact', head: true })
      .eq('subscription_status', 'trial');

    // Get total users (representatives + members)
    const { count: representatives } = await supabaseAdmin
      .from('representatives')
      .select('*', { count: 'exact', head: true });

    const { count: members } = await supabaseAdmin
      .from('members')
      .select('*', { count: 'exact', head: true });

    // Calculate monthly revenue
    const { data: companies } = await supabaseAdmin
      .from('registered_companies')
      .select(`
        subscription_status,
        subscription_plan:subscription_plans!current_plan_id(price, billing_cycle)
      `)
      .eq('subscription_status', 'active');

    let monthlyRevenue = 0;
    if (companies) {
      monthlyRevenue = companies.reduce((sum, company: any) => {
        if (company.subscription_plan) {
          const price = company.subscription_plan.price;
          const cycle = company.subscription_plan.billing_cycle;
          // Convert annual to monthly
          const monthlyPrice = cycle === 'annual' ? price / 12 : price;
          return sum + monthlyPrice;
        }
        return sum;
      }, 0);
    }

    // Get active plans count
    const { count: activePlans } = await supabaseAdmin
      .from('subscription_plans')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true);

    // Get total receipts processed
    const { count: totalReceipts } = await supabaseAdmin
      .from('receipts')
      .select('*', { count: 'exact', head: true });

    const stats = {
      totalCompanies: totalCompanies || 0,
      activeCompanies: activeCompanies || 0,
      trialCompanies: trialCompanies || 0,
      totalUsers: (representatives || 0) + (members || 0),
      totalRepresentatives: representatives || 0,
      totalMembers: members || 0,
      monthlyRevenue,
      activePlans: activePlans || 0,
      totalReceipts: totalReceipts || 0,
    };

    return NextResponse.json(stats);
  } catch (error) {
    console.error('Error fetching admin stats:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
