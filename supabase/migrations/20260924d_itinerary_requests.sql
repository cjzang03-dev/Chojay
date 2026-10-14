-- "Suggest an Itinerary" — a tourist tells us what kind of trip they want
-- (destination, food, travel style, guide preference, etc.) and an admin
-- turns it into a curated itinerary in `itineraries` (source='admin'),
-- suggesting an operator to fulfill it via the existing `itinerary_operators`
-- table (no schema change needed there — same approved-link pattern already
-- used for operator-authored itineraries).
create table if not exists public.itinerary_requests (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references public.profiles(id) on delete cascade,
  destination_type text,
  travel_style text,
  food_preference text,
  guide_preference text,
  group_size int,
  budget_range text,
  preferred_dates text,
  notes text,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'fulfilled', 'declined')),
  itinerary_id uuid references public.itineraries(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists itinerary_requests_tourist_id_idx on public.itinerary_requests(tourist_id);
create index if not exists itinerary_requests_status_idx on public.itinerary_requests(status);

alter table public.itinerary_requests enable row level security;

create policy "Tourists can insert their own itinerary requests"
  on public.itinerary_requests for insert
  with check (auth.uid() = tourist_id);

create policy "Tourists can view their own itinerary requests"
  on public.itinerary_requests for select
  using (auth.uid() = tourist_id);

create policy "Admins can view all itinerary requests"
  on public.itinerary_requests for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

create policy "Admins can update itinerary requests"
  on public.itinerary_requests for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));
