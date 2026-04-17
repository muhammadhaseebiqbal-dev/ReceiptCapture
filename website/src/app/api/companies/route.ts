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

    // Fetch companies with their subscription plan details and user counts
    const { data: companies, error } = await supabaseAdmin
      .from('registered_companies')
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
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to fetch companies' }, { status: 500 });
    }

    // For each company, get the user count
    const companiesWithCounts = await Promise.all(
      companies.map(async (company) => {
        // Count representatives
        const { count: repCount } = await supabaseAdmin
          .from('representatives')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id);

        // Count members
        const { count: memberCount } = await supabaseAdmin
          .from('members')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id);

        const { count: receiptCount } = await supabaseAdmin
          .from('receipts')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', company.id);

        return {
          ...company,
          representative_count: repCount || 0,
          member_count: memberCount || 0,
          total_user_count: (repCount || 0) + (memberCount || 0),
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
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');

    if (!token) {
      return NextResponse.json({ error: 'Authentication required' }, { status: 401 });
    }

    const decoded = verifyToken(token);
    if (!decoded || decoded.role !== 'master_admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const body = await request.json();
    const {
      name,
      domain,
      industry,
      company_size,
      address,
      phone,
      website,
      subscription_plan_id,
      subscription_status,
      subscription_start_date,
      subscription_end_date,
    } = body;

    // Validation
    if (!name || !subscription_plan_id) {
      return NextResponse.json(
        { error: 'Name and subscription plan are required' },
        { status: 400 }
      );
    }

    const { data: company, error } = await supabaseAdmin
      .from('registered_companies')
      .insert({
        name,
        domain,
        industry,
        company_size,
        address,
        phone,
        website,
        current_plan_id: subscription_plan_id,
        subscription_status: subscription_status || 'trial',
        subscription_start_date: subscription_start_date || new Date().toISOString(),
        subscription_end_date,
      })
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to create company' }, { status: 500 });
    }

    return NextResponse.json(company, { status: 201 });
  } catch (error) {
    console.error('Error creating company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
