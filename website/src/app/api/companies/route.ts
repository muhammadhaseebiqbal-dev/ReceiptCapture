import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    return await proxyJsonRequest(request, '/api/companies', 'GET');
  } catch (error) {
    console.error('Error fetching companies:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, '/api/companies', 'POST', body);
  } catch (error) {
    console.error('Error creating company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
