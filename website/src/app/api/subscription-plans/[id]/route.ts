import { NextRequest, NextResponse } from 'next/server';
import { proxyJsonRequest } from '@/lib/backend-proxy';

// PUT - Update a subscription plan
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    return await proxyJsonRequest(request, `/api/subscription-plans/${id}`, 'PUT', body);
  } catch (error: any) {
    console.error('Error updating plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}

// DELETE - Delete a subscription plan
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    return await proxyJsonRequest(request, `/api/subscription-plans/${id}`, 'DELETE');
  } catch (error: any) {
    console.error('Error deleting plan:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
