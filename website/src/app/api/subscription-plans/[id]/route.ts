import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { requireAuth } from '@/lib/api-auth';

// PUT - Update a subscription plan
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authResult = await requireAuth(request, ['master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const body = await request.json();
    const { name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active } = body;

    // Build update object
    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (price !== undefined) updateData.price = parseFloat(price);
    if (billing_cycle !== undefined) updateData.billing_cycle = billing_cycle;
    if (max_users !== undefined) updateData.max_users = parseInt(max_users);
    if (max_receipts_per_month !== undefined) updateData.max_receipts_per_month = max_receipts_per_month ? parseInt(max_receipts_per_month) : null;
    if (features !== undefined) updateData.features = features;
    if (is_active !== undefined) updateData.is_active = is_active;

    // Update plan
    const { data, error } = await supabaseAdmin
      .from('subscription_plans')
      .update(updateData)
      .eq('id', params.id)
      .select()
      .single();

    if (error) {
      return NextResponse.json(
        { error: 'Failed to update plan', details: error.message },
        { status: 500 }
      );
    }

    if (!data) {
      return NextResponse.json(
        { error: 'Plan not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Plan updated successfully',
      plan: data
    });

  } catch (error: any) {
    console.error('Error updating plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}

// DELETE - Delete a subscription plan
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authResult = await requireAuth(request, ['master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    // Check if plan is in use by any companies
    const { data: companiesUsingPlan } = await supabaseAdmin
      .from('companies')
      .select('id')
      .eq('subscription_plan_id', params.id)
      .limit(1);

    if (companiesUsingPlan && companiesUsingPlan.length > 0) {
      return NextResponse.json(
        { error: 'Cannot delete plan that is in use by companies. Deactivate it instead.' },
        { status: 400 }
      );
    }

    // Delete plan
    const { error } = await supabaseAdmin
      .from('subscription_plans')
      .delete()
      .eq('id', params.id);

    if (error) {
      return NextResponse.json(
        { error: 'Failed to delete plan', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Plan deleted successfully'
    });

  } catch (error: any) {
    console.error('Error deleting plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
