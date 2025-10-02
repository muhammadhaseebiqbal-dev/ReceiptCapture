import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { verifyToken } from '@/lib/auth';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    // Find the receipt
    const receipt = dataStore.getReceipts().find(r => r.id === params.id && r.companyId === user.companyId);
    
    if (!receipt) {
      return NextResponse.json({ error: 'Receipt not found' }, { status: 404 });
    }

    // Get user information
    const receiptUser = dataStore.getAppUsers().find(u => u.id === receipt.userId);
    
    return NextResponse.json({
      ...receipt,
      userName: receiptUser?.name || 'Unknown User',
      userEmail: receiptUser?.email || '',
    });

  } catch (error) {
    console.error('Receipt fetch error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const { status, notes } = await request.json();

    // Find the receipt
    const receipt = dataStore.getReceipts().find(r => r.id === params.id && r.companyId === user.companyId);
    
    if (!receipt) {
      return NextResponse.json({ error: 'Receipt not found' }, { status: 404 });
    }

    // Update receipt
    const updates: any = {};
    if (status) {
      updates.status = status;
      if (status === 'sent') {
        updates.emailSentAt = new Date().toISOString();
      }
    }
    if (notes !== undefined) {
      updates.notes = notes;
    }

    dataStore.updateReceipt(params.id, updates);

    // Get updated receipt with user info
    const updatedReceipt = dataStore.getReceipts().find(r => r.id === params.id);
    const receiptUser = dataStore.getAppUsers().find(u => u.id === updatedReceipt?.userId);
    
    return NextResponse.json({
      ...updatedReceipt,
      userName: receiptUser?.name || 'Unknown User',
      userEmail: receiptUser?.email || '',
    });

  } catch (error) {
    console.error('Receipt update error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}