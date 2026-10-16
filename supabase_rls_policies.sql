create or replace function public.current_student_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select nullif(p.student_id, '')
      from public.profiles p
      where p.auth_user_id = auth.uid()
      limit 1
    ),
    (
      select nullif(s.student_id, '')
      from public.students s
      where s.uid = auth.uid()::text
         or s.firebase_uid = auth.uid()::text
         or s.metadata->>'auth_user_id' = auth.uid()::text
         or lower(coalesce(s.auth_email, '')) = lower(coalesce(auth.email(), ''))
      limit 1
    )
  );
$$;

create or replace function public.is_own_student_id(student_id_value text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select student_id_value is not null
     and public.current_student_id() is not null
     and student_id_value = public.current_student_id();
$$;

create or replace function public.has_any_role(role_names text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with normalized_roles as (
    select lower(role_name) as role_name
    from unnest(role_names) as role_name
  ),
  current_roles as (
    select lower(coalesce(p.role, '')) as role_label
    from public.profiles p
    where p.auth_user_id = auth.uid()
    union all
    select lower(coalesce(p.assigned_role, ''))
    from public.profiles p
    where p.auth_user_id = auth.uid()
    union all
    select lower(coalesce(p.designation, ''))
    from public.profiles p
    where p.auth_user_id = auth.uid()
    union all
    select lower(coalesce(s.role, ''))
    from public.students s
    where s.uid = auth.uid()::text
       or s.firebase_uid = auth.uid()::text
       or s.metadata->>'auth_user_id' = auth.uid()::text
       or lower(coalesce(s.auth_email, '')) = lower(coalesce(auth.email(), ''))
    union all
    select lower(coalesce(s.assigned_role, ''))
    from public.students s
    where s.uid = auth.uid()::text
       or s.firebase_uid = auth.uid()::text
       or s.metadata->>'auth_user_id' = auth.uid()::text
       or lower(coalesce(s.auth_email, '')) = lower(coalesce(auth.email(), ''))
    union all
    select lower(coalesce(s.designation, ''))
    from public.students s
    where s.uid = auth.uid()::text
       or s.firebase_uid = auth.uid()::text
       or s.metadata->>'auth_user_id' = auth.uid()::text
       or lower(coalesce(s.auth_email, '')) = lower(coalesce(auth.email(), ''))
  )
  select exists (
    select 1
    from current_roles cr
    join normalized_roles nr
      on cr.role_label = nr.role_name
      or cr.role_label like '%' || nr.role_name || '%'
    where cr.role_label <> ''
  );
$$;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select true
    from public.profiles p
    where p.auth_user_id = auth.uid()
      and p.is_admin is true
    limit 1
  ), false)
  or coalesce((
    select true
    from public.students s
    where (s.uid = auth.uid()::text
        or s.firebase_uid = auth.uid()::text
        or s.metadata->>'auth_user_id' = auth.uid()::text
        or lower(coalesce(s.auth_email, '')) = lower(coalesce(auth.email(), '')))
      and s.is_admin is true
    limit 1
  ), false)
  or public.has_any_role(array[
    'admin',
    'executive',
    'president',
    'secretary',
    'treasurer',
    'union director',
    'vice president',
    'joint secretary'
  ]);
$$;

create or replace function public.is_finance_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_app_admin()
      or public.has_any_role(array[
        'finance',
        'finance_admin',
        'finance admin',
        'treasurer',
        'accountant',
        'union director'
      ]);
$$;

create or replace function public.is_committee_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_app_admin()
      or public.has_any_role(array[
        'committee_admin',
        'committee admin',
        'committee lead',
        'committee head',
        'sub committee',
        'coordinator',
        'captain',
        'director'
      ]);
$$;

create or replace function public.is_student_safe_role(
  role_value text,
  assigned_role_value text,
  designation_value text,
  is_admin_value boolean
)
returns boolean
language sql
immutable
as $$
  select coalesce(is_admin_value, false) is false
     and lower(coalesce(role_value, 'student')) in ('', 'student', 'user')
     and lower(coalesce(assigned_role_value, '')) in ('', 'student')
     and lower(coalesce(designation_value, '')) in ('', 'student');
$$;

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.users enable row level security;
alter table public.notifications enable row level security;
alter table public.committee_notifications enable row level security;
alter table public.executive_announcements enable row level security;
alter table public.announcements enable row level security;
alter table public.union_payments enable row level security;
alter table public.store_payments enable row level security;
alter table public.treasury enable row level security;
alter table public.aero_ledger enable row level security;
alter table public.system_status enable row level security;
alter table public.purchase_requests enable row level security;
alter table public.prd_payments enable row level security;
alter table public.library_payments enable row level security;
alter table public.leadership enable row level security;
alter table public.committee_photos enable row level security;
alter table public.committee_reels enable row level security;
alter table public.committee_awards enable row level security;
alter table public.complaints enable row level security;
alter table public.library_books enable row level security;
alter table public.store_inventory enable row level security;
alter table public.literary_works enable row level security;
alter table public.literary_requests enable row level security;
alter table public.research_works enable row level security;
alter table public.research_requests enable row level security;
alter table public.sports_events enable row level security;
alter table public.arts_events enable row level security;
alter table public.social_css_works enable row level security;
alter table public.social_exams enable row level security;
alter table public.cuc_notices enable row level security;
alter table public.union_schedule enable row level security;
alter table public.samajyam_performances enable row level security;
alter table public.prd_tasks enable row level security;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles
for select
to authenticated
using (auth_user_id = auth.uid() or public.is_app_admin());

drop policy if exists "profiles_insert_own_or_admin" on public.profiles;
create policy "profiles_insert_own_or_admin"
on public.profiles
for insert
to authenticated
with check (
  public.is_app_admin()
  or (
    auth_user_id = auth.uid()
    and public.is_student_safe_role(role, assigned_role, designation, is_admin)
  )
);

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles
for update
to authenticated
using (auth_user_id = auth.uid() or public.is_app_admin())
with check (
  public.is_app_admin()
  or (
    auth_user_id = auth.uid()
    and public.is_student_safe_role(role, assigned_role, designation, is_admin)
  )
);

drop policy if exists "profiles_delete_admin_only" on public.profiles;
create policy "profiles_delete_admin_only"
on public.profiles
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "students_select_own_or_staff" on public.students;
create policy "students_select_own_or_staff"
on public.students
for select
to authenticated
using (
  public.is_own_student_id(student_id)
  or uid = auth.uid()::text
  or firebase_uid = auth.uid()::text
  or metadata->>'auth_user_id' = auth.uid()::text
  or lower(coalesce(auth_email, '')) = lower(coalesce(auth.email(), ''))
  or public.is_app_admin()
  or public.is_finance_admin()
  or public.is_committee_admin()
);

drop policy if exists "students_insert_staff_only" on public.students;
create policy "students_insert_staff_only"
on public.students
for insert
to authenticated
with check (public.is_app_admin());

drop policy if exists "students_update_own_or_staff" on public.students;
drop policy if exists "students_update_admin_only" on public.students;
create policy "students_update_admin_only"
on public.students
for update
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

drop policy if exists "students_delete_admin_only" on public.students;
create policy "students_delete_admin_only"
on public.students
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "users_select_own_or_admin" on public.users;
create policy "users_select_own_or_admin"
on public.users
for select
to authenticated
using (
  uid = auth.uid()::text
  or firebase_uid = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
);

drop policy if exists "users_insert_admin_only" on public.users;
create policy "users_insert_admin_only"
on public.users
for insert
to authenticated
with check (public.is_app_admin());

drop policy if exists "users_update_own_or_admin" on public.users;
create policy "users_update_own_or_admin"
on public.users
for update
to authenticated
using (
  uid = auth.uid()::text
  or firebase_uid = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
)
with check (
  public.is_app_admin()
  or (
    (uid = auth.uid()::text or firebase_uid = auth.uid()::text or public.is_own_student_id(student_id))
    and public.is_student_safe_role(role, assigned_role, designation, is_admin)
  )
);

drop policy if exists "users_delete_admin_only" on public.users;
create policy "users_delete_admin_only"
on public.users
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "notifications_select_own_or_staff" on public.notifications;
create policy "notifications_select_own_or_staff"
on public.notifications
for select
to authenticated
using (
  student_id = 'all'
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
  or public.is_finance_admin()
  or public.is_committee_admin()
);

drop policy if exists "notifications_insert_staff_only" on public.notifications;
create policy "notifications_insert_staff_only"
on public.notifications
for insert
to authenticated
with check (
  public.is_app_admin()
  or public.is_committee_admin()
  or public.is_finance_admin()
);

drop policy if exists "notifications_update_own_read_or_staff" on public.notifications;
create policy "notifications_update_own_read_or_staff"
on public.notifications
for update
to authenticated
using (
  public.is_own_student_id(student_id)
  or public.is_app_admin()
)
with check (
  public.is_own_student_id(student_id)
  or public.is_app_admin()
);

drop policy if exists "notifications_delete_admin_only" on public.notifications;
create policy "notifications_delete_admin_only"
on public.notifications
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "committee_notifications_select_authenticated" on public.committee_notifications;
create policy "committee_notifications_select_authenticated"
on public.committee_notifications
for select
to authenticated
using (true);

drop policy if exists "committee_notifications_insert_committee_staff" on public.committee_notifications;
create policy "committee_notifications_insert_committee_staff"
on public.committee_notifications
for insert
to authenticated
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "committee_notifications_update_committee_staff" on public.committee_notifications;
create policy "committee_notifications_update_committee_staff"
on public.committee_notifications
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "committee_notifications_delete_admin_only" on public.committee_notifications;
create policy "committee_notifications_delete_admin_only"
on public.committee_notifications
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "executive_announcements_select_active" on public.executive_announcements;
create policy "executive_announcements_select_active"
on public.executive_announcements
for select
to authenticated
using (is_active is true or public.is_app_admin() or public.is_committee_admin());

drop policy if exists "executive_announcements_insert_staff" on public.executive_announcements;
create policy "executive_announcements_insert_staff"
on public.executive_announcements
for insert
to authenticated
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "executive_announcements_update_staff" on public.executive_announcements;
create policy "executive_announcements_update_staff"
on public.executive_announcements
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "executive_announcements_delete_admin_only" on public.executive_announcements;
create policy "executive_announcements_delete_admin_only"
on public.executive_announcements
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "announcements_select_active" on public.announcements;
create policy "announcements_select_active"
on public.announcements
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "announcements_insert_admin_only" on public.announcements;
create policy "announcements_insert_admin_only"
on public.announcements
for insert
to authenticated
with check (public.is_app_admin());

drop policy if exists "announcements_update_admin_only" on public.announcements;
create policy "announcements_update_admin_only"
on public.announcements
for update
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

drop policy if exists "announcements_delete_admin_only" on public.announcements;
create policy "announcements_delete_admin_only"
on public.announcements
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "finance_student_payments_select_own_or_finance" on public.union_payments;
create policy "finance_student_payments_select_own_or_finance"
on public.union_payments
for select
to authenticated
using (public.is_own_student_id(student_id) or public.is_finance_admin());

drop policy if exists "finance_staff_manage_union_payments" on public.union_payments;
create policy "finance_staff_manage_union_payments"
on public.union_payments
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "finance_student_payments_select_own_or_finance" on public.store_payments;
create policy "finance_student_payments_select_own_or_finance"
on public.store_payments
for select
to authenticated
using (public.is_own_student_id(student_id) or public.is_finance_admin());

drop policy if exists "finance_staff_manage_store_payments" on public.store_payments;
create policy "finance_staff_manage_store_payments"
on public.store_payments
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "treasury_select_own_or_finance" on public.treasury;
create policy "treasury_select_own_or_finance"
on public.treasury
for select
to authenticated
using (public.is_own_student_id(student_id) or public.is_finance_admin());

drop policy if exists "finance_staff_manage_treasury" on public.treasury;
create policy "finance_staff_manage_treasury"
on public.treasury
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "aero_ledger_select_finance" on public.aero_ledger;
create policy "aero_ledger_select_finance"
on public.aero_ledger
for select
to authenticated
using (public.is_finance_admin());

drop policy if exists "finance_staff_manage_aero_ledger" on public.aero_ledger;
create policy "finance_staff_manage_aero_ledger"
on public.aero_ledger
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "system_status_select_staff" on public.system_status;
create policy "system_status_select_staff"
on public.system_status
for select
to authenticated
using (public.is_app_admin() or public.is_finance_admin());

drop policy if exists "system_status_manage_finance" on public.system_status;
create policy "system_status_manage_finance"
on public.system_status
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "purchase_requests_select_staff" on public.purchase_requests;
create policy "purchase_requests_select_staff"
on public.purchase_requests
for select
to authenticated
using (
  public.is_app_admin()
  or public.is_finance_admin()
  or public.is_committee_admin()
);

drop policy if exists "purchase_requests_insert_committee_or_finance" on public.purchase_requests;
create policy "purchase_requests_insert_committee_or_finance"
on public.purchase_requests
for insert
to authenticated
with check (
  public.is_app_admin()
  or public.is_finance_admin()
  or public.is_committee_admin()
);

drop policy if exists "purchase_requests_update_finance" on public.purchase_requests;
create policy "purchase_requests_update_finance"
on public.purchase_requests
for update
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "purchase_requests_delete_admin_only" on public.purchase_requests;
create policy "purchase_requests_delete_admin_only"
on public.purchase_requests
for delete
to authenticated
using (public.is_app_admin() or public.is_finance_admin());

drop policy if exists "prd_payments_select_own_or_finance" on public.prd_payments;
create policy "prd_payments_select_own_or_finance"
on public.prd_payments
for select
to authenticated
using (public.is_own_student_id(student_id) or public.is_finance_admin());

drop policy if exists "finance_staff_manage_prd_payments" on public.prd_payments;
create policy "finance_staff_manage_prd_payments"
on public.prd_payments
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "library_payments_select_own_or_staff" on public.library_payments;
create policy "library_payments_select_own_or_staff"
on public.library_payments
for select
to authenticated
using (public.is_own_student_id(student_id) or public.is_app_admin());

drop policy if exists "library_payments_manage_admin_only" on public.library_payments;
create policy "library_payments_manage_admin_only"
on public.library_payments
for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

drop policy if exists "public_college_data_select_leadership" on public.leadership;
create policy "public_college_data_select_leadership"
on public.leadership
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "committee_staff_manage_leadership" on public.leadership;
create policy "committee_staff_manage_leadership"
on public.leadership
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "app_settings_select_authenticated" on public.app_settings;
create policy "app_settings_select_authenticated"
on public.app_settings
for select
to authenticated
using (true);

drop policy if exists "app_settings_manage_admin_only" on public.app_settings;
create policy "app_settings_manage_admin_only"
on public.app_settings
for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

drop policy if exists "home_assets_select_public" on storage.objects;
create policy "home_assets_select_public"
on storage.objects
for select
to public
using (bucket_id = 'home-assets');

drop policy if exists "home_assets_manage_admin_only" on storage.objects;
create policy "home_assets_manage_admin_only"
on storage.objects
for all
to authenticated
using (bucket_id = 'home-assets' and public.is_app_admin())
with check (bucket_id = 'home-assets' and public.is_app_admin());

drop policy if exists "public_college_data_select_committee_photos" on public.committee_photos;
create policy "public_college_data_select_committee_photos"
on public.committee_photos
for select
to authenticated
using (true);

drop policy if exists "committee_staff_manage_committee_photos" on public.committee_photos;
create policy "committee_staff_manage_committee_photos"
on public.committee_photos
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_committee_reels" on public.committee_reels;
create policy "public_college_data_select_committee_reels"
on public.committee_reels
for select
to authenticated
using (is_active is true or public.is_app_admin() or public.is_committee_admin());

drop policy if exists "committee_staff_manage_committee_reels" on public.committee_reels;
create policy "committee_staff_manage_committee_reels"
on public.committee_reels
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_committee_awards" on public.committee_awards;
create policy "public_college_data_select_committee_awards"
on public.committee_awards
for select
to authenticated
using (true);

drop policy if exists "committee_staff_manage_committee_awards" on public.committee_awards;
create policy "committee_staff_manage_committee_awards"
on public.committee_awards
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "complaints_select_own_or_staff" on public.complaints;
create policy "complaints_select_own_or_staff"
on public.complaints
for select
to authenticated
using (
  public.is_own_student_id(student_id)
  or public.is_app_admin()
  or public.is_committee_admin()
);

drop policy if exists "complaints_insert_own" on public.complaints;
create policy "complaints_insert_own"
on public.complaints
for insert
to authenticated
with check (public.is_own_student_id(student_id) or public.is_app_admin());

drop policy if exists "complaints_update_staff_only" on public.complaints;
create policy "complaints_update_staff_only"
on public.complaints
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "complaints_delete_admin_only" on public.complaints;
create policy "complaints_delete_admin_only"
on public.complaints
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "public_college_data_select_library_books" on public.library_books;
create policy "public_college_data_select_library_books"
on public.library_books
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "library_books_manage_admin_only" on public.library_books;
create policy "library_books_manage_admin_only"
on public.library_books
for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

drop policy if exists "store_inventory_select_authenticated" on public.store_inventory;
create policy "store_inventory_select_authenticated"
on public.store_inventory
for select
to authenticated
using (is_active is true or public.is_app_admin() or public.is_finance_admin());

drop policy if exists "store_inventory_manage_finance" on public.store_inventory;
create policy "store_inventory_manage_finance"
on public.store_inventory
for all
to authenticated
using (public.is_finance_admin())
with check (public.is_finance_admin());

drop policy if exists "public_college_data_select_literary_works" on public.literary_works;
create policy "public_college_data_select_literary_works"
on public.literary_works
for select
to authenticated
using (true);

drop policy if exists "literary_works_manage_committee_staff" on public.literary_works;
create policy "literary_works_manage_committee_staff"
on public.literary_works
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "literary_requests_select_own_or_staff" on public.literary_requests;
create policy "literary_requests_select_own_or_staff"
on public.literary_requests
for select
to authenticated
using (
  author_id = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
  or public.is_committee_admin()
);

drop policy if exists "literary_requests_insert_own" on public.literary_requests;
create policy "literary_requests_insert_own"
on public.literary_requests
for insert
to authenticated
with check (
  author_id = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
);

drop policy if exists "literary_requests_update_staff_only" on public.literary_requests;
create policy "literary_requests_update_staff_only"
on public.literary_requests
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "literary_requests_delete_admin_only" on public.literary_requests;
create policy "literary_requests_delete_admin_only"
on public.literary_requests
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "public_college_data_select_research_works" on public.research_works;
create policy "public_college_data_select_research_works"
on public.research_works
for select
to authenticated
using (true);

drop policy if exists "research_works_manage_committee_staff" on public.research_works;
create policy "research_works_manage_committee_staff"
on public.research_works
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "research_works_insert_published_authenticated" on public.research_works;
create policy "research_works_insert_published_authenticated"
on public.research_works
for insert
to authenticated
with check (status = 'published');

drop policy if exists "research_requests_select_own_or_staff" on public.research_requests;
create policy "research_requests_select_own_or_staff"
on public.research_requests
for select
to authenticated
using (
  author_id = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
  or public.is_committee_admin()
);

drop policy if exists "research_requests_insert_own" on public.research_requests;
create policy "research_requests_insert_own"
on public.research_requests
for insert
to authenticated
with check (
  author_id = auth.uid()::text
  or public.is_own_student_id(student_id)
  or public.is_app_admin()
);

drop policy if exists "research_requests_update_staff_only" on public.research_requests;
create policy "research_requests_update_staff_only"
on public.research_requests
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "research_requests_delete_admin_only" on public.research_requests;
create policy "research_requests_delete_admin_only"
on public.research_requests
for delete
to authenticated
using (public.is_app_admin());

drop policy if exists "public_college_data_select_sports_events" on public.sports_events;
create policy "public_college_data_select_sports_events"
on public.sports_events
for select
to authenticated
using (true);

drop policy if exists "sports_events_manage_committee_staff" on public.sports_events;
create policy "sports_events_manage_committee_staff"
on public.sports_events
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_arts_events" on public.arts_events;
create policy "public_college_data_select_arts_events"
on public.arts_events
for select
to authenticated
using (true);

drop policy if exists "arts_events_manage_committee_staff" on public.arts_events;
create policy "arts_events_manage_committee_staff"
on public.arts_events
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_social_css_works" on public.social_css_works;
create policy "public_college_data_select_social_css_works"
on public.social_css_works
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "social_css_works_manage_committee_staff" on public.social_css_works;
create policy "social_css_works_manage_committee_staff"
on public.social_css_works
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_social_exams" on public.social_exams;
create policy "public_college_data_select_social_exams"
on public.social_exams
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "social_exams_manage_committee_staff" on public.social_exams;
create policy "social_exams_manage_committee_staff"
on public.social_exams
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_cuc_notices" on public.cuc_notices;
create policy "public_college_data_select_cuc_notices"
on public.cuc_notices
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "cuc_notices_manage_committee_staff" on public.cuc_notices;
create policy "cuc_notices_manage_committee_staff"
on public.cuc_notices
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_union_schedule" on public.union_schedule;
create policy "public_college_data_select_union_schedule"
on public.union_schedule
for select
to authenticated
using (is_active is true or public.is_app_admin());

drop policy if exists "union_schedule_manage_committee_staff" on public.union_schedule;
create policy "union_schedule_manage_committee_staff"
on public.union_schedule
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "public_college_data_select_samajyam_performances" on public.samajyam_performances;
create policy "public_college_data_select_samajyam_performances"
on public.samajyam_performances
for select
to authenticated
using (true);

drop policy if exists "samajyam_performances_manage_committee_staff" on public.samajyam_performances;
create policy "samajyam_performances_manage_committee_staff"
on public.samajyam_performances
for all
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "prd_tasks_select_staff" on public.prd_tasks;
create policy "prd_tasks_select_staff"
on public.prd_tasks
for select
to authenticated
using (
  public.is_app_admin()
  or public.is_committee_admin()
  or public.is_finance_admin()
);

drop policy if exists "prd_tasks_insert_committee_staff" on public.prd_tasks;
create policy "prd_tasks_insert_committee_staff"
on public.prd_tasks
for insert
to authenticated
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "prd_tasks_update_committee_staff" on public.prd_tasks;
create policy "prd_tasks_update_committee_staff"
on public.prd_tasks
for update
to authenticated
using (public.is_app_admin() or public.is_committee_admin())
with check (public.is_app_admin() or public.is_committee_admin());

drop policy if exists "prd_tasks_delete_admin_only" on public.prd_tasks;
create policy "prd_tasks_delete_admin_only"
on public.prd_tasks
for delete
to authenticated
using (public.is_app_admin());
