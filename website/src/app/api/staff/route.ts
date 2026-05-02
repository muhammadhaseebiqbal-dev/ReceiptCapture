import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    return await proxyJsonRequest(request, '/api/staff', 'GET');
  } catch (error) {
    console.error('Get staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, '/api/staff', 'POST', body);
  } catch (error) {
    console.error('Create staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
