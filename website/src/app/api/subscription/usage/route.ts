import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function GET(request: NextRequest) {
  try {
    const response = await proxyJsonRequest(request, '/api/company/settings', 'GET');
    const payload = await response.json();
    return NextResponse.json(
      {
        usage: payload.usage || null,
        currentPlan: payload.subscriptionPlan || null,
        company: payload.company
          ? {
              subscriptionStatus: payload.company.subscriptionStatus,
              subscriptionEndDate: payload.company.subscriptionEndDate,
            }
          : null,
      },
      { status: response.status }
    );
  } catch (error) {
    console.error('Usage analytics error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
