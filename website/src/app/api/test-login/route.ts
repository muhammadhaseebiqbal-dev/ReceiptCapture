import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { verifyPassword, hashPassword } from '@/lib/auth';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    // Get user from database
    const { data: user, error } = await supabaseAdmin
      .from('portal_users')
      .select('*')
      .eq('email', email)
      .maybeSingle();

    if (error) {
      return NextResponse.json({
        success: false,
        error: 'Database error',
        details: error.message
      }, { status: 500 });
    }

    if (!user) {
      return NextResponse.json({
        success: false,
        error: 'User not found',
        email: email
      }, { status: 404 });
    }

    // Test password verification
    const isValid = await verifyPassword(password, user.password_hash);

    // Generate a test hash for comparison
    const testHash = await hashPassword(password);

    return NextResponse.json({
      success: true,
      user: {
        email: user.email,
        name: user.name,
        role: user.role
      },
      passwordTest: {
        providedPassword: password,
        storedHash: user.password_hash,
        isValidPassword: isValid,
        testHash: testHash
      }
    });

  } catch (error: any) {
    return NextResponse.json({
      success: false,
      error: 'Test failed',
      details: error.message
    }, { status: 500 });
  }
}
