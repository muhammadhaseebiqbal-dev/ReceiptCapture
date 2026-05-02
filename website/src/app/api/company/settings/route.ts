import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    return await proxyJsonRequest(request, '/api/company/settings', 'GET');
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
