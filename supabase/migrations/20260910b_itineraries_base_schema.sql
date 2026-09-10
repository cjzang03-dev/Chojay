-- Base itinerary-model schema: itineraries, their day-by-day plan and
-- media, and the per-itinerary operator/guide application table. This is
-- the schema sketch from the original product spec, written to a
-- migration file for the first time here — it previously only existed as
-- inline SQL in the task description, so this session can't confirm
-- whether it was ever actually run against the live Supabase project.
--
-- NOT APPLIED AUTOMATICALLY. Review and run this (and
-- 20260910_itinerary_bookings.sql, which references itineraries(id) and
-- so must run after this) before the itinerary browsing, booking, or
-- operator/guide "apply to itinerary" features will work against real
-- data. If these tables already exist in your project, diff this against
-- the real schema before running — the `create table if not exists`
-- guards make re-running safe, but the RLS policies below assume this is
-- the first time they're being added.

create table if not exists itineraries (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  duration_days int,
  indicative_price text,
  includes_flight boolean default false,
  cover_photo_url text,
  status text default 'draft', -- draft / published / archived
  created_by uuid references profiles(id),
  source text default 'admin', -- 'admin' now; reserve 'operator_proposed' for later
  created_at timestamptz default now()
);

create table if not exists itinerary_days (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid references itineraries(id) on delete cascade,
  day_number int not null,
  title text,
  description text
);

create table if not exists itinerary_media (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid references itineraries(id) on delete cascade,
  media_type text check (media_type in ('photo', 'video')),
  file_path text not null,
  display_order int default 0
);

-- Operators/guides apply per itinerary; admin approval makes them appear
-- as a fulfillment option for that itinerary (product decision — no
-- auto-assignment, tourist picks from the approved list).
create table if not exists itinerary_operators (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid references itineraries(id) on delete cascade,
  operator_id uuid references profiles(id) on delete cascade,
  status text default 'pending', -- pending / approved / rejected
  applied_at timestamptz default now(),
  approved_at timestamptz,
  unique (itinerary_id, operator_id)
);

create index if not exists itinerary_days_itinerary_id_idx on itinerary_days (itinerary_id);
create index if not exists itinerary_media_itinerary_id_idx on itinerary_media (itinerary_id);
create index if not exists itinerary_operators_itinerary_id_idx on itinerary_operators (itinerary_id);
create index if not exists itinerary_operators_operator_id_idx on itinerary_operators (operator_id);

alter table itineraries enable row level security;
alter table itinerary_days enable row level security;
alter table itinerary_media enable row level security;
alter table itinerary_operators enable row level security;

-- Public catalog: anyone (including signed-out visitors) can browse
-- published itineraries and their day-by-day plan/media. Draft/archived
-- itineraries are admin-only (no policy here grants access to them —
-- the admin panel is expected to use the service role, which bypasses RLS).
drop policy if exists "Anyone can view published itineraries" on itineraries;
create policy "Anyone can view published itineraries"
  on itineraries for select
  using (status = 'published');

drop policy if exists "Anyone can view days of published itineraries" on itinerary_days;
create policy "Anyone can view days of published itineraries"
  on itinerary_days for select
  using (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_days.itinerary_id
      and itineraries.status = 'published'
  ));

drop policy if exists "Anyone can view media of published itineraries" on itinerary_media;
create policy "Anyone can view media of published itineraries"
  on itinerary_media for select
  using (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_media.itinerary_id
      and itineraries.status = 'published'
  ));

-- itinerary_operators: tourists need to see approved rows (to build the
-- "pick your operator" list); operators need to see and create their own
-- applications, in any status, so their dashboard can show pending/
-- rejected as well as approved.
drop policy if exists "Anyone can view approved operator applications" on itinerary_operators;
create policy "Anyone can view approved operator applications"
  on itinerary_operators for select
  using (status = 'approved');

drop policy if exists "Operators can view their own applications" on itinerary_operators;
create policy "Operators can view their own applications"
  on itinerary_operators for select
  using (auth.uid() = operator_id);

drop policy if exists "Operators can apply to itineraries" on itinerary_operators;
create policy "Operators can apply to itineraries"
  on itinerary_operators for insert
  with check (auth.uid() = operator_id);

-- No update/delete policy for operators: withdrawing an application or
-- admin approval/rejection isn't built in the app yet (admin approval
-- screens are build order step 8, on the website).
