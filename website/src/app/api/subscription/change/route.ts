import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, '/api/company/change-plan', 'POST', body);
  } catch (error) {
    console.error('Subscription change error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
