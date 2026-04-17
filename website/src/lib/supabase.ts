import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

// Client-side Supabase client
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  }
});

// Database Types (based on your schema)
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      subscription_plans: {
        Row: {
          id: string
          name: string
          description: string | null
          price: number
          billing_cycle: string
          max_users: number
          max_receipts_per_month: number | null
          features: Json | null
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          price: number
          billing_cycle: string
          max_users: number
          max_receipts_per_month?: number | null
          features?: Json | null
          is_active?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          price?: number
          billing_cycle?: string
          max_users?: number
          max_receipts_per_month?: number | null
          features?: Json | null
          is_active?: boolean
          created_at?: string
        }
      }
      companies: {
        Row: {
          id: string
          name: string
          domain: string | null
          destination_email: string
          subscription_plan_id: string | null
          subscription_status: string
          subscription_start_date: string | null
          subscription_end_date: string | null
          stripe_customer_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          domain?: string | null
          destination_email: string
          subscription_plan_id?: string | null
          subscription_status?: string
          subscription_start_date?: string | null
          subscription_end_date?: string | null
          stripe_customer_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          domain?: string | null
          destination_email?: string
          subscription_plan_id?: string | null
          subscription_status?: string
          subscription_start_date?: string | null
          subscription_end_date?: string | null
          stripe_customer_id?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      portal_users: {
        Row: {
          id: string
          email: string
          password_hash: string
          name: string
          role: string
          company_id: string | null
          is_active: boolean
          email_verified: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          email: string
          password_hash: string
          name: string
          role: string
          company_id?: string | null
          is_active?: boolean
          email_verified?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          password_hash?: string
          name?: string
          role?: string
          company_id?: string | null
          is_active?: boolean
          email_verified?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      app_users: {
        Row: {
          id: string
          email: string
          password_hash: string
          name: string
          company_id: string | null
          role: string
          is_active: boolean
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          email: string
          password_hash: string
          name: string
          company_id?: string | null
          role?: string
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          password_hash?: string
          name?: string
          company_id?: string | null
          role?: string
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      receipts: {
        Row: {
          id: string
          user_id: string | null
          company_id: string | null
          image_path: string
          merchant_name: string | null
          amount: number | null
          receipt_date: string | null
          category: string | null
          notes: string | null
          ocr_data: Json | null
          status: string
          email_sent_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id?: string | null
          company_id?: string | null
          image_path: string
          merchant_name?: string | null
          amount?: number | null
          receipt_date?: string | null
          category?: string | null
          notes?: string | null
          ocr_data?: Json | null
          status?: string
          email_sent_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string | null
          company_id?: string | null
          image_path?: string
          merchant_name?: string | null
          amount?: number | null
          receipt_date?: string | null
          category?: string | null
          notes?: string | null
          ocr_data?: Json | null
          status?: string
          email_sent_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      payments: {
        Row: {
          id: string
          company_id: string | null
          stripe_payment_intent_id: string | null
          amount: number
          currency: string
          status: string
          billing_period_start: string | null
          billing_period_end: string | null
          created_at: string
        }
        Insert: {
          id?: string
          company_id?: string | null
          stripe_payment_intent_id?: string | null
          amount: number
          currency?: string
          status: string
          billing_period_start?: string | null
          billing_period_end?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          company_id?: string | null
          stripe_payment_intent_id?: string | null
          amount?: number
          currency?: string
          status?: string
          billing_period_start?: string | null
          billing_period_end?: string | null
          created_at?: string
        }
      }
      usage_stats: {
        Row: {
          id: string
          company_id: string | null
          month: number
          year: number
          receipts_processed: number
          active_users: number
          created_at: string
        }
        Insert: {
          id?: string
          company_id?: string | null
          month: number
          year: number
          receipts_processed?: number
          active_users?: number
          created_at?: string
        }
        Update: {
          id?: string
          company_id?: string | null
          month?: number
          year?: number
          receipts_processed?: number
          active_users?: number
          created_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}
