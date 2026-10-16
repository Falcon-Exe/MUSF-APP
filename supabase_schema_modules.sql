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

create table if not exists public.library_books (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  author text,
  image_url text,
  timestamp timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_library_books_updated_at on public.library_books;
create trigger set_library_books_updated_at
before update on public.library_books
for each row execute function public.set_updated_at();

alter table public.library_books enable row level security;

create table if not exists public.store_inventory (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  name text,
  purchase_price numeric not null default 0,
  price numeric not null default 0,
  unit text,
  quantity numeric not null default 0,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_store_inventory_updated_at on public.store_inventory;
create trigger set_store_inventory_updated_at
before update on public.store_inventory
for each row execute function public.set_updated_at();

alter table public.store_inventory enable row level security;

create table if not exists public.literary_works (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  author text,
  content text,
  category text,
  date timestamptz,
  last_edited timestamptz,
  likes jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_literary_works_updated_at on public.literary_works;
create trigger set_literary_works_updated_at
before update on public.literary_works
for each row execute function public.set_updated_at();

alter table public.literary_works enable row level security;

create table if not exists public.literary_requests (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  author text,
  student_id text,
  author_id text,
  content text,
  category text,
  status text not null default 'pending',
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_literary_requests_updated_at on public.literary_requests;
create trigger set_literary_requests_updated_at
before update on public.literary_requests
for each row execute function public.set_updated_at();

alter table public.literary_requests enable row level security;

create table if not exists public.research_works (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  author text,
  author_name text,
  student_id text,
  author_id text,
  abstract text,
  description text,
  full_paper text,
  field text,
  category text,
  file_url text,
  pdf_url text,
  status text not null default 'published',
  likes numeric not null default 0,
  date timestamptz,
  published_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.research_works
add column if not exists pdf_url text;

drop trigger if exists set_research_works_updated_at on public.research_works;
create trigger set_research_works_updated_at
before update on public.research_works
for each row execute function public.set_updated_at();

alter table public.research_works enable row level security;

create table if not exists public.research_requests (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  author text,
  student_id text,
  author_id text,
  abstract text,
  field text,
  status text not null default 'pending',
  likes numeric not null default 0,
  date timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_research_requests_updated_at on public.research_requests;
create trigger set_research_requests_updated_at
before update on public.research_requests
for each row execute function public.set_updated_at();

alter table public.research_requests enable row level security;

create table if not exists public.sports_events (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  category text,
  first_place_id text,
  first_place_name text,
  second_place_id text,
  second_place_name text,
  third_place_id text,
  third_place_name text,
  results_published boolean not null default false,
  winners jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_sports_events_updated_at on public.sports_events;
create trigger set_sports_events_updated_at
before update on public.sports_events
for each row execute function public.set_updated_at();

alter table public.sports_events enable row level security;

create table if not exists public.arts_events (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  type text,
  first_place_id text,
  first_place_name text,
  second_place_id text,
  second_place_name text,
  third_place_id text,
  third_place_name text,
  results_published boolean not null default false,
  winners jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_arts_events_updated_at on public.arts_events;
create trigger set_arts_events_updated_at
before update on public.arts_events
for each row execute function public.set_updated_at();

alter table public.arts_events enable row level security;

create table if not exists public.social_css_works (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  instruction text,
  start_date timestamptz,
  end_date timestamptz,
  date_added timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_social_css_works_updated_at on public.social_css_works;
create trigger set_social_css_works_updated_at
before update on public.social_css_works
for each row execute function public.set_updated_at();

alter table public.social_css_works enable row level security;

create table if not exists public.social_exams (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  subject text,
  date timestamptz,
  location text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_social_exams_updated_at on public.social_exams;
create trigger set_social_exams_updated_at
before update on public.social_exams
for each row execute function public.set_updated_at();

alter table public.social_exams enable row level security;

create table if not exists public.cuc_notices (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  content text,
  date text,
  type text,
  timestamp timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_cuc_notices_updated_at on public.cuc_notices;
create trigger set_cuc_notices_updated_at
before update on public.cuc_notices
for each row execute function public.set_updated_at();

alter table public.cuc_notices enable row level security;

create table if not exists public.union_schedule (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  date_string text,
  time_string text,
  committee text,
  event_date timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_union_schedule_updated_at on public.union_schedule;
create trigger set_union_schedule_updated_at
before update on public.union_schedule
for each row execute function public.set_updated_at();

alter table public.union_schedule enable row level security;

create table if not exists public.samajyam_performances (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  date timestamptz,
  category text,
  team text,
  venue text,
  event_name text,
  topic text,
  performer text,
  performer_id text,
  timestamp timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_samajyam_performances_updated_at on public.samajyam_performances;
create trigger set_samajyam_performances_updated_at
before update on public.samajyam_performances
for each row execute function public.set_updated_at();

alter table public.samajyam_performances enable row level security;

create table if not exists public.prd_tasks (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  committee_name text,
  type text,
  request_title text,
  title text,
  description text,
  deadline text,
  status text not null default 'Pending',
  requested_by text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_prd_tasks_updated_at on public.prd_tasks;
create trigger set_prd_tasks_updated_at
before update on public.prd_tasks
for each row execute function public.set_updated_at();

alter table public.prd_tasks enable row level security;

create index if not exists idx_library_books_timestamp on public.library_books (timestamp desc);
create index if not exists idx_store_inventory_name on public.store_inventory (name);
create index if not exists idx_literary_works_date on public.literary_works (date desc);
create index if not exists idx_literary_requests_status on public.literary_requests (status);
create index if not exists idx_research_works_date on public.research_works (date desc);
create index if not exists idx_research_requests_status on public.research_requests (status);
create index if not exists idx_sports_events_results on public.sports_events (results_published);
create index if not exists idx_arts_events_results on public.arts_events (results_published);
create index if not exists idx_social_css_works_date_added on public.social_css_works (date_added desc);
create index if not exists idx_social_exams_date on public.social_exams (date);
create index if not exists idx_cuc_notices_timestamp on public.cuc_notices (timestamp desc);
create index if not exists idx_union_schedule_committee on public.union_schedule (committee);
create index if not exists idx_samajyam_performances_team on public.samajyam_performances (team);
create index if not exists idx_prd_tasks_status on public.prd_tasks (status);
