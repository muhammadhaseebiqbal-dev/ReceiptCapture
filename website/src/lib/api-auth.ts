import { NextRequest, NextResponse } from 'next/server';
import { verifyToken } from '@/lib/auth';
import { supabaseAdmin } from '@/lib/supabase-server';

export interface AuthenticatedUser {
  id: string;
  email: string;
  name: string;
  role: string;
  company_id: string | null;
  is_active: boolean;
}

export interface AuthContext {
  token: string;
  payload: any;
  user: AuthenticatedUser;
}

export async function requireAuth(
  request: NextRequest,
  allowedRoles?: string[]
): Promise<{ context?: AuthContext; response?: NextResponse }> {
  const authHeader = request.headers.get('authorization');
  const token = authHeader?.replace('Bearer ', '');

  if (!token) {
    return {
      response: NextResponse.json({ error: 'Authentication required' }, { status: 401 }),
    };
  }

  const payload = verifyToken(token);
  if (!payload?.userId) {
    return {
      response: NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 }),
    };
  }

  const { data: user, error } = await supabaseAdmin
    .from('users')
    .select('id, email, name, role, company_id, is_active')
    .eq('id', payload.userId)
    .maybeSingle();

  if (error || !user || !user.is_active) {
    return {
      response: NextResponse.json({ error: 'User not found or inactive' }, { status: 401 }),
    };
  }

  if (allowedRoles && allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
    return {
      response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }),
    };
  }

  return {
    context: {
      token,
      payload,
      user: user as AuthenticatedUser,
    },
  };
}
