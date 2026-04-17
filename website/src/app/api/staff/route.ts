import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';
import { hashPassword } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative', 'master_admin']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    const { searchParams } = new URL(request.url);
    const requestedCompanyId = searchParams.get('companyId');

    let query = supabaseAdmin
      .from('users')
      .select('id, email, name, role, company_id, is_active, created_by, created_at')
      .in('role', ['manager', 'employee'])
      .order('created_at', { ascending: false });

    if (user.role === 'company_representative') {
      query = query.eq('company_id', user.company_id);
    } else if (requestedCompanyId) {
      query = query.eq('company_id', requestedCompanyId);
    }

    const { data: staff, error } = await query;

    if (error) {
      return NextResponse.json({ error: 'Failed to fetch staff users' }, { status: 500 });
    }

    return NextResponse.json({
      staff: (staff || []).map((s) => ({
        id: s.id,
        email: s.email,
        name: s.name,
        companyId: s.company_id,
        role: s.role,
        isActive: s.is_active,
        createdBy: s.created_by,
        createdAt: s.created_at,
      })),
    });
  } catch (error) {
    console.error('Get staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const currentUser = authResult.context!.user;
    if (!currentUser.company_id) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    const { email, name, role, password } = await request.json();

    if (!email || !name || !role || !password) {
      return NextResponse.json({ error: 'All fields are required' }, { status: 400 });
    }

    if (!isValidEmail(email)) {
      return NextResponse.json({ error: 'Invalid email format' }, { status: 400 });
    }

    if (!['manager', 'employee'].includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
    }

    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email.toLowerCase())
      .maybeSingle();

    if (existingUser) {
      return NextResponse.json({ error: 'Email already exists' }, { status: 400 });
    }

    const passwordHash = await hashPassword(password);

    const { data: newStaff, error } = await supabaseAdmin
      .from('users')
      .insert({
        email: email.toLowerCase(),
        name,
        role,
        password_hash: passwordHash,
        company_id: currentUser.company_id,
        is_active: true,
        created_by: currentUser.id,
      })
      .select('id, email, name, role, company_id, is_active, created_by, created_at')
      .single();

    if (error || !newStaff) {
      return NextResponse.json({ error: 'Failed to create staff user' }, { status: 500 });
    }

    return NextResponse.json(
      {
        staff: {
          id: newStaff.id,
          email: newStaff.email,
          name: newStaff.name,
          role: newStaff.role,
          companyId: newStaff.company_id,
          isActive: newStaff.is_active,
          createdBy: newStaff.created_by,
          createdAt: newStaff.created_at,
        },
        message: 'Staff user created successfully',
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('Create staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
