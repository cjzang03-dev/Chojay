-- Reviews for the itinerary-model booking flow (build order step 9:
-- reviews/notifications/polish). Deliberately a NEW, separate table rather
-- than reusing the website's existing `reviews` (guide-only) or
-- `agency_reviews` (agency-booking-only) tables — those are keyed to the
-- legacy `bookings` table via `booking_id`, and itinerary bookings live in
-- the separate `itinerary_bookings` table added in
-- 20260910_itinerary_bookings.sql. This mirrors that same table's
-- separation rationale: additive-only, no reuse of a differently-shaped
-- foreign key.
--
-- NOT APPLIED AUTOMATICALLY — review and run this (after
-- 20260910_itinerary_bookings.sql, which it references) before the
-- review features in the app/website will work against real data.
--
-- One review per booking (unique constraint below). No update/delete
-- policy — reviews are immutable once posted, matching the apparent
-- pattern of the website's other review tables. Eligibility (e.g. only
-- after the trip's travel_start_date has passed) is enforced by the
-- client, not RLS, again matching the existing `ReviewForm`/
-- `AgencyReviewForm` pattern on the website, which gates on payment
-- status client-side rather than in a policy.

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

-- Public read: reviews are shown on the public itinerary detail page next
-- to each approved operator, same as guide/agency reviews are shown on
-- their public profile pages.
drop policy if exists "Anyone can view itinerary booking reviews" on itinerary_booking_reviews;
create policy "Anyone can view itinerary booking reviews"
  on itinerary_booking_reviews for select
  using (true);

-- A tourist can review only their own booking, and only once (the unique
-- constraint on itinerary_booking_id backs that up against races).
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
