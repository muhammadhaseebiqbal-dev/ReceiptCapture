import { NextRequest, NextResponse } from 'next/server';
const BACKEND_API_URL = process.env.BACKEND_API_URL || 'http://localhost:4000';

export async function GET(request: NextRequest) {
  try {
    const backendUrl = new URL(`${BACKEND_API_URL}/api/receipts`);
    const incomingUrl = new URL(request.url);
    incomingUrl.searchParams.forEach((value, key) => {
      backendUrl.searchParams.set(key, value);
    });

    const response = await fetch(backendUrl.toString(), {
      headers: {
        Authorization: request.headers.get('authorization') || '',
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
  } catch (error) {
    console.error('Receipts fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
