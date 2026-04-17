import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

function createMissingSupabaseClient() {
  return new Proxy(
    {},
    {
      get() {
        throw new Error('Supabase is not configured for this workspace. Use the backend API routes instead.');
      },
      apply() {
        throw new Error('Supabase is not configured for this workspace. Use the backend API routes instead.');
      },
    }
  );
}

// Legacy fallback: keep imports safe even when Supabase env vars are absent.
// Remaining routes should be migrated to the backend API.
export const supabaseAdmin =
  supabaseUrl && supabaseServiceKey
    ? createClient(supabaseUrl, supabaseServiceKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      })
    : createMissingSupabaseClient();
