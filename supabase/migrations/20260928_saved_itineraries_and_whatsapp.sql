-- Lets a signed-in tourist bookmark an itinerary they're browsing (the
-- heart icon on /explore and the itinerary detail page), and gives admin
-- a place to set a WhatsApp contact number that powers the site-wide
-- floating contact button. Both additive.

create table if not exists public.saved_itineraries (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references auth.users(id) on delete cascade,
  itinerary_id uuid not null references public.itineraries(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (tourist_id, itinerary_id)
);

alter table public.saved_itineraries enable row level security;

drop policy if exists "tourists manage own saved itineraries" on public.saved_itineraries;
create policy "tourists manage own saved itineraries" on public.saved_itineraries
  for all
  using (auth.uid() = tourist_id)
  with check (auth.uid() = tourist_id);

alter table public.platform_settings
  add column if not exists whatsapp_number text;
