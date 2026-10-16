create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.union_payments (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  amount numeric not null default 0,
  type text,
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_union_payments_updated_at on public.union_payments;
create trigger set_union_payments_updated_at
before update on public.union_payments
for each row execute function public.set_updated_at();

alter table public.union_payments enable row level security;

create table if not exists public.store_payments (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  amount numeric not null default 0,
  type text,
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_store_payments_updated_at on public.store_payments;
create trigger set_store_payments_updated_at
before update on public.store_payments
for each row execute function public.set_updated_at();

alter table public.store_payments enable row level security;

create table if not exists public.treasury (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  amount numeric not null default 0,
  type text,
  date timestamptz,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_treasury_updated_at on public.treasury;
create trigger set_treasury_updated_at
before update on public.treasury
for each row execute function public.set_updated_at();

alter table public.treasury enable row level security;

create table if not exists public.aero_ledger (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  date timestamptz,
  subcommittee text,
  purpose text,
  type text,
  amount numeric not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_aero_ledger_updated_at on public.aero_ledger;
create trigger set_aero_ledger_updated_at
before update on public.aero_ledger
for each row execute function public.set_updated_at();

alter table public.aero_ledger enable row level security;

create table if not exists public.system_status (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  key text unique,
  opening_balance numeric not null default 0,
  last_weekly_summary timestamptz,
  last_monthly_summary timestamptz,
  is_active boolean not null default true,
  settings jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_system_status_updated_at on public.system_status;
create trigger set_system_status_updated_at
before update on public.system_status
for each row execute function public.set_updated_at();

alter table public.system_status enable row level security;

create table if not exists public.purchase_requests (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  committee_name text,
  request_title text,
  item_name text,
  reason text,
  description text,
  amount numeric not null default 0,
  estimated_cost numeric,
  status text not null default 'pending',
  requested_by text,
  reviewed_at timestamptz,
  completed_at timestamptz,
  rejection_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_purchase_requests_updated_at on public.purchase_requests;
create trigger set_purchase_requests_updated_at
before update on public.purchase_requests
for each row execute function public.set_updated_at();

alter table public.purchase_requests enable row level security;

create table if not exists public.prd_payments (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  amount numeric not null default 0,
  type text,
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_prd_payments_updated_at on public.prd_payments;
create trigger set_prd_payments_updated_at
before update on public.prd_payments
for each row execute function public.set_updated_at();

alter table public.prd_payments enable row level security;

create table if not exists public.library_payments (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  amount numeric not null default 0,
  type text,
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_library_payments_updated_at on public.library_payments;
create trigger set_library_payments_updated_at
before update on public.library_payments
for each row execute function public.set_updated_at();

alter table public.library_payments enable row level security;

create index if not exists idx_union_payments_student_id on public.union_payments (student_id);
create index if not exists idx_store_payments_student_id on public.store_payments (student_id);
create index if not exists idx_treasury_student_id on public.treasury (student_id);
create index if not exists idx_aero_ledger_date on public.aero_ledger (date desc);
create index if not exists idx_purchase_requests_status on public.purchase_requests (status);
create index if not exists idx_prd_payments_student_id on public.prd_payments (student_id);
create index if not exists idx_library_payments_student_id on public.library_payments (student_id);
