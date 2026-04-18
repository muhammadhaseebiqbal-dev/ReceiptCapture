import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const { data: receipt, error } = await supabaseAdmin
      .from('receipts')
      .select('*')
      .eq('id', id)
      .eq('company_id', user.company_id)
      .maybeSingle();

    if (error || !receipt) {
      return NextResponse.json({ error: 'Receipt not found' }, { status: 404 });
    }

    const { data: receiptUser } = await supabaseAdmin
      .from('users')
      .select('id, name, email')
      .eq('id', receipt.user_id)
      .maybeSingle();

    return NextResponse.json({
      id: receipt.id,
      userId: receipt.user_id,
      companyId: receipt.company_id,
      imagePath: receipt.image_path,
      merchantName: receipt.merchant_name,
      amount: receipt.amount,
      receiptDate: receipt.receipt_date,
      category: receipt.category,
      notes: receipt.notes,
      status: receipt.status,
      emailSentAt: receipt.email_sent_at,
      createdAt: receipt.created_at,
      userName: receiptUser?.name || 'Unknown User',
      userEmail: receiptUser?.email || '',
    });
  } catch (error) {
    console.error('Receipt fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const authResult = await requireAuth(request, ['company_representative']);
    if (authResult.response) {
      return authResult.response;
    }

    const user = authResult.context!.user;
    if (!user.company_id) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const { status, notes } = await request.json();

    const { data: existing, error: findError } = await supabaseAdmin
      .from('receipts')
      .select('id, user_id')
      .eq('id', id)
      .eq('company_id', user.company_id)
      .maybeSingle();

    if (findError || !existing) {
      return NextResponse.json({ error: 'Receipt not found' }, { status: 404 });
    }

    const updates: Record<string, any> = {};
    if (status !== undefined) {
      updates.status = status;
      if (status === 'sent') {
        updates.email_sent_at = new Date().toISOString();
      }
    }
    if (notes !== undefined) {
      updates.notes = notes;
    }

    const { data: updatedReceipt, error: updateError } = await supabaseAdmin
      .from('receipts')
      .update(updates)
      .eq('id', id)
      .eq('company_id', user.company_id)
      .select('*')
      .single();

    if (updateError || !updatedReceipt) {
      return NextResponse.json({ error: 'Failed to update receipt' }, { status: 500 });
    }

    const { data: receiptUser } = await supabaseAdmin
      .from('users')
      .select('id, name, email')
      .eq('id', updatedReceipt.user_id)
      .maybeSingle();

    return NextResponse.json({
      id: updatedReceipt.id,
      userId: updatedReceipt.user_id,
      companyId: updatedReceipt.company_id,
      imagePath: updatedReceipt.image_path,
      merchantName: updatedReceipt.merchant_name,
      amount: updatedReceipt.amount,
      receiptDate: updatedReceipt.receipt_date,
      category: updatedReceipt.category,
      notes: updatedReceipt.notes,
      status: updatedReceipt.status,
      emailSentAt: updatedReceipt.email_sent_at,
      createdAt: updatedReceipt.created_at,
      userName: receiptUser?.name || 'Unknown User',
      userEmail: receiptUser?.email || '',
    });
  } catch (error) {
    console.error('Receipt update error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
