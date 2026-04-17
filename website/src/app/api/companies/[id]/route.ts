import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { verifyToken } from '@/lib/auth';

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
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
      destination_email,
      subscription_plan_id,
      subscription_status,
      subscription_start_date,
      subscription_end_date,
    } = body;

    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (destination_email !== undefined) updateData.destination_email = destination_email;
    if (subscription_plan_id !== undefined) updateData.subscription_plan_id = subscription_plan_id;
    if (subscription_status !== undefined) updateData.subscription_status = subscription_status;
    if (subscription_start_date !== undefined) updateData.subscription_start_date = subscription_start_date;
    if (subscription_end_date !== undefined) updateData.subscription_end_date = subscription_end_date;

    const { data: company, error } = await supabaseAdmin
      .from('companies')
      .update(updateData)
      .eq('id', params.id)
      .select()
      .single();

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to update company' }, { status: 500 });
    }

    return NextResponse.json(company);
  } catch (error) {
    console.error('Error updating company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
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

    // Check if company has users
    const { count: userCount } = await supabaseAdmin
      .from('portal_users')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', params.id);

    if (userCount && userCount > 0) {
      return NextResponse.json(
        { error: `Cannot delete company with ${userCount} users. Please remove users first.` },
        { status: 400 }
      );
    }

    const { error } = await supabaseAdmin
      .from('companies')
      .delete()
      .eq('id', params.id);

    if (error) {
      console.error('Database error:', error);
      return NextResponse.json({ error: 'Failed to delete company' }, { status: 500 });
    }

    return NextResponse.json({ message: 'Company deleted successfully' });
  } catch (error) {
    console.error('Error deleting company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
