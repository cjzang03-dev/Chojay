-- ============================================================================
-- RUN THIS ONE FILE in Supabase's SQL Editor to fix the Bookings tab error
-- ("Could not find the table 'public.itinerary_bookings'").
--
-- It's the combined content of three migrations that depend on each other
-- in this order — 20260910_itinerary_bookings.sql,
-- 20260911_itinerary_booking_reviews.sql, and
-- 20261006_itinerary_bookings_operator_actions.sql — pasted here as one
-- script so there's a single copy-paste instead of three. Safe to run even
-- if some of this already exists: every CREATE is guarded with
-- IF NOT EXISTS, and every CREATE POLICY is preceded by a DROP POLICY IF
-- EXISTS for the same name.
-- ============================================================================

-- --- from 20260910_itinerary_bookings.sql -----------------------------------

create table if not exists itinerary_bookings (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references itineraries(id) on delete restrict,
  operator_id uuid not null references profiles(id) on delete restrict,
  tourist_id uuid not null references profiles(id) on delete restrict,
  travel_start_date date not null,
  traveler_count int not null default 1,
  indicative_price_snapshot text,
  notes text,
  status text not null default 'requested',
  created_at timestamptz not null default now()
);

create index if not exists itinerary_bookings_tourist_id_idx
  on itinerary_bookings (tourist_id);
create index if not exists itinerary_bookings_operator_id_idx
  on itinerary_bookings (operator_id);
create index if not exists itinerary_bookings_itinerary_id_idx
  on itinerary_bookings (itinerary_id);

alter table itinerary_bookings enable row level security;

drop policy if exists "Tourists can view their own itinerary bookings" on itinerary_bookings;
create policy "Tourists can view their own itinerary bookings"
  on itinerary_bookings for select
  using (auth.uid() = tourist_id);

drop policy if exists "Tourists can create their own itinerary bookings" on itinerary_bookings;
create policy "Tourists can create their own itinerary bookings"
  on itinerary_bookings for insert
  with check (auth.uid() = tourist_id);

drop policy if exists "Operators can view itinerary bookings directed at them" on itinerary_bookings;
create policy "Operators can view itinerary bookings directed at them"
  on itinerary_bookings for select
  using (auth.uid() = operator_id);

-- --- from 20260911_itinerary_booking_reviews.sql ----------------------------

create table if not exists itinerary_booking_reviews (
  id uuid primary key default gen_random_uuid(),
  itinerary_booking_id uuid not null unique references itinerary_bookings(id) on delete cascade,
  itinerary_id uuid not null references itineraries(id) on delete cascade,
  operator_id uuid not null references profiles(id) on delete cascade,
  tourist_id uuid not null references profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists itinerary_booking_reviews_itinerary_id_idx
  on itinerary_booking_reviews (itinerary_id);
create index if not exists itinerary_booking_reviews_operator_id_idx
  on itinerary_booking_reviews (operator_id);

alter table itinerary_booking_reviews enable row level security;

drop policy if exists "Anyone can view itinerary booking reviews" on itinerary_booking_reviews;
create policy "Anyone can view itinerary booking reviews"
  on itinerary_booking_reviews for select
  using (true);

drop policy if exists "Tourists can review their own bookings" on itinerary_booking_reviews;
create policy "Tourists can review their own bookings"
  on itinerary_booking_reviews for insert
  with check (
    auth.uid() = tourist_id
    and exists (
      select 1 from itinerary_bookings
      where itinerary_bookings.id = itinerary_booking_reviews.itinerary_booking_id
        and itinerary_bookings.tourist_id = auth.uid()
        and itinerary_bookings.operator_id = itinerary_booking_reviews.operator_id
        and itinerary_bookings.itinerary_id = itinerary_booking_reviews.itinerary_id
    )
  );

-- --- from 20261006_itinerary_bookings_operator_actions.sql ------------------

drop policy if exists "Operators can confirm or decline their itinerary bookings" on itinerary_bookings;
create policy "Operators can confirm or decline their itinerary bookings"
  on itinerary_bookings for update
  using (auth.uid() = operator_id)
  with check (auth.uid() = operator_id and status in ('confirmed', 'declined'));
