import { NextRequest, NextResponse } from 'next/server';

const backendBaseUrl = process.env.BACKEND_API_URL || 'http://localhost:4000';

export async function proxyJsonRequest(
  request: NextRequest,
  path: string,
  method: string,
  body?: unknown
) {
  const headers = new Headers();
  headers.set('Content-Type', 'application/json');

  const authorization = request.headers.get('authorization');
  if (authorization) {
    headers.set('Authorization', authorization);
  }

  const response = await fetch(`${backendBaseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await response.text();
  const contentType = response.headers.get('content-type') || 'application/json';

  return new NextResponse(text, {
    status: response.status,
    headers: {
      'Content-Type': contentType,
    },
  });
}