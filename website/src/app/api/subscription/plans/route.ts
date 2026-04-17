import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const response = await fetch('http://localhost:4000/api/subscription-plans', {
      headers: {
        Authorization: request.headers.get('authorization') || '',
      },
    });

    const payload = await response.json();
    return NextResponse.json(payload, { status: response.status });

  } catch (error) {
    console.error('Get subscription plans error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
