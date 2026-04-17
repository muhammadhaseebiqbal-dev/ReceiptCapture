import { NextRequest, NextResponse } from 'next/server';
import { loginStaffUser } from '@/lib/auth-operations';

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();
    const result = await loginStaffUser(email, password);

    if ('error' in result) {
      return NextResponse.json({ error: result.error }, { status: result.status });
    }

    return NextResponse.json({
      user: result.user,
      token: result.token,
      tokenPayload: result.tokenPayload,
      message: 'Login successful',
    });
  } catch (error) {
    console.error('Staff login error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}