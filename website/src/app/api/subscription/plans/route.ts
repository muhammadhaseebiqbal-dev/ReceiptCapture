import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    return await proxyJsonRequest(request, '/api/subscription-plans', 'GET');

  } catch (error) {
    console.error('Get subscription plans error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
