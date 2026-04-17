import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

// GET - Fetch all subscription plans (PUBLIC - no auth required for landing page)
export async function GET(request: NextRequest) {
  try {
    const response = await fetch('http://localhost:4000/api/subscription-plans', {
      headers: {
        Authorization: request.headers.get('authorization') || '',
      },
    });

    const payload = await response.json();
    return NextResponse.json(payload.plans || [], { status: response.status });

  } catch (error: any) {
    console.error('Error fetching plans:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}

// POST - Create a new subscription plan
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, '/api/subscription-plans', 'POST', body);

  } catch (error: any) {
    console.error('Error creating plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
