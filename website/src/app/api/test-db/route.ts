import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-server';

export async function GET(request: NextRequest) {
  try {
    // Check if we can connect to Supabase
    const { data: tables, error: tablesError } = await supabaseAdmin
      .from('users')
      .select('email, name, role, is_active')
      .limit(5);

    if (tablesError) {
      return NextResponse.json({
        success: false,
        error: 'Database error',
        details: tablesError.message,
        hint: 'Make sure migrations have been applied for companies/users/receipts/sync_queue'
      }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      message: 'Database connection successful',
      users: tables,
      userCount: tables?.length || 0
    });

  } catch (error: any) {
    return NextResponse.json({
      success: false,
      error: 'Connection failed',
      details: error.message
    }, { status: 500 });
  }
}
