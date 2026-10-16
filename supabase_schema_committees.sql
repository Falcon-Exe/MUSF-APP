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

create table if not exists public.leadership (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  name text,
  role text,
  display_order numeric not null default 99,
  color_hex text,
  icon_name text,
  image_url text,
  background_image_url text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.leadership
add column if not exists background_image_url text;

drop trigger if exists set_leadership_updated_at on public.leadership;
create trigger set_leadership_updated_at
before update on public.leadership
for each row execute function public.set_updated_at();

alter table public.leadership enable row level security;

create table if not exists public.committee_photos (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  name text,
  role text,
  image_url text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_committee_photos_updated_at on public.committee_photos;
create trigger set_committee_photos_updated_at
before update on public.committee_photos
for each row execute function public.set_updated_at();

alter table public.committee_photos enable row level security;

create table if not exists public.committee_reels (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  committee text,
  image_url text,
  caption text,
  timestamp timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_committee_reels_updated_at on public.committee_reels;
create trigger set_committee_reels_updated_at
before update on public.committee_reels
for each row execute function public.set_updated_at();

alter table public.committee_reels enable row level security;

create table if not exists public.committee_awards (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  committee text,
  title text,
  date text,
  gold_id text,
  silver_id text,
  bronze_id text,
  results_published boolean not null default false,
  winners jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_committee_awards_updated_at on public.committee_awards;
create trigger set_committee_awards_updated_at
before update on public.committee_awards
for each row execute function public.set_updated_at();

alter table public.committee_awards enable row level security;

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  type text,
  title text,
  message text,
  student_id text,
  status text not null default 'pending',
  is_read boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_complaints_updated_at on public.complaints;
create trigger set_complaints_updated_at
before update on public.complaints
for each row execute function public.set_updated_at();

alter table public.complaints enable row level security;

create index if not exists idx_leadership_display_order on public.leadership (display_order);
create index if not exists idx_committee_reels_committee on public.committee_reels (committee);
create index if not exists idx_committee_awards_committee on public.committee_awards (committee);
create index if not exists idx_complaints_status on public.complaints (status);
