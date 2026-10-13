-- ============================================================================
-- RUN THIS ONE FILE in Supabase's SQL Editor to add structured trip-inclusion
-- flags beyond "includes_flight" — hotel/accommodation, meals, transport,
-- and a licensed guide — so the app and website can show what a specific
-- itinerary actually includes instead of the same generic text for every
-- trip regardless of what the operator offers.
--
-- Safe to run even if some of these already exist: each uses
-- `add column if not exists`.
-- ============================================================================

alter table itineraries add column if not exists includes_hotel boolean default false;
alter table itineraries add column if not exists includes_meals boolean default false;
alter table itineraries add column if not exists includes_transport boolean default false;
alter table itineraries add column if not exists includes_guide boolean default false;
