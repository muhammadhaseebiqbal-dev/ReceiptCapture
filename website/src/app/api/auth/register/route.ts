import { NextRequest, NextResponse } from 'next/server';
import { registerCompanyRepresentative } from '@/lib/auth-operations';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const result = await registerCompanyRepresentative(body);

    if ('error' in result) {
      return NextResponse.json({ error: result.error }, { status: result.status });
    }

    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { error: 'Internal server error during registration' },
      { status: 500 }
    );
  }
}