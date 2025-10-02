import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { verifyToken } from '@/lib/auth';
import { Receipt } from '@/types';

export async function GET(request: NextRequest) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Get current user and company
    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    // Get query parameters for filtering
    const url = new URL(request.url);
    const searchParams = url.searchParams;
    const status = searchParams.get('status');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');
    const minAmount = searchParams.get('minAmount');
    const maxAmount = searchParams.get('maxAmount');
    const search = searchParams.get('search');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');

    // Get all receipts for the company
    let receipts = dataStore.getReceiptsByCompany(user.companyId);

    // Apply filters
    if (status && status !== 'all') {
      receipts = receipts.filter(r => r.status === status);
    }

    if (startDate) {
      receipts = receipts.filter(r => {
        const receiptDate = r.receiptDate || r.createdAt;
        return new Date(receiptDate) >= new Date(startDate);
      });
    }

    if (endDate) {
      receipts = receipts.filter(r => {
        const receiptDate = r.receiptDate || r.createdAt;
        return new Date(receiptDate) <= new Date(endDate);
      });
    }

    if (minAmount) {
      receipts = receipts.filter(r => (r.amount || 0) >= parseFloat(minAmount));
    }

    if (maxAmount) {
      receipts = receipts.filter(r => (r.amount || 0) <= parseFloat(maxAmount));
    }

    if (search) {
      receipts = receipts.filter(r => 
        (r.merchantName?.toLowerCase().includes(search.toLowerCase())) ||
        (r.notes?.toLowerCase().includes(search.toLowerCase())) ||
        (r.category?.toLowerCase().includes(search.toLowerCase()))
      );
    }

    // Sort by creation date (newest first)
    receipts.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    // Pagination
    const total = receipts.length;
    const totalPages = Math.ceil(total / limit);
    const start = (page - 1) * limit;
    const paginatedReceipts = receipts.slice(start, start + limit);

    // Add user information to receipts
    const receiptsWithUsers = paginatedReceipts.map(receipt => {
      const receiptUser = dataStore.getAppUsers().find(u => u.id === receipt.userId);
      return {
        ...receipt,
        userName: receiptUser?.name || 'Unknown User',
        userEmail: receiptUser?.email || '',
      };
    });

    return NextResponse.json({
      receipts: receiptsWithUsers,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
      stats: {
        total: dataStore.getReceiptsByCompany(user.companyId).length,
        pending: dataStore.getReceiptsByCompany(user.companyId).filter(r => r.status === 'pending').length,
        processed: dataStore.getReceiptsByCompany(user.companyId).filter(r => r.status === 'processed').length,
        sent: dataStore.getReceiptsByCompany(user.companyId).filter(r => r.status === 'sent').length,
      },
    });

  } catch (error) {
    console.error('Receipts fetch error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}