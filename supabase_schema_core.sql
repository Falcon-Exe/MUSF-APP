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

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  auth_user_id uuid unique,
  firebase_uid text unique,
  student_id text,
  full_name text,
  display_name text,
  email text,
  phone text,
  avatar_url text,
  role text,
  assigned_role text,
  designation text,
  is_admin boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key text not null unique,
  setting_value text,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_app_settings_updated_at on public.app_settings;
create trigger set_app_settings_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();

alter table public.app_settings enable row level security;

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  firebase_uid text unique,
  uid text,
  full_name text,
  student_id text unique,
  cic_no text,
  course text,
  class_name text,
  personal_email text,
  email text,
  auth_email text,
  phone text,
  address text,
  role text not null default 'student',
  assigned_role text,
  designation text,
  role_description text,
  profile_image_url text,
  committee_name text,
  is_admin boolean not null default false,
  is_active boolean not null default true,
  fcm_token text,
  union_balance numeric not null default 0,
  union_total_paid numeric not null default 0,
  store_balance numeric not null default 0,
  store_total_added numeric not null default 0,
  library_fine numeric not null default 0,
  library_status text,
  prd_print_balance numeric not null default 0,
  prd_print_total_added numeric not null default 0,
  balances jsonb not null default '{}'::jsonb,
  fines jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_students_updated_at on public.students;
create trigger set_students_updated_at
before update on public.students
for each row execute function public.set_updated_at();

alter table public.students enable row level security;

alter table public.students add column if not exists role_description text;
alter table public.students add column if not exists profile_image_url text;
alter table public.students add column if not exists committee_name text;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  firebase_uid text unique,
  uid text,
  student_id text,
  full_name text,
  email text,
  phone text,
  role text,
  assigned_role text,
  designation text,
  is_admin boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

alter table public.users enable row level security;

create index if not exists idx_profiles_student_id on public.profiles (student_id);
create index if not exists idx_app_settings_key on public.app_settings (setting_key);
create index if not exists idx_students_student_id on public.students (student_id);
create index if not exists idx_students_role on public.students (role);
create index if not exists idx_users_student_id on public.users (student_id);
