import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';

// GET /api/company/subscription-status
// Returns current subscription status for the company
export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context?.user;
    if (!user?.company_id) {
      return NextResponse.json(
        { error: 'Company not found' },
        { status: 404 }
      );
    }

    // Fetch subscription status from backend
    const backendUrl = new URL('http://localhost:4000/api/company/subscription-status');
    const response = await fetch(backendUrl.toString(), {
      headers: {
        'Authorization': request.headers.get('authorization') || '',
      },
    });

    if (!response.ok) {
      throw new Error('Failed to fetch subscription status from backend');
    }

    const data = await response.json();
    return NextResponse.json(data);

  } catch (error: any) {
    console.error('Error getting subscription status:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
