import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    return await proxyJsonRequest(request, '/api/admin/stats', 'GET');
  } catch (error) {
    console.error('Error fetching admin stats:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
