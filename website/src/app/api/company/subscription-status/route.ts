import { NextRequest, NextResponse } from 'next/server';

const BACKEND_API_URL = process.env.BACKEND_API_URL || 'http://localhost:4000';

// GET /api/company/subscription-status
// Returns current subscription status for the company
export async function GET(request: NextRequest) {
  try {
    const authorization = request.headers.get('authorization') || '';
    if (!authorization) {
      return NextResponse.json(
        { error: 'Authentication required' },
        { status: 401 }
      );
    }

    const response = await fetch(`${BACKEND_API_URL}/api/company/subscription-status`, {
      headers: {
        Authorization: authorization,
      },
    });

    const payload = await response.text();
    const contentType = response.headers.get('content-type') || 'application/json';

    return new NextResponse(payload, {
      status: response.status,
      headers: {
        'Content-Type': contentType,
      },
    });

  } catch (error: any) {
    console.error('Error getting subscription status:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
