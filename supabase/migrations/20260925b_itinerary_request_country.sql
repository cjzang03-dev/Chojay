-- Lets a tourist tell us which country they're traveling from when they
-- suggest an itinerary, so the operator building their package knows
-- things like visa/SDF nuances and travel logistics up front.
alter table public.itinerary_requests add column if not exists country text;
