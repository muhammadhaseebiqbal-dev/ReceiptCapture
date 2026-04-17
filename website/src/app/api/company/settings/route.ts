import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    const response = await fetch('http://localhost:4000/api/company/settings', {
      headers: {
        Authorization: request.headers.get('authorization') || '',
      },
    });

    const payload = await response.json();
    return NextResponse.json(payload, { status: response.status });
  } catch (error) {
    console.error('Get company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, '/api/company/settings', 'PUT', body);
  } catch (error) {
    console.error('Update company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
