import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json();
    return await proxyJsonRequest(request, `/api/companies/${params.id}`, 'PUT', body);
  } catch (error) {
    console.error('Error updating company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    return await proxyJsonRequest(request, `/api/companies/${params.id}`, 'DELETE');
  } catch (error) {
    console.error('Error deleting company:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
