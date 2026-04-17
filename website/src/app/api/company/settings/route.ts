import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';
import { isValidEmail } from '@/lib/utils';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    const { data: company, error: companyError } = await supabaseAdmin
      .from('companies')
      .select('*')
      .eq('id', user.company_id)
      .maybeSingle();

    if (companyError || !company) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    const [{ data: subscriptionPlan }, { count: staffCount }, { count: activeStaffCount }, { count: receiptsThisMonth }] = await Promise.all([
      company.subscription_plan_id
        ? supabaseAdmin
            .from('subscription_plans')
            .select('*')
            .eq('id', company.subscription_plan_id)
            .maybeSingle()
        : Promise.resolve({ data: null as any }),
      supabaseAdmin
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', user.company_id)
        .in('role', ['manager', 'employee']),
      supabaseAdmin
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', user.company_id)
        .in('role', ['manager', 'employee'])
        .eq('is_active', true),
      supabaseAdmin
        .from('receipts')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', user.company_id)
        .gte('created_at', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
    ]);

    return NextResponse.json({
      company: {
        id: company.id,
        name: company.name,
        domain: company.domain,
        destinationEmail: company.destination_email,
        subscriptionPlanId: company.subscription_plan_id,
        subscriptionStatus: company.subscription_status,
        subscriptionStartDate: company.subscription_start_date,
        subscriptionEndDate: company.subscription_end_date,
        createdAt: company.created_at,
        updatedAt: company.updated_at,
      },
      subscriptionPlan: subscriptionPlan
        ? {
            id: subscriptionPlan.id,
            name: subscriptionPlan.name,
            description: subscriptionPlan.description,
            price: subscriptionPlan.price,
            billingCycle: subscriptionPlan.billing_cycle,
            maxUsers: subscriptionPlan.max_users,
            maxReceiptsPerMonth: subscriptionPlan.max_receipts_per_month,
            features: subscriptionPlan.features || [],
            isActive: subscriptionPlan.is_active,
          }
        : null,
      usage: {
        staffCount: staffCount || 0,
        activeStaffCount: activeStaffCount || 0,
        receiptsThisMonth: receiptsThisMonth || 0,
        maxUsers: subscriptionPlan?.max_users || 0,
        maxReceipts: subscriptionPlan?.max_receipts_per_month || 0,
      },
    });
  } catch (error) {
    console.error('Get company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function PUT(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    const { name, destinationEmail, domain } = await request.json();

    if (!destinationEmail || !isValidEmail(destinationEmail)) {
      return NextResponse.json({ error: 'Valid destination email is required' }, { status: 400 });
    }

    if (!name || name.trim().length < 2) {
      return NextResponse.json({ error: 'Company name must be at least 2 characters' }, { status: 400 });
    }

    const { data: updatedCompany, error } = await supabaseAdmin
      .from('companies')
      .update({
        name: name.trim(),
        destination_email: destinationEmail.toLowerCase(),
        domain: domain?.trim() || null,
      })
      .eq('id', user.company_id)
      .select('*')
      .single();

    if (error || !updatedCompany) {
      return NextResponse.json({ error: 'Failed to update company settings' }, { status: 500 });
    }

    return NextResponse.json({
      company: {
        id: updatedCompany.id,
        name: updatedCompany.name,
        domain: updatedCompany.domain,
        destinationEmail: updatedCompany.destination_email,
        subscriptionPlanId: updatedCompany.subscription_plan_id,
        subscriptionStatus: updatedCompany.subscription_status,
        subscriptionStartDate: updatedCompany.subscription_start_date,
        subscriptionEndDate: updatedCompany.subscription_end_date,
        createdAt: updatedCompany.created_at,
        updatedAt: updatedCompany.updated_at,
      },
      message: 'Company settings updated successfully',
    });
  } catch (error) {
    console.error('Update company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
