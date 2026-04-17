import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { generateToken, hashPassword } from '@/lib/auth';

interface RegistrationRequest {
  // Company Information
  companyName: string;
  companyDomain?: string;
  destinationEmail: string;
  
  // Representative Information
  representativeName: string;
  representativeEmail: string;
  representativePassword: string;
  
  // Subscription
  selectedPlanId: string;
}

export async function POST(request: NextRequest) {
  try {
    const {
      companyName,
      companyDomain,
      destinationEmail,
      representativeName,
      representativeEmail,
      representativePassword,
      selectedPlanId,
    }: RegistrationRequest = await request.json();

    // Validation
    if (!companyName || !destinationEmail || !representativeName || !representativeEmail || !representativePassword || !selectedPlanId) {
      return NextResponse.json(
        { error: 'All required fields must be provided' },
        { status: 400 }
      );
    }

    // Check if user already exists
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', representativeEmail)
      .maybeSingle();

    if (existingUser) {
      return NextResponse.json(
        { error: 'A user with this email already exists' },
        { status: 400 }
      );
    }

    // Validate subscription plan
    const { data: subscriptionPlan, error: planError } = await supabaseAdmin
      .from('subscription_plans')
      .select('id, name, billing_cycle')
      .eq('id', selectedPlanId)
      .eq('is_active', true)
      .maybeSingle();

    if (planError) {
      return NextResponse.json(
        { error: 'Failed to verify subscription plan' },
        { status: 500 }
      );
    }

    if (!subscriptionPlan) {
      return NextResponse.json(
        { error: 'Invalid subscription plan selected' },
        { status: 400 }
      );
    }

    const now = new Date();

    // Calculate subscription end date (30 days trial)
    const subscriptionEndDate = new Date(now);
    subscriptionEndDate.setDate(subscriptionEndDate.getDate() + 30);

    // Create company
    const { data: company, error: companyError } = await supabaseAdmin
      .from('companies')
      .insert({
        name: companyName,
        domain: companyDomain || null,
        destination_email: destinationEmail.toLowerCase(),
        subscription_plan_id: selectedPlanId,
        subscription_status: 'trial',
        subscription_start_date: now.toISOString(),
        subscription_end_date: subscriptionEndDate.toISOString(),
      })
      .select('id, name, destination_email, subscription_status')
      .single();

    if (companyError || !company) {
      return NextResponse.json(
        { error: 'Failed to create company' },
        { status: 500 }
      );
    }

    const passwordHash = await hashPassword(representativePassword);

    // Create company representative user
    const { data: user, error: userCreateError } = await supabaseAdmin
      .from('users')
      .insert({
        email: representativeEmail.toLowerCase(),
        password_hash: passwordHash,
        name: representativeName,
        role: 'company_representative',
        company_id: company.id,
        is_active: true,
      })
      .select('id, email, name, role, company_id')
      .single();

    if (userCreateError || !user) {
      return NextResponse.json(
        { error: 'Failed to create representative account' },
        { status: 500 }
      );
    }

    // Optional billing history write if table exists
    await supabaseAdmin
      .from('billing_history')
      .insert({
        company_id: company.id,
        plan_id: selectedPlanId,
        plan_name: subscriptionPlan.name,
        amount: 0,
        billing_cycle: subscriptionPlan.billing_cycle,
        status: 'paid',
        billing_date: now.toISOString(),
        next_billing_date: subscriptionEndDate.toISOString(),
        description: `30-day trial for ${subscriptionPlan.name} plan`,
      });

    // Generate authentication token
    const token = generateToken(user.id, user.email, user.role, user.company_id);

    return NextResponse.json({
      success: true,
      message: 'Company registration successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.company_id,
      },
      company: {
        id: company.id,
        name: company.name,
        destinationEmail: company.destination_email,
        subscriptionStatus: company.subscription_status,
      },
      token,
      subscriptionPlan: {
        name: subscriptionPlan.name,
        trialEndDate: subscriptionEndDate.toISOString(),
      },
    });

  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { error: 'Internal server error during registration' },
      { status: 500 }
    );
  }
}
