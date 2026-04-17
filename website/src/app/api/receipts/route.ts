import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const url = new URL(request.url);
    const searchParams = url.searchParams;
    const status = searchParams.get('status');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');
    const minAmount = searchParams.get('minAmount');
    const maxAmount = searchParams.get('maxAmount');
    const search = searchParams.get('search');
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '10', 10);

    const { data: receiptsRaw, error } = await supabaseAdmin
      .from('receipts')
      .select('*')
      .eq('company_id', user.company_id)
      .order('created_at', { ascending: false });

    if (error) {
      return NextResponse.json({ error: 'Failed to fetch receipts' }, { status: 500 });
    }

    let receipts = receiptsRaw || [];

    if (status && status !== 'all') {
      receipts = receipts.filter((r) => r.status === status);
    }

    if (startDate) {
      receipts = receipts.filter((r) => new Date(r.receipt_date || r.created_at) >= new Date(startDate));
    }

    if (endDate) {
      receipts = receipts.filter((r) => new Date(r.receipt_date || r.created_at) <= new Date(endDate));
    }

    if (minAmount) {
      receipts = receipts.filter((r) => Number(r.amount || 0) >= parseFloat(minAmount));
    }

    if (maxAmount) {
      receipts = receipts.filter((r) => Number(r.amount || 0) <= parseFloat(maxAmount));
    }

    if (search) {
      const q = search.toLowerCase();
      receipts = receipts.filter((r) =>
        (r.merchant_name || '').toLowerCase().includes(q) ||
        (r.notes || '').toLowerCase().includes(q) ||
        (r.category || '').toLowerCase().includes(q)
      );
    }

    const total = receipts.length;
    const totalPages = Math.ceil(total / limit);
    const start = (page - 1) * limit;
    const paginatedReceipts = receipts.slice(start, start + limit);

    const userIds = [...new Set(paginatedReceipts.map((r) => r.user_id).filter(Boolean))] as string[];
    const { data: receiptUsers } = userIds.length
      ? await supabaseAdmin.from('users').select('id, name, email').in('id', userIds)
      : { data: [] as any[] };

    const userMap = new Map((receiptUsers || []).map((u: any) => [u.id, u]));

    const mappedReceipts = paginatedReceipts.map((r) => ({
      id: r.id,
      userId: r.user_id,
      companyId: r.company_id,
      imagePath: r.image_path,
      merchantName: r.merchant_name,
      amount: r.amount,
      receiptDate: r.receipt_date,
      category: r.category,
      notes: r.notes,
      status: r.status,
      emailSentAt: r.email_sent_at,
      createdAt: r.created_at,
      userName: userMap.get(r.user_id)?.name || 'Unknown User',
      userEmail: userMap.get(r.user_id)?.email || '',
    }));

    return NextResponse.json({
      receipts: mappedReceipts,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
      stats: {
        total: (receiptsRaw || []).length,
        pending: (receiptsRaw || []).filter((r) => r.status === 'pending').length,
        processed: (receiptsRaw || []).filter((r) => r.status === 'processed').length,
        sent: (receiptsRaw || []).filter((r) => r.status === 'sent').length,
      },
    });
  } catch (error) {
    console.error('Receipts fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
