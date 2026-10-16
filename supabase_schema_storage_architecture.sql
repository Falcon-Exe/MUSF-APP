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

-- Supabase stores records and file metadata only.
-- Cloudflare R2 stores the actual PDFs, images, posters, reels/videos,
-- research files, profile photos, and event photos.

insert into storage.buckets (id, name, public)
values ('home-assets', 'home-assets', true)
on conflict (id) do update set public = true;

create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  student_id text,
  user_id uuid,
  role text not null,
  committee_name text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_admin_roles_updated_at on public.admin_roles;
create trigger set_admin_roles_updated_at
before update on public.admin_roles
for each row execute function public.set_updated_at();

alter table public.admin_roles enable row level security;

create table if not exists public.committees (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text unique,
  description text,
  image_url text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_committees_updated_at on public.committees;
create trigger set_committees_updated_at
before update on public.committees
for each row execute function public.set_updated_at();

alter table public.committees enable row level security;

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

create table if not exists public.publications (
  id uuid primary key default gen_random_uuid(),
  title text,
  content text,
  category text,
  image_url text,
  committee_name text,
  author_name text,
  likes_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_publications_updated_at on public.publications;
create trigger set_publications_updated_at
before update on public.publications
for each row execute function public.set_updated_at();

alter table public.publications enable row level security;

create table if not exists public.research_works (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  author_name text,
  category text,
  file_url text,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  published_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.research_works add column if not exists description text;
alter table public.research_works add column if not exists author_name text;
alter table public.research_works add column if not exists category text;
alter table public.research_works add column if not exists file_url text;
alter table public.research_works add column if not exists published_at timestamptz;

drop trigger if exists set_research_works_updated_at on public.research_works;
create trigger set_research_works_updated_at
before update on public.research_works
for each row execute function public.set_updated_at();

alter table public.research_works enable row level security;

create table if not exists public.prd_requests (
  id uuid primary key default gen_random_uuid(),
  committee_name text,
  title text,
  description text,
  category text,
  image_url text,
  video_url text,
  pdf_url text,
  file_url text,
  status text not null default 'pending',
  requested_by text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_prd_requests_updated_at on public.prd_requests;
create trigger set_prd_requests_updated_at
before update on public.prd_requests
for each row execute function public.set_updated_at();

alter table public.prd_requests enable row level security;

create table if not exists public.fund_requests (
  id uuid primary key default gen_random_uuid(),
  committee_name text,
  title text,
  description text,
  amount numeric not null default 0,
  image_url text,
  pdf_url text,
  file_url text,
  status text not null default 'pending',
  requested_by text,
  reviewed_at timestamptz,
  completed_at timestamptz,
  rejection_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_fund_requests_updated_at on public.fund_requests;
create trigger set_fund_requests_updated_at
before update on public.fund_requests
for each row execute function public.set_updated_at();

alter table public.fund_requests enable row level security;

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  committee_name text,
  event_date timestamptz,
  location text,
  image_url text,
  video_url text,
  pdf_url text,
  file_url text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_events_updated_at on public.events;
create trigger set_events_updated_at
before update on public.events
for each row execute function public.set_updated_at();

alter table public.events enable row level security;

create table if not exists public.file_metadata (
  id uuid primary key default gen_random_uuid(),
  owner_table text not null,
  owner_id uuid,
  r2_key text not null,
  bucket text,
  file_url text,
  image_url text,
  video_url text,
  pdf_url text,
  content_type text,
  size_bytes bigint,
  uploaded_by uuid,
  visibility text not null default 'public',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_file_metadata_updated_at on public.file_metadata;
create trigger set_file_metadata_updated_at
before update on public.file_metadata
for each row execute function public.set_updated_at();

alter table public.file_metadata enable row level security;

alter table public.students add column if not exists image_url text;
alter table public.profiles add column if not exists image_url text;
alter table public.notifications add column if not exists image_url text;
alter table public.notifications add column if not exists file_url text;

create index if not exists idx_admin_roles_student_id on public.admin_roles (student_id);
create index if not exists idx_committees_name on public.committees (name);
create index if not exists idx_app_settings_key on public.app_settings (setting_key);
create index if not exists idx_publications_committee on public.publications (committee_name);
create index if not exists idx_publications_created_at on public.publications (created_at desc);
create index if not exists idx_research_works_status on public.research_works (status);
create index if not exists idx_prd_requests_status on public.prd_requests (status);
create index if not exists idx_fund_requests_status on public.fund_requests (status);
create index if not exists idx_events_committee_date on public.events (committee_name, event_date);
create index if not exists idx_file_metadata_owner on public.file_metadata (owner_table, owner_id);
create index if not exists idx_file_metadata_r2_key on public.file_metadata (r2_key);
