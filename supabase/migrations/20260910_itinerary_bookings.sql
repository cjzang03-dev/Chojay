-- Booking requests against the NEW itinerary model (curated itinerary +
-- tourist-chosen approved operator). This is deliberately a separate table
-- from the legacy `bookings` table used by the old per-operator-package
-- flow — additive only, per the project's safe-rollout rules:
--   - does not touch, rename, or reuse columns on the existing `bookings`
--     table (whose exact shape, e.g. a possibly-required package_id, was
--     not verified against the live schema this session)
--   - does not require a package_id, since itineraries aren't packages
--
-- NOT APPLIED AUTOMATICALLY. This session has no database credentials for
-- your Supabase project — review this and run it yourself (SQL editor or
-- `supabase db push` / your migration tool of choice) before the app's
-- booking flow will work against real data.
--
-- Pricing note: per product decision, the platform sets one indicative
-- price per itinerary, shown as-is regardless of operator. This table
-- snapshots that price at request time (so a later edit to the itinerary's
-- price doesn't retroactively change what a tourist was quoted) but does
-- NOT auto-calculate or charge a final price — group-size/shared-room
-- pricing is confirmed directly between operator and tourist in chat
-- (build order step 6), matching the known group-pricing issue call-out.

create table if not exists itinerary_bookings (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references itineraries(id) on delete restrict,
  operator_id uuid not null references profiles(id) on delete restrict,
  tourist_id uuid not null references profiles(id) on delete restrict,
  travel_start_date date not null,
  traveler_count int not null default 1,
  indicative_price_snapshot text,
  notes text,
  -- requested / confirmed / declined / cancelled. Only 'requested' is
  -- written by this app version; operator/admin confirmation UI is a
  -- later build-order step (operator dashboards, step 7).
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

-- Tourists can see and create their own booking requests, but not edit
-- them after the fact (no update/delete policy) — confirming or changing
-- a request's status is operator/admin territory, not built yet.
create policy "Tourists can view their own itinerary bookings"
  on itinerary_bookings for select
  using (auth.uid() = tourist_id);

create policy "Tourists can create their own itinerary bookings"
  on itinerary_bookings for insert
  with check (auth.uid() = tourist_id);

-- Operators can see requests directed at them (read-only for now; no
-- operator dashboard exists yet to act on these).
create policy "Operators can view itinerary bookings directed at them"
  on itinerary_bookings for select
  using (auth.uid() = operator_id);
