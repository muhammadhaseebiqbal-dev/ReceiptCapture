import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';
import { hashPassword } from '@/lib/auth';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    // Hash the password
    const hashedPassword = await hashPassword(password);

    // Update the user's password in the database
    const { data, error } = await supabaseAdmin
      .from('users')
      .update({ password_hash: hashedPassword })
      .eq('email', email)
      .select();

    if (error) {
      return NextResponse.json({
        success: false,
        error: 'Database error',
        details: error.message
      }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      message: 'Password updated successfully',
      email: email,
      newHash: hashedPassword
    });

  } catch (error: any) {
    return NextResponse.json({
      success: false,
      error: 'Failed to update password',
      details: error.message
    }, { status: 500 });
  }
}
