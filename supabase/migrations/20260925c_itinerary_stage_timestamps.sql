-- Timestamps for when a package entered "assigned" and "confirmed" status,
-- so the admin Pipeline board can flag anything that's been sitting too
-- long instead of only showing current state. Additive, not applied
-- automatically. Falls back to created_at (an approximation) until this
-- is run.
alter table public.itineraries
  add column if not exists assigned_at timestamptz,
  add column if not exists confirmed_at timestamptz;
