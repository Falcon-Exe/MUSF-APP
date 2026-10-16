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

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  student_id text,
  title text,
  message text,
  body text,
  type text,
  priority text,
  committee text,
  target_type text,
  reference_id text,
  is_read boolean not null default false,
  timestamp timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

alter table public.notifications enable row level security;

create table if not exists public.committee_notifications (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  committee text,
  title text,
  message text,
  priority text,
  target_type text,
  target_committee text,
  sender_id text,
  is_read boolean not null default false,
  timestamp timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_committee_notifications_updated_at on public.committee_notifications;
create trigger set_committee_notifications_updated_at
before update on public.committee_notifications
for each row execute function public.set_updated_at();

alter table public.committee_notifications enable row level security;

create table if not exists public.executive_announcements (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  message text,
  sender_id text,
  sender_name text,
  sender_role text,
  target_type text,
  target_committee text,
  priority text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_executive_announcements_updated_at on public.executive_announcements;
create trigger set_executive_announcements_updated_at
before update on public.executive_announcements
for each row execute function public.set_updated_at();

alter table public.executive_announcements enable row level security;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  firestore_id text unique,
  title text,
  body text,
  message text,
  sender text,
  timestamp timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_announcements_updated_at on public.announcements;
create trigger set_announcements_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

alter table public.announcements enable row level security;

create index if not exists idx_notifications_student_id on public.notifications (student_id);
create index if not exists idx_notifications_is_read on public.notifications (is_read);
create index if not exists idx_notifications_created_at on public.notifications (created_at desc);
create index if not exists idx_committee_notifications_committee on public.committee_notifications (committee);
create index if not exists idx_executive_announcements_active on public.executive_announcements (is_active);
