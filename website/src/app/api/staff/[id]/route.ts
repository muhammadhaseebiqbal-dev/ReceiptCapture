import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;
    const body = await request.json();
    return await proxyJsonRequest(request, `/api/staff/${id}`, 'PUT', body);
  } catch (error) {
    console.error('Update staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;
    return await proxyJsonRequest(request, `/api/staff/${id}`, 'DELETE');
  } catch (error) {
    console.error('Delete staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
