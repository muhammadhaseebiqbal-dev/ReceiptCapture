create extension if not exists pgcrypto;

create table if not exists subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  description text,
  price numeric(10, 2) not null,
  billing_cycle varchar(20) not null,
  max_users integer not null,
  max_receipts_per_month integer,
  features jsonb default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists companies (
  id uuid primary key default gen_random_uuid(),
  name varchar(255) not null,
  domain varchar(255),
  destination_email varchar(255) not null,
  subscription_plan_id uuid references subscription_plans(id),
  subscription_status varchar(20) not null default 'inactive',
  subscription_start_date timestamptz,
  subscription_end_date timestamptz,
  stripe_customer_id varchar(255),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email varchar(255) unique not null,
  password_hash varchar(255) not null,
  name varchar(255) not null,
  role varchar(50) not null,
  company_id uuid references companies(id) on delete set null,
  is_active boolean not null default true,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  company_id uuid references companies(id) on delete cascade,
  image_path text not null,
  merchant_name varchar(255),
  amount numeric(10, 2),
  receipt_date date,
  category varchar(100),
  notes text,
  status varchar(20) not null default 'pending',
  email_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists sync_queue (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid references receipts(id) on delete cascade,
  user_id uuid references users(id) on delete set null,
  company_id uuid references companies(id) on delete cascade,
  payload jsonb,
  status varchar(20) not null default 'pending',
  retry_count integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists billing_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  plan_id uuid references subscription_plans(id),
  plan_name varchar(100) not null,
  amount numeric(10, 2) not null,
  billing_cycle varchar(20) not null,
  status varchar(20) not null,
  billing_date timestamptz not null,
  next_billing_date timestamptz,
  description text,
  created_at timestamptz not null default now()
);

create index if not exists idx_users_company_id on users(company_id);
create index if not exists idx_users_role on users(role);
create index if not exists idx_receipts_company_id on receipts(company_id);
create index if not exists idx_receipts_user_id on receipts(user_id);
create index if not exists idx_sync_queue_status on sync_queue(status);
create index if not exists idx_sync_queue_company_id on sync_queue(company_id);
create index if not exists idx_billing_history_company_id on billing_history(company_id);

insert into subscription_plans (name, description, price, billing_cycle, max_users, max_receipts_per_month, features, is_active)
values
  ('Starter', 'Perfect for small teams', 29.99, 'monthly', 5, 100, '["Email Support", "1GB Storage", "Basic Analytics"]'::jsonb, true),
  ('Professional', 'Growing businesses', 59.99, 'monthly', 20, 500, '["Priority Support", "10GB Storage", "Advanced Analytics"]'::jsonb, true),
  ('Enterprise', 'Large organizations', 149.99, 'monthly', 100, 2000, '["Phone Support", "Unlimited Storage", "API Access"]'::jsonb, true)
on conflict do nothing;
