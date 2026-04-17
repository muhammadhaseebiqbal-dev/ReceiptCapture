import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';
import { hashPassword } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

interface RouteParams {
  params: { id: string };
}

export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const authResult = await requireAuth(request, ['company_representative', 'master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const currentUser = authResult.context!.user;
    const { id } = params;

    const { data: staff, error: findError } = await supabaseAdmin
      .from('users')
      .select('id, email, name, role, company_id, is_active, created_by, created_at')
      .eq('id', id)
      .in('role', ['manager', 'employee'])
      .maybeSingle();

    if (findError || !staff) {
      return NextResponse.json({ error: 'Staff user not found' }, { status: 404 });
    }

    if (currentUser.role === 'company_representative' && staff.company_id !== currentUser.company_id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const { email, name, role, isActive, password } = await request.json();

    if (email && !isValidEmail(email)) {
      return NextResponse.json({ error: 'Invalid email format' }, { status: 400 });
    }

    if (role && !['manager', 'employee'].includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
    }

    if (email && email.toLowerCase() !== staff.email.toLowerCase()) {
      const { data: existing } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase())
        .neq('id', id)
        .maybeSingle();

      if (existing) {
        return NextResponse.json({ error: 'Email already exists' }, { status: 400 });
      }
    }

    const updates: Record<string, any> = {};
    if (email !== undefined) updates.email = email.toLowerCase();
    if (name !== undefined) updates.name = name;
    if (role !== undefined) updates.role = role;
    if (isActive !== undefined) updates.is_active = isActive;
    if (password !== undefined && password !== '') {
      updates.password_hash = await hashPassword(password);
    }

    const { data: updatedStaff, error: updateError } = await supabaseAdmin
      .from('users')
      .update(updates)
      .eq('id', id)
      .select('id, email, name, role, company_id, is_active, created_by, created_at')
      .single();

    if (updateError || !updatedStaff) {
      return NextResponse.json({ error: 'Failed to update staff user' }, { status: 500 });
    }

    return NextResponse.json({
      staff: {
        id: updatedStaff.id,
        email: updatedStaff.email,
        name: updatedStaff.name,
        role: updatedStaff.role,
        companyId: updatedStaff.company_id,
        isActive: updatedStaff.is_active,
        createdBy: updatedStaff.created_by,
        createdAt: updatedStaff.created_at,
      },
      message: 'Staff user updated successfully',
    });
  } catch (error) {
    console.error('Update staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const authResult = await requireAuth(request, ['company_representative', 'master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const currentUser = authResult.context!.user;
    const { id } = params;

    const { data: staff, error: findError } = await supabaseAdmin
      .from('users')
      .select('id, company_id')
      .eq('id', id)
      .in('role', ['manager', 'employee'])
      .maybeSingle();

    if (findError || !staff) {
      return NextResponse.json({ error: 'Staff user not found' }, { status: 404 });
    }

    if (currentUser.role === 'company_representative' && staff.company_id !== currentUser.company_id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const { error: deleteError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', id);

    if (deleteError) {
      return NextResponse.json({ error: 'Failed to delete staff user' }, { status: 500 });
    }

    return NextResponse.json({ message: 'Staff user deleted successfully' });
  } catch (error) {
    console.error('Delete staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
