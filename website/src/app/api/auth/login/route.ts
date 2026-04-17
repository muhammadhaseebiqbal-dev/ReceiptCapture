import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { verifyPassword, generateToken } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    // Validation
    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required' },
        { status: 400 }
      );
    }

    if (!isValidEmail(email)) {
      return NextResponse.json(
        { error: 'Invalid email format' },
        { status: 400 }
      );
    }

    // Find user in Supabase (representatives table)
    console.log('🔍 Looking up user:', email);
    const { data: user, error: userError } = await supabaseAdmin
      .from('representatives')
      .select('*')
      .eq('email', email)
      .maybeSingle();

    console.log('👤 User found:', user ? 'YES' : 'NO');
    console.log('❌ Error:', userError?.message || 'none');

    if (userError || !user) {
      console.log('⚠️ User not found or error occurred');
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    console.log('🔐 User details:', {
      id: user.id,
      email: user.email,
      role: user.role,
      is_active: user.is_active,
      password_hash_length: user.password_hash?.length || 0
    });

    // Validate password
    console.log('🔑 Verifying password...');
    const isValidPassword = await verifyPassword(password, user.password_hash);
    console.log('✅ Password valid:', isValidPassword);
    
    if (!isValidPassword) {
      console.log('⚠️ Password verification failed');
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Check if user is active
    if (!user.is_active) {
      return NextResponse.json(
        { error: 'Account is inactive. Please contact support.' },
        { status: 403 }
      );
    }

    // Generate JWT token
    const token = generateToken(user.id, user.email, user.role, user.company_id);

    // Return user data (without password hash) and token
    const userData = {
      id: user.id,
      email: user.email,
      name: `${user.first_name} ${user.last_name}`,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
      companyId: user.company_id,
      jobTitle: user.job_title,
      isActive: user.is_active,
      emailVerified: user.email_verified,
      verifiedEmail: user.verified_email,
      isPrimary: user.is_primary
    };
    
    return NextResponse.json({
      user: userData,
      token,
      message: 'Login successful'
    });

  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}