import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const response = await fetch('http://localhost:4000/api/company/settings', {
      headers: {
        Authorization: request.headers.get('authorization') || '',
      },
    });

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
