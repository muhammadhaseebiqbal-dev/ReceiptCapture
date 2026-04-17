import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { requireAuth } from '@/lib/api-auth';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const { data: companies, error } = await supabaseAdmin
      .from('companies')
      .select(`
        *,
        subscription_plan:subscription_plans(
          id,
          name,
          price,
          billing_cycle,
          max_users,
          max_receipts_per_month
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      return NextResponse.json({ error: 'Failed to fetch companies' }, { status: 500 });
    }

    const companiesWithCounts = await Promise.all(
      (companies || []).map(async (company: any) => {
        const { count: userCount } = await supabaseAdmin
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id);

        const { count: receiptCount } = await supabaseAdmin
          .from('receipts')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id);

        return {
          ...company,
          user_count: userCount || 0,
          receipt_count: receiptCount || 0,
        };
      })
    );

    return NextResponse.json(companiesWithCounts);
  } catch (error) {
    console.error('Error fetching companies:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const body = await request.json();
    const {
      name,
      domain,
      destination_email,
      subscription_plan_id,
      subscription_status,
      subscription_start_date,
      subscription_end_date,
    } = body;

    if (!name || !subscription_plan_id) {
      return NextResponse.json({ error: 'Name and subscription plan are required' }, { status: 400 });
    }

    const { data: company, error } = await supabaseAdmin
      .from('companies')
      .insert({
        name,
        domain,
        destination_email,
        subscription_plan_id,
        subscription_status: subscription_status || 'trial',
        subscription_start_date: subscription_start_date || new Date().toISOString(),
        subscription_end_date,
      })
      .select('*')
      .single();

    if (error) {
      return NextResponse.json({ error: 'Failed to create company' }, { status: 500 });
    }

    return NextResponse.json(company, { status: 201 });
  } catch (error) {
    console.error('Error creating company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
