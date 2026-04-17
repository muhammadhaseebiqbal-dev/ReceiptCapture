import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { requireAuth } from '@/lib/api-auth';

// GET - Fetch all subscription plans (PUBLIC - no auth required for landing page)
export async function GET(request: NextRequest) {
  try {
    // Check if request has authorization header (for admin use)
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');
    let isAdmin = false;

    // If token is provided, verify and check admin role
    if (token) {
      const authResult = await requireAuth(request, ['master_admin']);
      if (!authResult.response) {
        isAdmin = true;
      }
    }

    // Fetch subscription plans
    // If admin, show all plans. If public, only show active plans
    let query = supabaseAdmin
      .from('subscription_plans')
      .select('*')
      .order('price', { ascending: true });

    if (!isAdmin) {
      // Public users only see active plans
      query = query.eq('is_active', true);
    }

    const { data: plans, error } = await query;

    if (error) {
      return NextResponse.json(
        { error: 'Failed to fetch plans', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(plans || []);

  } catch (error: any) {
    console.error('Error fetching plans:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}

// POST - Create a new subscription plan
export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const body = await request.json();
    const { name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active } = body;

    // Validation
    if (!name || !price || !billing_cycle || !max_users) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Insert new plan
    const { data, error } = await supabaseAdmin
      .from('subscription_plans')
      .insert({
        name,
        description,
        price: parseFloat(price),
        billing_cycle,
        max_users: parseInt(max_users),
        max_receipts_per_month: max_receipts_per_month ? parseInt(max_receipts_per_month) : null,
        features: features || {},
        is_active: is_active !== undefined ? is_active : true
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json(
        { error: 'Failed to create plan', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Plan created successfully',
      plan: data
    }, { status: 201 });

  } catch (error: any) {
    console.error('Error creating plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
